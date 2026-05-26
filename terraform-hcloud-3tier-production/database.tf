# ==============================================================================
# DATABASE — HETZNER MANAGED (DBaaS)
#
# Uses hcloud_database_cluster, available in hcloud provider >= 1.50.0.
# If your provider version does not support this resource, switch to
# database_mode = "self_managed" instead.
# ==============================================================================

resource "hcloud_database_cluster" "this" {
  count = var.database_enabled && var.database_mode == "managed" ? 1 : 0

  name     = "${local.name_prefix}-db"
  type     = var.database_managed_type
  engine   = var.database_managed_engine
  version  = var.database_managed_version
  location = var.location
  labels   = merge(local.common_labels, { role = "database" })

  maintenance_window {
    day_of_week = var.database_managed_maintenance_dow
    time        = var.database_managed_maintenance_time
  }

  # Attach the managed database to the private network so backend servers
  # can reach it via private IP without exposing it to the internet.
  dynamic "network" {
    for_each = [local.network_id]
    content {
      network_id = network.value
    }
  }

  depends_on = [module.network]
}

# ==============================================================================
# DATABASE — SELF-MANAGED SERVER
#
# A dedicated Hetzner Cloud server running the database engine of your choice.
# Fully private: no public IPv4 by default.
# ==============================================================================

resource "hcloud_server" "database" {
  count = var.database_enabled && var.database_mode == "self_managed" ? 1 : 0

  name        = "${local.name_prefix}-db"
  server_type = var.database_server_type
  image       = var.database_server_image
  location    = var.location
  ssh_keys    = local.all_ssh_keys
  backups     = var.database_server_backups_enabled
  user_data   = var.database_server_user_data
  labels      = merge(local.common_labels, { role = "database" })

  public_net {
    ipv4_enabled = var.database_server_public_ipv4_enabled
    ipv6_enabled = false
  }

  placement_group_id = var.placement_group_enabled ? try(hcloud_placement_group.database[0].id, null) : null

  firewall_ids = var.firewall_create ? [hcloud_firewall.database[0].id] : []

  depends_on = [module.network]
}

resource "hcloud_server_network" "database" {
  count = var.database_enabled && var.database_mode == "self_managed" ? 1 : 0

  server_id  = hcloud_server.database[0].id
  network_id = local.network_id
}

# ==============================================================================
# DATABASE VOLUME (self-managed only)
#
# A separate Hetzner Cloud Block Volume mounted as the database data directory.
# Decouples data lifecycle from the server lifecycle and makes snapshots easier.
# ==============================================================================

resource "hcloud_volume" "database" {
  count = var.database_enabled && var.database_mode == "self_managed" && var.database_volume_enabled ? 1 : 0

  name     = "${local.name_prefix}-db-vol"
  size     = var.database_volume_size_gb
  location = var.location
  format   = var.database_volume_format
  labels   = merge(local.common_labels, { role = "database-storage" })
}

resource "hcloud_volume_attachment" "database" {
  count = var.database_enabled && var.database_mode == "self_managed" && var.database_volume_enabled ? 1 : 0

  volume_id = hcloud_volume.database[0].id
  server_id = hcloud_server.database[0].id
  automount = true
}
