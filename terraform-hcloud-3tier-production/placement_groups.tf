# ==============================================================================
# PLACEMENT GROUPS
# Each tier gets a dedicated "spread" placement group so that Hetzner
# schedules servers on separate physical hosts, maximising availability.
# ==============================================================================

resource "hcloud_placement_group" "web" {
  count = var.placement_group_enabled && var.web_server_enabled ? 1 : 0

  name   = "${local.name_prefix}-web-pg"
  type   = "spread"
  labels = merge(local.common_labels, { role = "web" })
}

resource "hcloud_placement_group" "backend" {
  count = var.placement_group_enabled && var.backend_server_enabled ? 1 : 0

  name   = "${local.name_prefix}-backend-pg"
  type   = "spread"
  labels = merge(local.common_labels, { role = "backend" })
}

resource "hcloud_placement_group" "database" {
  count = var.placement_group_enabled && var.database_enabled ? 1 : 0

  name   = "${local.name_prefix}-db-pg"
  type   = "spread"
  labels = merge(local.common_labels, { role = "database" })
}
