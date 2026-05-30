# ==============================================================================
# NETWORK
# ==============================================================================

resource "hcloud_network" "main" {
  count    = var.create_network ? 1 : 0
  name     = var.name
  ip_range = var.ip_range
  labels   = var.labels
}

# Look up an existing network by name when no ID is supplied.
data "hcloud_network" "existing" {
  count = !var.create_network && var.existing_network_id == null ? 1 : 0
  name  = var.existing_network_name
}

# ==============================================================================
# SUBNETS (only when creating a new network)
# ==============================================================================

resource "hcloud_network_subnet" "public" {
  count        = var.create_network ? 1 : 0
  network_id   = local.network_id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_public
}

resource "hcloud_network_subnet" "private" {
  count        = var.create_network ? 1 : 0
  network_id   = local.network_id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_private
}

resource "hcloud_network_subnet" "db" {
  count        = var.create_network ? 1 : 0
  network_id   = local.network_id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_db
}
