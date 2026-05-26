# Minimal example — smallest viable stack
#
# Provisions:
#   - New private network
#   - SSH key upload
#   - Bastion with floating IP
#   - 1 web server (public IPv4 enabled — no load balancer)
#   - 1 backend server (private)
#   - Self-managed database server + 50 GiB volume
#
# No load balancer, no HTTPS, no backups on web, single servers per tier.

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

  project_name = "demo"
  environment  = "dev"
  location     = "nbg1"

  # Network
  network_create = true

  # SSH key
  ssh_key_create     = true
  ssh_key_public_key = file("~/.ssh/id_ed25519.pub")

  # No load balancer — give the single web server a public IP
  load_balancer_enabled          = false
  web_server_count               = 1
  web_server_public_ipv4_enabled = true

  # Single backend
  backend_server_count = 1
  backend_server_type  = "cx22"

  # Self-managed database with a small volume
  database_mode                   = "self_managed"
  database_server_type            = "cx32"
  database_volume_enabled         = true
  database_volume_size_gb         = 50
  database_server_backups_enabled = false
}

output "bastion_ip" {
  value = module.infra.bastion_public_ipv4
}

output "web_server_ips" {
  value = module.infra.web_server_private_ips
}

output "database_private_ip" {
  value = module.infra.database_server_private_ip
}
