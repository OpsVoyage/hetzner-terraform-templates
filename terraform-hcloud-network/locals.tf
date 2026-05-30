locals {
  # ---------------------------------------------------------------------------
  # Resolved network ID
  # ---------------------------------------------------------------------------
  network_id = var.create_network ? hcloud_network.main[0].id : (
    var.existing_network_id != null
    ? var.existing_network_id
    : data.hcloud_network.existing[0].id
  )

  # ---------------------------------------------------------------------------
  # NAT gateway static private IP
  # Defaults to the second usable host in the public subnet (e.g. 10.0.1.2).
  # ---------------------------------------------------------------------------
  nat_gateway_ip   = var.nat_gateway_ip != null ? var.nat_gateway_ip : cidrhost(var.subnet_public, 2)
  nat_gateway_name = var.nat_gateway_name != null ? var.nat_gateway_name : "${var.name}-nat-gw"

  # ---------------------------------------------------------------------------
  # Default NAT gateway cloud-init
  #
  # Enables kernel IPv4 forwarding and installs iptables-persistent so that
  # the MASQUERADE rules survive reboots. Detects the public interface
  # dynamically (supports both x86/eth0 and ARM/enp1s0 server types).
  #
  # The MASQUERADE rules explicitly match the private and db subnet sources
  # so that only expected traffic is masqueraded.
  # ---------------------------------------------------------------------------
  default_nat_gateway_user_data = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true

    debconf_selections: |
      iptables-persistent iptables-persistent/autosave_v4 boolean true
      iptables-persistent iptables-persistent/autosave_v6 boolean true

    packages:
      - iptables-persistent

    write_files:
      - path: /etc/sysctl.d/99-nat-gateway.conf
        content: |
          net.ipv4.ip_forward = 1
          net.ipv6.conf.all.forwarding = 1

    runcmd:
      - sysctl -p /etc/sysctl.d/99-nat-gateway.conf
      - |
        PUBLIC_IF=$(ip route show default | awk '/default/ {print $5; exit}')
        iptables -t nat -A POSTROUTING -s '${var.subnet_private}' -o "$PUBLIC_IF" -j MASQUERADE
        iptables -t nat -A POSTROUTING -s '${var.subnet_db}' -o "$PUBLIC_IF" -j MASQUERADE
        netfilter-persistent save
  CLOUDINIT

  nat_gateway_user_data = var.nat_gateway_user_data != null ? var.nat_gateway_user_data : local.default_nat_gateway_user_data
}
