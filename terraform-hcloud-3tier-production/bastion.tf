# ==============================================================================
# BASTION SERVER
# Public-facing jump host; all private server access is routed through it.
# ==============================================================================

module "bastion_server" {
  source = "./modules/server"

  servers = var.bastion_enabled ? {
    "${local.name_prefix}-bastion" = {
      server_type = var.bastion_server_type
      location    = var.location
      image       = var.bastion_image
      ssh_keys    = local.all_ssh_keys
      user_data   = local.bastion_user_data
      labels      = merge(local.common_labels, { role = "bastion" })
      firewall_ids = concat(
        var.firewall_create ? [tostring(hcloud_firewall.bastion[0].id)] : [],
        [for id in var.bastion_additional_firewall_ids : tostring(id)]
      )
      ipv4_enabled    = true
      ipv6_enabled    = true
      network_id      = tonumber(local.network_id)
      subnet_id       = local.subnet_ids[var.bastion_subnet]
      network_enabled = true
    }
  } : {}

  depends_on = [module.network]
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
  server_id      = module.bastion_server.first_id
}
