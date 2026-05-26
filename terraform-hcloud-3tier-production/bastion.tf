# ==============================================================================
# BASTION SERVER
# Public-facing jump host; all private server access is routed through it.
# ==============================================================================

resource "hcloud_server" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  name        = "${local.name_prefix}-bastion"
  server_type = var.bastion_server_type
  image       = var.bastion_image
  location    = var.location
  ssh_keys    = local.all_ssh_keys
  user_data   = local.bastion_user_data
  labels      = merge(local.common_labels, { role = "bastion" })

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  firewall_ids = concat(
    var.firewall_create ? [hcloud_firewall.bastion[0].id] : [],
    var.bastion_additional_firewall_ids
  )

  depends_on = [module.network]
}

resource "hcloud_server_network" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  server_id  = hcloud_server.bastion[0].id
  network_id = local.network_id
}

# ==============================================================================
# FLOATING IP (optional stable public endpoint for the bastion)
# ==============================================================================

resource "hcloud_floating_ip" "bastion" {
  count = var.bastion_enabled && var.bastion_floating_ip_enabled ? 1 : 0

  type          = "ipv4"
  home_location = var.location
  name          = "${local.name_prefix}-bastion-fip"
  labels        = merge(local.common_labels, { role = "bastion" })
}

resource "hcloud_floating_ip_assignment" "bastion" {
  count = var.bastion_enabled && var.bastion_floating_ip_enabled ? 1 : 0

  floating_ip_id = hcloud_floating_ip.bastion[0].id
  server_id      = hcloud_server.bastion[0].id
}
