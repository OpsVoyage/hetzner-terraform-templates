# ==============================================================================
# WEB / FRONTEND SERVERS
# These sit behind the load balancer and serve client-facing traffic.
# Public IPs are disabled by default — all ingress goes through the LB.
# Attached to the public subnet at creation time (inline network block).
# ==============================================================================

module "web_servers" {
  source = "./modules/server"

  servers = var.web_server_enabled ? {
    for i in range(var.web_server_count) :
    "${local.name_prefix}-web-${i + 1}" => {
      server_type        = var.web_server_type
      location           = var.location
      image              = var.web_server_image
      ssh_keys           = local.all_ssh_keys
      backups            = var.web_server_backups_enabled
      user_data          = var.web_server_user_data
      labels             = merge(local.common_labels, { role = "web", index = tostring(i + 1) })
      firewall_ids       = var.firewall_create ? [hcloud_firewall.web[0].id] : []
      placement_group_id = var.placement_group_enabled && var.web_server_enabled ? tonumber(hcloud_placement_group.web[0].id) : null
      ipv4_enabled       = var.web_server_public_ipv4_enabled
      ipv6_enabled       = var.web_server_public_ipv6_enabled
      network_id         = tonumber(local.network_id)
      subnet_id          = local.subnet_ids[var.web_server_subnet]
      network_enabled    = true
    }
  } : {}

  depends_on = [module.network]
}
