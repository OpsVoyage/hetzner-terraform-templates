# Minimal example — smallest viable stack
#
# Provisions:
#   - New private network
#   - Existing SSH key referenced by name
#   - Bastion with floating IP
#   - 1 web server (public IPv4 enabled — no load balancer)
#   - 1 backend server (private)
#   - Self-managed PostgreSQL database server + 50 GiB volume
#
# No load balancer, no HTTPS, no backups on web, single servers per tier.
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

  project_name = "demo"
  environment  = "dev"
  location     = "nbg1"

  # Network
  network_create = true

  # SSH key — names of SSH keys already uploaded to your Hetzner Cloud project
  ssh_key_existing_names = ["your-key-name"]

  # Bastion
  bastion_enabled             = true
  bastion_server_type         = "cx22"
  bastion_image               = "ubuntu-24.04"
  bastion_floating_ip_enabled = true
  # bastion_subnet              = "public"  # default; set to "private" or "db" to override

  # No load balancer — give the single web server a public IP
  load_balancer_enabled          = false
  web_server_count               = 1
  web_server_public_ipv4_enabled = true
  # web_server_subnet            = "public"  # default; set to "private" or "db" to override

  # Single backend
  backend_server_count = 1
  backend_server_type  = "cx22"
  # backend_server_subnet = "private"  # default; set to "public" or "db" to override

  # Self-managed PostgreSQL with a small volume
  database_engine                 = "postgres"
  database_root_user              = var.database_root_user
  database_root_password          = var.database_root_password
  database_server_type            = "cx32"
  database_volume_enabled         = true
  database_volume_size_gb         = 50
  database_server_backups_enabled = false
  # database_server_subnet          = "db"  # default; set to "public" or "private" to override
}

output "bastion_ip" {
  description = "Public IP of the bastion."
  value       = module.infra.bastion_public_ipv4
}

output "web_server_ips" {
  description = "Private IPs of the web servers."
  value       = module.infra.web_server_private_ips
}

output "database_private_ip" {
  description = "Private IP of the database server."
  value       = module.infra.database_server_private_ip
}

output "database_engine" {
  description = "Database engine installed."
  value       = module.infra.database_engine
}
