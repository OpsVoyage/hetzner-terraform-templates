# ==============================================================================
# WEB / FRONTEND SERVERS
# These sit behind the load balancer and serve client-facing traffic.
# Public IPs are disabled by default — all ingress goes through the LB.
# ==============================================================================

resource "hcloud_server" "web" {
  count = var.web_server_enabled ? var.web_server_count : 0

  name        = "${local.name_prefix}-web-${count.index + 1}"
  server_type = var.web_server_type
  image       = var.web_server_image
  location    = var.location
  ssh_keys    = local.all_ssh_keys
  backups     = var.web_server_backups_enabled
  user_data   = var.web_server_user_data
  labels = merge(local.common_labels, {
    role  = "web"
    index = tostring(count.index + 1)
  })

  public_net {
    ipv4_enabled = var.web_server_public_ipv4_enabled
    ipv6_enabled = var.web_server_public_ipv6_enabled
  }

  placement_group_id = var.placement_group_enabled && var.web_server_enabled ? hcloud_placement_group.web[0].id : null

  firewall_ids = var.firewall_create ? [hcloud_firewall.web[0].id] : []

  depends_on = [module.network]
}

resource "hcloud_server_network" "web" {
  count = var.web_server_enabled ? var.web_server_count : 0

  server_id  = hcloud_server.web[count.index].id
  network_id = local.network_id
}
