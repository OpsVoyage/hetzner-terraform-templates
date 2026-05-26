# ==============================================================================
# NETWORK MODULE
# Uses the existing terraform-hcloud-network module from GitHub.
# Source: github.com/danylomikula/terraform-hcloud-network
# ==============================================================================

module "network" {
  source = "github.com/danylomikula/terraform-hcloud-network"

  create_network        = var.network_create
  name                  = coalesce(var.network_name, "${local.name_prefix}-network")
  ip_range              = var.network_ip_range
  existing_network_id   = var.network_existing_id
  existing_network_name = var.network_existing_name
  labels                = local.common_labels

  # Subnets are only created alongside a new network.
  # When reusing an existing network, subnets are expected to already exist.
  subnets = var.network_create ? {
    servers = {
      type         = "cloud"
      network_zone = local.network_zone
      ip_range     = var.network_subnet_servers
    }
    db = {
      type         = "cloud"
      network_zone = local.network_zone
      ip_range     = var.network_subnet_db
    }
  } : {}
}

# ==============================================================================
# SSH KEYS
# ==============================================================================

resource "hcloud_ssh_key" "this" {
  count = var.ssh_key_create ? 1 : 0

  name       = coalesce(var.ssh_key_name, "${local.name_prefix}-key")
  public_key = var.ssh_key_public_key
  labels     = local.common_labels
}
