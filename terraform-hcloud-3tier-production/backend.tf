# ==============================================================================
# BACKEND / APPLICATION SERVERS
# Private, no public IPs by default. Reachable from web tier and via bastion.
# Attached to the private subnet at creation time (inline network block).
# ==============================================================================

module "backend_servers" {
  source = "./modules/server"

  servers = var.backend_server_enabled ? {
    for i in range(var.backend_server_count) :
    "${local.name_prefix}-backend-${i + 1}" => {
      server_type        = var.backend_server_type
      location           = var.location
      image              = var.backend_server_image
      ssh_keys           = local.all_ssh_keys
      backups            = var.backend_server_backups_enabled
      user_data          = var.backend_server_user_data
      labels             = merge(local.common_labels, { role = "backend", index = tostring(i + 1) })
      firewall_ids       = var.firewall_create ? [hcloud_firewall.backend[0].id] : []
      placement_group_id = var.placement_group_enabled && var.backend_server_enabled ? tonumber(hcloud_placement_group.backend[0].id) : null
      ipv4_enabled       = var.backend_server_public_ipv4_enabled
      ipv6_enabled       = var.backend_server_public_ipv6_enabled
      network_id         = tonumber(local.network_id)
      subnet_id          = local.subnet_ids[var.backend_server_subnet]
      network_enabled    = true
    }
  } : {}

  depends_on = [module.network]
}
