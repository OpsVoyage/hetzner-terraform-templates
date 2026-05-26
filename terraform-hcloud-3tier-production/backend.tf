# ==============================================================================
# BACKEND / APPLICATION SERVERS
# Private, no public IPs by default. Reachable from web tier and via bastion.
# ==============================================================================

resource "hcloud_server" "backend" {
  count = var.backend_server_enabled ? var.backend_server_count : 0

  name        = "${local.name_prefix}-backend-${count.index + 1}"
  server_type = var.backend_server_type
  image       = var.backend_server_image
  location    = var.location
  ssh_keys    = local.all_ssh_keys
  backups     = var.backend_server_backups_enabled
  user_data   = var.backend_server_user_data
  labels = merge(local.common_labels, {
    role  = "backend"
    index = tostring(count.index + 1)
  })

  public_net {
    ipv4_enabled = var.backend_server_public_ipv4_enabled
    ipv6_enabled = var.backend_server_public_ipv6_enabled
  }

  placement_group_id = var.placement_group_enabled && var.backend_server_enabled ? hcloud_placement_group.backend[0].id : null

  firewall_ids = var.firewall_create ? [hcloud_firewall.backend[0].id] : []

  depends_on = [module.network]
}

resource "hcloud_server_network" "backend" {
  count = var.backend_server_enabled ? var.backend_server_count : 0

  server_id  = hcloud_server.backend[count.index].id
  network_id = local.network_id
}
