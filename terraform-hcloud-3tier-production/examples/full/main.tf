# Full example — all features enabled
#
# Provisions:
#   - New private network (10.0.0.0/16)
#   - SSH key upload
#   - Firewalls for every tier
#   - Spread placement groups
#   - Bastion with floating IP
#   - Load balancer (HTTP + HTTPS with redirect)
#   - 2 web servers (private only)
#   - 2 backend servers (private only)
#   - Hetzner Managed PostgreSQL database

terraform {
  required_version = ">= 1.12.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

provider "hcloud" {
  # Set via HCLOUD_TOKEN environment variable
}

module "infra" {
  source = "../../"

  # ----------------------------------------------------------------------------
  # Global
  # ----------------------------------------------------------------------------
  project_name = "acme"
  environment  = "prod"
  location     = "nbg1"
  labels = {
    team = "platform"
    cost = "prod"
  }

  # ----------------------------------------------------------------------------
  # Network — create a new private network
  # ----------------------------------------------------------------------------
  network_create         = true
  network_ip_range       = "10.0.0.0/16"
  network_subnet_servers = "10.0.1.0/24"
  network_subnet_db      = "10.0.2.0/24"

  # ----------------------------------------------------------------------------
  # SSH key
  # ----------------------------------------------------------------------------
  ssh_key_create     = true
  ssh_key_public_key = file("~/.ssh/id_ed25519.pub")

  # ----------------------------------------------------------------------------
  # Firewalls
  # ----------------------------------------------------------------------------
  firewall_create            = true
  firewall_ssh_allowed_cidrs = ["203.0.113.10/32"] # Restrict to your IP

  # ----------------------------------------------------------------------------
  # Placement groups
  # ----------------------------------------------------------------------------
  placement_group_enabled = true

  # ----------------------------------------------------------------------------
  # Bastion
  # ----------------------------------------------------------------------------
  bastion_enabled             = true
  bastion_server_type         = "cx22"
  bastion_image               = "ubuntu-24.04"
  bastion_floating_ip_enabled = true

  # ----------------------------------------------------------------------------
  # Load balancer
  # ----------------------------------------------------------------------------
  load_balancer_enabled                 = true
  load_balancer_type                    = "lb11"
  load_balancer_algorithm               = "round_robin"
  load_balancer_http_enabled            = true
  load_balancer_https_enabled           = true
  load_balancer_certificate_ids         = [12345] # Replace with your cert ID
  load_balancer_redirect_http           = true
  load_balancer_backend_port            = 80
  load_balancer_health_check_path       = "/healthz"
  load_balancer_sticky_sessions_enabled = false

  # ----------------------------------------------------------------------------
  # Web servers
  # ----------------------------------------------------------------------------
  web_server_enabled             = true
  web_server_count               = 2
  web_server_type                = "cx22"
  web_server_image               = "ubuntu-24.04"
  web_server_public_ipv4_enabled = false
  web_server_backups_enabled     = false

  # ----------------------------------------------------------------------------
  # Backend servers
  # ----------------------------------------------------------------------------
  backend_server_enabled             = true
  backend_server_count               = 2
  backend_server_type                = "cx32"
  backend_server_image               = "ubuntu-24.04"
  backend_server_public_ipv4_enabled = false
  backend_server_backups_enabled     = true

  # ----------------------------------------------------------------------------
  # Database — Hetzner Managed PostgreSQL
  # ----------------------------------------------------------------------------
  database_enabled                  = true
  database_mode                     = "managed"
  database_managed_type             = "db1-small"
  database_managed_engine           = "pg"
  database_managed_version          = "16"
  database_managed_maintenance_dow  = "sunday"
  database_managed_maintenance_time = "03:00:00"
}

# ----------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------

output "bastion_ip" {
  value = module.infra.bastion_public_ipv4
}

output "load_balancer_ip" {
  value = module.infra.load_balancer_public_ipv4
}

output "summary" {
  value     = module.infra.summary
  sensitive = false
}
