# ==============================================================================
# NETWORK MODULE
# Uses the local terraform-hcloud-network module which creates the network,
# subnets, and optionally a dedicated NAT gateway server.
# ==============================================================================

module "network" {
  source = "../terraform-hcloud-network"

  create_network        = var.network_create
  name                  = coalesce(var.network_name, "${local.name_prefix}-network")
  ip_range              = var.network_ip_range
  existing_network_id   = var.network_existing_id
  existing_network_name = var.network_existing_name
  labels                = local.common_labels
  network_zone          = local.network_zone
  location              = var.location

  subnet_public  = var.network_subnet_public
  subnet_private = var.network_subnet_private
  subnet_db      = var.network_subnet_db

  # NAT gateway — dedicated server providing outbound internet for private servers.
  nat_gateway_enabled             = var.network_create && var.nat_gateway_enabled
  nat_gateway_server_type         = var.nat_gateway_server_type
  nat_gateway_image               = var.nat_gateway_image
  nat_gateway_ip                  = var.nat_gateway_ip
  nat_gateway_ssh_keys            = local.all_ssh_keys
  nat_gateway_ssh_allowed_cidrs   = var.firewall_ssh_allowed_cidrs
  nat_gateway_floating_ip_enabled = var.nat_gateway_floating_ip_enabled
  nat_gateway_labels              = local.common_labels
}


