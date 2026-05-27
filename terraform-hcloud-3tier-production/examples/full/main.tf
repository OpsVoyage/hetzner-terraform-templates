# Full example — all features enabled
#
# Provisions:
#   - New private network (10.0.0.0/16)
#   - Existing SSH key referenced by name
#   - Firewalls for every tier
#   - Spread placement groups
#   - Bastion with floating IP
#   - Load balancer (HTTP + HTTPS with redirect)
#   - 2 web servers (private only)
#   - 2 backend servers (private only)
#   - Self-managed PostgreSQL database server + 100 GiB volume
#
# Usage:
#   export HCLOUD_TOKEN=<your-api-token>
#   export TF_VAR_database_root_user=dbadmin
#   export TF_VAR_database_root_password=<your-secret>
#   terraform init && terraform apply

terraform {
  required_version = ">= 1.12.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.63.0"
    }
  }
}

provider "hcloud" {
  # Token is read from the HCLOUD_TOKEN environment variable
}

# Database credentials — supply via TF_VAR_* environment variables.
# Never commit these values to version control.
variable "database_root_user" {
  description = "Superuser name to create in the database engine."
  type        = string
  sensitive   = true
}

variable "database_root_password" {
  description = "Superuser password for the database engine."
  type        = string
  sensitive   = true
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
  network_subnet_public  = "10.0.1.0/24"
  network_subnet_private = "10.0.2.0/24"
  network_subnet_db      = "10.0.3.0/24"

  # ----------------------------------------------------------------------------
  # SSH key — names of SSH keys already uploaded to your Hetzner Cloud project
  # ----------------------------------------------------------------------------
  ssh_key_existing_names = ["your-key-name"]

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
  # Database — self-managed PostgreSQL
  # Credentials are forwarded from the variables declared above.
  # ----------------------------------------------------------------------------
  database_enabled                = true
  database_engine                 = "postgres"
  database_root_user              = var.database_root_user
  database_root_password          = var.database_root_password
  database_server_type            = "cx32"
  database_server_backups_enabled = true
  database_volume_enabled         = true
  database_volume_size_gb         = 100
}

# ----------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------

output "network_id" {
  description = "Private network ID."
  value       = module.infra.network_id
}

output "bastion_ip" {
  description = "Public IP of the bastion (floating IP)."
  value       = module.infra.bastion_public_ipv4
}

output "load_balancer_ip" {
  description = "Public IP of the load balancer."
  value       = module.infra.load_balancer_public_ipv4
}

output "web_server_private_ips" {
  description = "Private IPs of the web servers."
  value       = module.infra.web_server_private_ips
}

output "backend_server_private_ips" {
  description = "Private IPs of the backend servers."
  value       = module.infra.backend_server_private_ips
}

output "database_server_id" {
  description = "Hetzner server ID of the database server."
  value       = module.infra.database_server_id
}

output "database_private_ip" {
  description = "Private IP of the database server."
  value       = module.infra.database_server_private_ip
}

output "database_engine" {
  description = "Database engine installed on the server."
  value       = module.infra.database_engine
}

output "summary" {
  description = "High-level summary of all deployed resources."
  value       = module.infra.summary
  sensitive   = false
}
