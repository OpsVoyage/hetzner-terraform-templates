# Hetzner Cloud — Production 3-Tier Infrastructure

A batteries-included Terraform template for deploying a production-grade,
3-tier application stack on Hetzner Cloud. Every component has a dedicated
**enable/disable toggle** so OpsVoyage (or any operator) can compose exactly
the infrastructure they need.

## Architecture

```
Internet
   │
   ▼
┌──────────────────────────────────┐
│  Hetzner Cloud Load Balancer     │  (optional)
│  HTTP :80  /  HTTPS :443         │
└──────────────┬───────────────────┘
               │ private network
   ┌───────────┼───────────┐
   ▼           ▼           ▼
[web-1]    [web-2]   ... [web-N]    ← Web / Frontend tier
   │           │
   └─────┬─────┘
         │ private network
   ┌─────┼──────┐
   ▼     ▼      ▼
[backend-1] [backend-2] ... [backend-N]  ← Backend / App tier
         │
         ▼
   [database]   ← Hetzner Managed DB  OR  self-managed server + volume

        +
   [bastion]    ← Jump host (floating IP) for SSH access
```

All servers (except the bastion and optionally the load balancer) are
**private-only by default**: no public IPv4/IPv6. SSH access goes through
the bastion; application traffic goes through the load balancer.

## Features

| Component         | Toggle variable                    | Default |
|-------------------|------------------------------------|---------|
| Private network   | `network_create`                   | `true`  |
| SSH key upload    | `ssh_key_create`                   | `true`  |
| Firewalls (all)   | `firewall_create`                  | `true`  |
| Spread placement  | `placement_group_enabled`          | `true`  |
| Bastion server    | `bastion_enabled`                  | `true`  |
| Bastion floating IP | `bastion_floating_ip_enabled`    | `true`  |
| Load balancer     | `load_balancer_enabled`            | `true`  |
| LB HTTP listener  | `load_balancer_http_enabled`       | `true`  |
| LB HTTPS listener | `load_balancer_https_enabled`      | `false` |
| LB sticky sessions| `load_balancer_sticky_sessions_enabled` | `false` |
| LB private-only   | `load_balancer_private_only`       | `false` |
| Web servers       | `web_server_enabled`               | `true`  |
| Web public IPv4   | `web_server_public_ipv4_enabled`   | `false` |
| Web backups       | `web_server_backups_enabled`       | `false` |
| Backend servers   | `backend_server_enabled`           | `true`  |
| Backend public IPv4 | `backend_server_public_ipv4_enabled` | `false` |
| Backend backups   | `backend_server_backups_enabled`   | `true`  |
| Database tier     | `database_enabled`                 | `true`  |
| DB mode           | `database_mode`                    | `"managed"` |
| DB volume (self-managed) | `database_volume_enabled`   | `true`  |
| DB server backups | `database_server_backups_enabled`  | `true`  |

## Quick Start

```hcl
module "infra" {
  source = "github.com/OpsVoyage/opsvoyage//templates/hetzner/terraform-hcloud-3tier-production"

  project_name       = "myapp"
  environment        = "prod"
  location           = "nbg1"

  ssh_key_create     = true
  ssh_key_public_key = file("~/.ssh/id_ed25519.pub")

  web_server_count     = 2
  backend_server_count = 2

  database_mode = "managed"
}
```

## Network Module

The private network is provisioned via the
[`terraform-hcloud-network`](https://github.com/danylomikula/terraform-hcloud-network)
module. Pass `network_create = false` plus either `network_existing_id` or
`network_existing_name` to attach to a pre-existing network instead.

## Database Modes

### `managed` (default)
Provisions a **Hetzner Cloud Managed Database** (`hcloud_database_cluster`).
Attached to the private network; no public exposure.

> **Note:** Requires hcloud Terraform provider >= 1.50.0. If this resource
> is unavailable in your provider version, use `database_mode = "self_managed"`.

### `self_managed`
Deploys a dedicated Hetzner Cloud server. By default:
- No public IPv4
- Automatic daily backups enabled
- A separate block volume (`database_volume_enabled = true`) for data storage

## Prerequisites

- Terraform >= 1.12.0
- hcloud Terraform provider >= 1.50.0
- Hetzner Cloud API token (set via `HCLOUD_TOKEN` environment variable)

## Usage

```bash
export HCLOUD_TOKEN="your-hetzner-api-token"

terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Examples

| Example | Description |
|---------|-------------|
| [full](./examples/full/) | All features enabled: LB + HTTPS + managed DB + bastion |
| [minimal](./examples/minimal/) | Smallest viable stack: 1 web server, self-managed DB, no LB |

## Variables Reference

### Global

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | string | — | Resource name prefix |
| `environment` | string | `"prod"` | prod / staging / dev |
| `location` | string | `"nbg1"` | Hetzner datacenter |
| `labels` | map(string) | `{}` | Extra labels on all resources |

### Network

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `network_create` | bool | `true` | Create new network |
| `network_name` | string | `null` | Network name (auto-generated if null) |
| `network_ip_range` | string | `10.0.0.0/16` | Network CIDR |
| `network_existing_id` | number | `null` | Reuse existing network by ID |
| `network_existing_name` | string | `null` | Reuse existing network by name |
| `network_subnet_servers` | string | `10.0.1.0/24` | Servers subnet CIDR |
| `network_subnet_db` | string | `10.0.2.0/24` | Database subnet CIDR |

### SSH Keys

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ssh_key_create` | bool | `true` | Upload new SSH key |
| `ssh_key_name` | string | `null` | Key name (auto-generated if null) |
| `ssh_key_public_key` | string | `null` | Public key content |
| `ssh_key_existing_names` | list(string) | `[]` | Pre-existing key names to attach |

### Bastion

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bastion_enabled` | bool | `true` | Deploy bastion server |
| `bastion_server_type` | string | `cx22` | Server type |
| `bastion_image` | string | `ubuntu-24.04` | OS image |
| `bastion_floating_ip_enabled` | bool | `true` | Assign floating IPv4 |
| `bastion_user_data` | string | `null` | Custom cloud-init (default: ufw + fail2ban) |
| `bastion_additional_firewall_ids` | list(number) | `[]` | Extra firewall IDs |

### Load Balancer

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `load_balancer_enabled` | bool | `true` | Deploy LB |
| `load_balancer_type` | string | `lb11` | LB plan |
| `load_balancer_algorithm` | string | `round_robin` | round_robin / least_connections |
| `load_balancer_http_enabled` | bool | `true` | HTTP listener |
| `load_balancer_https_enabled` | bool | `false` | HTTPS listener |
| `load_balancer_certificate_ids` | list(number) | `[]` | Cert IDs for HTTPS |
| `load_balancer_redirect_http` | bool | `false` | Redirect HTTP→HTTPS |
| `load_balancer_backend_port` | number | `80` | Target port on web servers |
| `load_balancer_health_check_path` | string | `/healthz` | Health check path |
| `load_balancer_sticky_sessions_enabled` | bool | `false` | Cookie sessions |
| `load_balancer_private_only` | bool | `false` | Disable public interface |

### Web Servers

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `web_server_enabled` | bool | `true` | Deploy web tier |
| `web_server_count` | number | `2` | Number of servers |
| `web_server_type` | string | `cx22` | Server type |
| `web_server_image` | string | `ubuntu-24.04` | OS image |
| `web_server_public_ipv4_enabled` | bool | `false` | Public IPv4 |
| `web_server_backups_enabled` | bool | `false` | Daily backups |
| `web_server_user_data` | string | `null` | Cloud-init script |

### Backend Servers

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `backend_server_enabled` | bool | `true` | Deploy backend tier |
| `backend_server_count` | number | `2` | Number of servers |
| `backend_server_type` | string | `cx32` | Server type |
| `backend_server_image` | string | `ubuntu-24.04` | OS image |
| `backend_server_public_ipv4_enabled` | bool | `false` | Public IPv4 |
| `backend_server_backups_enabled` | bool | `true` | Daily backups |
| `backend_server_user_data` | string | `null` | Cloud-init script |

### Database

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `database_enabled` | bool | `true` | Deploy database tier |
| `database_mode` | string | `managed` | managed / self_managed |
| `database_managed_type` | string | `db1-mini` | Managed DB plan |
| `database_managed_engine` | string | `pg` | pg / mysql |
| `database_managed_version` | string | `16` | Engine major version |
| `database_server_type` | string | `cx42` | Self-managed server type |
| `database_server_image` | string | `ubuntu-24.04` | Self-managed OS image |
| `database_server_backups_enabled` | bool | `true` | Daily backups |
| `database_volume_enabled` | bool | `true` | Attach block volume |
| `database_volume_size_gb` | number | `100` | Volume size (GiB) |
| `database_volume_format` | string | `ext4` | ext4 / xfs |

## Outputs

| Output | Description |
|--------|-------------|
| `network_id` | Private network ID |
| `bastion_public_ipv4` | Bastion public IP (floating or primary) |
| `bastion_private_ip` | Bastion private IP |
| `load_balancer_public_ipv4` | Load balancer public IP |
| `web_server_private_ips` | List of web server private IPs |
| `backend_server_private_ips` | List of backend server private IPs |
| `database_server_private_ip` | Database server private IP (self-managed) |
| `database_managed_host` | Managed DB hostname (sensitive) |
| `summary` | Full structured summary for OpsVoyage UI |

## Security Notes

- Restrict `firewall_ssh_allowed_cidrs` to your known IP(s) in production.
- Never assign public IPs to backend or database servers.
- Store the Hetzner API token in a secrets manager; do not commit it.
- The `ssh_key_public_key` output is marked `sensitive = true`.
