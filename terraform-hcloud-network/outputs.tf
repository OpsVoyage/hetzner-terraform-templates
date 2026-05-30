# ==============================================================================
# NETWORK OUTPUTS
# ==============================================================================

output "network_id" {
  description = "ID of the Hetzner Cloud network."
  value       = local.network_id
}

output "network_name" {
  description = "Name of the Hetzner Cloud network."
  value = var.create_network ? hcloud_network.main[0].name : (
    var.existing_network_id != null
    ? var.name
    : data.hcloud_network.existing[0].name
  )
}

output "network_ip_range" {
  description = "IP range (CIDR) of the Hetzner Cloud network."
  value = var.create_network ? hcloud_network.main[0].ip_range : (
    var.existing_network_id != null
    ? null
    : data.hcloud_network.existing[0].ip_range
  )
}

output "subnets" {
  description = "Map of subnet objects keyed by tier name (public, private, db). Each has an `id` attribute. Values are null when create_network = false."
  value = {
    public  = { id = one(hcloud_network_subnet.public[*].id) }
    private = { id = one(hcloud_network_subnet.private[*].id) }
    db      = { id = one(hcloud_network_subnet.db[*].id) }
  }
}

# ==============================================================================
# NAT GATEWAY OUTPUTS
# ==============================================================================

output "nat_gateway_private_ip" {
  description = "Static private IP of the NAT gateway within the public subnet. Null when nat_gateway_enabled = false."
  value       = var.nat_gateway_enabled ? local.nat_gateway_ip : null
}

output "nat_gateway_public_ip" {
  description = "Public IPv4 address of the NAT gateway server. Null when nat_gateway_enabled = false."
  value       = var.nat_gateway_enabled ? hcloud_server.nat_gateway[0].ipv4_address : null
}

output "nat_gateway_floating_ip" {
  description = "Floating IPv4 assigned to the NAT gateway. Null when floating IP is disabled."
  value       = var.nat_gateway_enabled && var.nat_gateway_floating_ip_enabled ? hcloud_floating_ip.nat_gateway[0].ip_address : null
}

output "nat_gateway_server_id" {
  description = "Server ID of the NAT gateway. Null when nat_gateway_enabled = false."
  value       = var.nat_gateway_enabled ? hcloud_server.nat_gateway[0].id : null
}
