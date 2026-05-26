# ==============================================================================
# DATABASE SERVER
#
# hcloud does NOT have managed databases (DBaaS) — this stack always provisions
# a dedicated Hetzner Cloud server and installs MySQL or PostgreSQL via cloud-init.
#
# Credentials are injected at provision time through Terraform sensitive variables.
# Set them via environment variables so they are never committed to version control:
#
#   export TF_VAR_database_root_user=dbadmin
#   export TF_VAR_database_root_password=<your-secret>
#
# Or supply them through OpsVoyage layer secrets.
# ==============================================================================

module "database_server" {
  source = "./modules/server"

  servers = var.database_enabled ? {
    "${local.name_prefix}-db" = {
      server_type        = var.database_server_type
      location           = var.location
      image              = var.database_server_image
      ssh_keys           = local.all_ssh_keys
      backups            = var.database_server_backups_enabled
      user_data          = local.database_user_data
      labels             = merge(local.common_labels, { role = "database", engine = var.database_engine })
      firewall_ids       = var.firewall_create ? [hcloud_firewall.database[0].id] : []
      placement_group_id = var.placement_group_enabled ? try(tonumber(hcloud_placement_group.database[0].id), null) : null
      ipv4_enabled       = var.database_server_public_ipv4_enabled
      ipv6_enabled       = false
      network_id         = tonumber(local.network_id)
    }
  } : {}

  depends_on = [module.network]
}

# ==============================================================================
# DATABASE VOLUME
#
# A separate Hetzner Cloud Block Volume mounted as the database data directory.
# Decouples data lifecycle from the server lifecycle; enables snapshots and
# server type upgrades without losing data.
# ==============================================================================

resource "hcloud_volume" "database" {
  count = var.database_enabled && var.database_volume_enabled ? 1 : 0

  name     = "${local.name_prefix}-db-vol"
  size     = var.database_volume_size_gb
  location = var.location
  format   = var.database_volume_format
  labels   = merge(local.common_labels, { role = "database-storage" })
}

resource "hcloud_volume_attachment" "database" {
  count = var.database_enabled && var.database_volume_enabled ? 1 : 0

  volume_id = hcloud_volume.database[0].id
  server_id = module.database_server.first_id
  automount = true
}
