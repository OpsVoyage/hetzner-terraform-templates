# ==============================================================================
# NAT GATEWAY (optional)
#
# A small dedicated server in the public subnet that masquerades outbound
# internet traffic from private-only servers (no public IP) so they can
# reach package repositories, APIs, etc. without an exposed public IP.
#
# Architecture:
#   private server → Hetzner SDN → hcloud_network_route → NAT gateway → internet
#
# How it works:
#   1. A private server sends a packet to the internet (e.g. apt update).
#   2. Its OS default route sends the packet to the Hetzner subnet gateway.
#   3. hcloud_network_route tells Hetzner's fabric: forward 0.0.0.0/0 to
#      the NAT gateway's static private IP.
#   4. The NAT gateway's kernel forwards the packet; iptables MASQUERADE
#      rewrites the source IP to the gateway's public IP.
#   5. The response returns to the gateway, which conntrack-NATs it back to
#      the originating private server.
#
# Cloud-init configures:
#   - net.ipv4.ip_forward = 1  (kernel packet forwarding)
#   - iptables MASQUERADE for subnet_private and subnet_db
#   - iptables-persistent to reload rules across reboots
# ==============================================================================

resource "hcloud_firewall" "nat_gateway" {
  count  = var.nat_gateway_enabled ? 1 : 0
  name   = "${local.nat_gateway_name}-fw"
  labels = merge(var.labels, var.nat_gateway_labels, { role = "nat-gateway" })

  # SSH from allowed external CIDRs and from the private network (via bastion)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = concat(var.nat_gateway_ssh_allowed_cidrs, [var.subnet_private, var.subnet_db])
  }

  # ICMP (ping) from anywhere for diagnostics
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Allow all traffic from the private network so forwarded packets are accepted
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.subnet_private, var.subnet_db]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.subnet_private, var.subnet_db]
  }
}

resource "hcloud_server" "nat_gateway" {
  count       = var.nat_gateway_enabled ? 1 : 0
  name        = local.nat_gateway_name
  server_type = var.nat_gateway_server_type
  image       = var.nat_gateway_image
  location    = var.location
  ssh_keys    = var.nat_gateway_ssh_keys
  user_data   = local.nat_gateway_user_data
  labels      = merge(var.labels, var.nat_gateway_labels, { role = "nat-gateway" })

  firewall_ids = [hcloud_firewall.nat_gateway[0].id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = local.network_id
    ip         = local.nat_gateway_ip
  }

  depends_on = [
    hcloud_network_subnet.public,
    hcloud_network_subnet.private,
    hcloud_network_subnet.db,
  ]
}

# Default 0.0.0.0/0 route in the Hetzner virtual network pointing to the NAT
# gateway. Hetzner's SDN uses this to forward all internet-bound traffic from
# private servers to the NAT gateway before it leaves the datacenter.
resource "hcloud_network_route" "nat" {
  count       = var.nat_gateway_enabled ? 1 : 0
  network_id  = tonumber(local.network_id)
  destination = "0.0.0.0/0"
  gateway     = local.nat_gateway_ip

  depends_on = [hcloud_server.nat_gateway]
}

# Optional floating IP for a stable public endpoint on the NAT gateway.
# Useful when egress traffic needs to come from a fixed IP for allowlisting.
# Note: after creation, OS-level configuration (netplan) is required to bind
# the floating IP to the network interface.
resource "hcloud_floating_ip" "nat_gateway" {
  count         = var.nat_gateway_enabled && var.nat_gateway_floating_ip_enabled ? 1 : 0
  type          = "ipv4"
  home_location = var.location
  name          = "${local.nat_gateway_name}-fip"
  labels        = merge(var.labels, var.nat_gateway_labels, { role = "nat-gateway" })
}

resource "hcloud_floating_ip_assignment" "nat_gateway" {
  count          = var.nat_gateway_enabled && var.nat_gateway_floating_ip_enabled ? 1 : 0
  floating_ip_id = hcloud_floating_ip.nat_gateway[0].id
  server_id      = hcloud_server.nat_gateway[0].id
}
