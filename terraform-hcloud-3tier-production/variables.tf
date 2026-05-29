# ==============================================================================
# GLOBAL
# ==============================================================================

variable "project_name" {
  description = "Short slug for this project. Used as a prefix for every resource name (e.g. myapp)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name may only contain lowercase letters, digits, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Controls naming and default behaviours."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Hetzner Cloud datacenter location. All resources are created here."
  type        = string
  default     = "nbg1"

  validation {
    condition     = contains(["nbg1", "fsn1", "hel1", "ash", "hil", "sin"], var.location)
    error_message = "location must be one of: nbg1, fsn1, hel1, ash, hil, sin."
  }
}

variable "labels" {
  description = "Extra key-value labels merged with the default labels on every resource."
  type        = map(string)
  default     = {}
}

# ==============================================================================
# NETWORK
# ==============================================================================

variable "network_create" {
  description = "TOGGLE — Create a new private network. Set to false to attach to an existing network."
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Name for the private network. Defaults to <project>-<env>-network when omitted."
  type        = string
  default     = null
}

variable "network_ip_range" {
  description = "CIDR block for the private network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "network_existing_id" {
  description = "ID of an existing Hetzner Cloud network. Required when network_create = false."
  type        = number
  default     = null
}

variable "network_existing_name" {
  description = "Name of an existing Hetzner Cloud network. Used when network_create = false and network_existing_id is null."
  type        = string
  default     = null
}

variable "network_subnet_public" {
  description = "CIDR for the public subnet created when network_create = true."
  type        = string
  default     = "10.0.1.0/24"
}

variable "network_subnet_private" {
  description = "CIDR for the private subnet created when network_create = true."
  type        = string
  default     = "10.0.2.0/24"
}

variable "network_subnet_db" {
  description = "CIDR for the database subnet created when network_create = true."
  type        = string
  default     = "10.0.3.0/24"
}

# ==============================================================================
# SUBNET ID OVERRIDES (network_create = false only)
# When using an existing network, provide the Hetzner subnet resource IDs
# (format: "{network_id}-{cidr}", e.g. "12345678-10.0.1.0/24").
# These are ignored when network_create = true — subnets are auto-assigned.
# ==============================================================================

variable "bastion_subnet_id" {
  description = "Subnet ID to attach the bastion to. Required when network_create = false."
  type        = string
  default     = null
}

variable "web_server_subnet_id" {
  description = "Subnet ID to attach web servers to. Required when network_create = false."
  type        = string
  default     = null
}

variable "backend_server_subnet_id" {
  description = "Subnet ID to attach backend servers to. Required when network_create = false."
  type        = string
  default     = null
}

variable "database_server_subnet_id" {
  description = "Subnet ID to attach the database server to. Required when network_create = false."
  type        = string
  default     = null
}

variable "load_balancer_subnet_id" {
  description = "Subnet ID to attach the load balancer to when network_create = false. Format: \"{network_id}-{cidr}\", e.g. \"12345678-10.0.1.0/24\". Ignored when network_create = true (uses the private subnet automatically)."
  type        = string
  default     = null
}

# ==============================================================================
# SSH KEYS
# ==============================================================================

variable "ssh_key_existing_names" {
  description = "Names of pre-existing Hetzner Cloud SSH keys to add to every server."
  type        = list(string)
  default     = []
}

# ==============================================================================
# FIREWALLS
# ==============================================================================

variable "firewall_create" {
  description = "TOGGLE — Create and attach Hetzner Cloud Firewalls to all server tiers."
  type        = bool
  default     = true
}

variable "firewall_ssh_allowed_cidrs" {
  description = "Source CIDRs allowed to reach SSH (port 22) on the bastion. Restrict to known IPs in production."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "firewall_http_allowed_cidrs" {
  description = "Source CIDRs allowed to reach HTTP/HTTPS on the load balancer or web servers."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

# ==============================================================================
# PLACEMENT GROUPS
# ==============================================================================

variable "placement_group_enabled" {
  description = "TOGGLE — Create spread placement groups per tier to maximise availability."
  type        = bool
  default     = true
}

# ==============================================================================
# BASTION / JUMP HOST
# ==============================================================================

variable "bastion_enabled" {
  description = "TOGGLE — Deploy a bastion (jump) server for secure SSH access into the private network."
  type        = bool
  default     = true
}

variable "bastion_server_type" {
  description = "Hetzner Cloud server type for the bastion."
  type        = string
  default     = "cx22"
}

variable "bastion_image" {
  description = "OS image for the bastion server."
  type        = string
  default     = "ubuntu-24.04"
}

variable "bastion_floating_ip_enabled" {
  description = "TOGGLE — Assign a static floating IPv4 to the bastion for a stable public endpoint."
  type        = bool
  default     = true
}

variable "bastion_user_data" {
  description = "Custom cloud-init user_data for the bastion. When null, a default hardening script (ufw + fail2ban) is applied."
  type        = string
  default     = null
}

variable "bastion_additional_firewall_ids" {
  description = "IDs of additional Hetzner Cloud Firewalls to attach to the bastion server."
  type        = list(number)
  default     = []
}



# ==============================================================================
# LOAD BALANCER
# ==============================================================================

variable "load_balancer_enabled" {
  description = "TOGGLE — Deploy a Hetzner Cloud Load Balancer in front of the web tier."
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "Hetzner Cloud Load Balancer plan."
  type        = string
  default     = "lb11"

  validation {
    condition     = contains(["lb11", "lb21", "lb31"], var.load_balancer_type)
    error_message = "load_balancer_type must be one of: lb11, lb21, lb31."
  }
}

variable "load_balancer_algorithm" {
  description = "Load balancing algorithm: round_robin or least_connections."
  type        = string
  default     = "round_robin"

  validation {
    condition     = contains(["round_robin", "least_connections"], var.load_balancer_algorithm)
    error_message = "load_balancer_algorithm must be round_robin or least_connections."
  }
}

variable "load_balancer_http_enabled" {
  description = "TOGGLE — Configure an HTTP (port 80) listener on the load balancer."
  type        = bool
  default     = true
}

variable "load_balancer_https_enabled" {
  description = "TOGGLE — Configure an HTTPS (port 443) listener with TLS termination on the load balancer."
  type        = bool
  default     = false
}

variable "load_balancer_certificate_ids" {
  description = "Hetzner Cloud certificate IDs to use for HTTPS termination. Required when load_balancer_https_enabled = true."
  type        = list(number)
  default     = []
}

variable "load_balancer_redirect_http" {
  description = "TOGGLE — Redirect HTTP requests to HTTPS. Only effective when load_balancer_https_enabled = true."
  type        = bool
  default     = false
}

variable "load_balancer_backend_port" {
  description = "Port on the web servers the load balancer forwards traffic to."
  type        = number
  default     = 80
}

variable "load_balancer_health_check_path" {
  description = "HTTP path used by the load balancer health check."
  type        = string
  default     = "/healthz"
}

variable "load_balancer_health_check_interval" {
  description = "Interval in seconds between health checks."
  type        = number
  default     = 15
}

variable "load_balancer_health_check_timeout" {
  description = "Timeout in seconds per health check attempt."
  type        = number
  default     = 10
}

variable "load_balancer_health_check_retries" {
  description = "Number of consecutive failures before a target is marked unhealthy."
  type        = number
  default     = 3
}

variable "load_balancer_sticky_sessions_enabled" {
  description = "TOGGLE — Enable cookie-based sticky sessions on the load balancer."
  type        = bool
  default     = false
}

variable "load_balancer_private_only" {
  description = "TOGGLE — Disable the load balancer's public interface (internal-only LB)."
  type        = bool
  default     = false
}

# ==============================================================================
# WEB / FRONTEND SERVERS
# ==============================================================================

variable "web_server_enabled" {
  description = "TOGGLE — Deploy web / frontend application servers."
  type        = bool
  default     = true
}

variable "web_server_count" {
  description = "Number of web servers to provision."
  type        = number
  default     = 2

  validation {
    condition     = var.web_server_count >= 0
    error_message = "web_server_count must be a non-negative number (0 disables the tier)."
  }
}

variable "web_server_type" {
  description = "Hetzner Cloud server type for web servers."
  type        = string
  default     = "cx22"
}

variable "web_server_image" {
  description = "OS image for web servers."
  type        = string
  default     = "ubuntu-24.04"
}

variable "web_server_public_ipv4_enabled" {
  description = "TOGGLE — Assign a public IPv4 to web servers. Recommended false when a load balancer is used."
  type        = bool
  default     = false
}

variable "web_server_public_ipv6_enabled" {
  description = "TOGGLE — Assign a public IPv6 to web servers."
  type        = bool
  default     = false
}

variable "web_server_backups_enabled" {
  description = "TOGGLE — Enable Hetzner Cloud automatic daily backups for web servers."
  type        = bool
  default     = false
}

variable "web_server_user_data" {
  description = "Cloud-init user_data script applied to every web server."
  type        = string
  default     = null
}



# ==============================================================================
# BACKEND / APPLICATION SERVERS
# ==============================================================================

variable "backend_server_enabled" {
  description = "TOGGLE — Deploy backend / application servers."
  type        = bool
  default     = true
}

variable "backend_server_count" {
  description = "Number of backend servers to provision."
  type        = number
  default     = 2

  validation {
    condition     = var.backend_server_count >= 0
    error_message = "backend_server_count must be a non-negative number (0 disables the tier)."
  }
}

variable "backend_server_type" {
  description = "Hetzner Cloud server type for backend servers."
  type        = string
  default     = "cx32"
}

variable "backend_server_image" {
  description = "OS image for backend servers."
  type        = string
  default     = "ubuntu-24.04"
}

variable "backend_server_public_ipv4_enabled" {
  description = "TOGGLE — Assign a public IPv4 to backend servers. Recommended false — access via bastion."
  type        = bool
  default     = false
}

variable "backend_server_public_ipv6_enabled" {
  description = "TOGGLE — Assign a public IPv6 to backend servers."
  type        = bool
  default     = false
}

variable "backend_server_backups_enabled" {
  description = "TOGGLE — Enable Hetzner Cloud automatic daily backups for backend servers."
  type        = bool
  default     = true
}

variable "backend_server_user_data" {
  description = "Cloud-init user_data script applied to every backend server."
  type        = string
  default     = null
}



# ==============================================================================
# DATABASE
# ==============================================================================

variable "database_enabled" {
  description = "TOGGLE — Deploy a database server."
  type        = bool
  default     = true
}

variable "database_engine" {
  description = "Database engine to install via cloud-init: mysql or postgres."
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["mysql", "postgres"], var.database_engine)
    error_message = "database_engine must be \"mysql\" or \"postgres\"."
  }
}

variable "database_root_user" {
  description = "Superuser name created in the database at bootstrap. Supply via TF_VAR_database_root_user or an OpsVoyage layer secret."
  type        = string
  sensitive   = true
}

variable "database_root_password" {
  description = "Superuser password for the database. Supply via TF_VAR_database_root_password or an OpsVoyage layer secret. Never commit to version control."
  type        = string
  sensitive   = true
}

variable "database_server_type" {
  description = "Hetzner Cloud server type for the database server."
  type        = string
  default     = "cx42"
}

variable "database_server_image" {
  description = "OS image for the database server."
  type        = string
  default     = "ubuntu-24.04"
}

variable "database_server_public_ipv4_enabled" {
  description = "TOGGLE — Assign a public IPv4 to the database server. Strongly recommended false — access via bastion only."
  type        = bool
  default     = false
}

variable "database_server_backups_enabled" {
  description = "TOGGLE — Enable Hetzner Cloud automatic daily backups for the database server."
  type        = bool
  default     = true
}

variable "database_server_user_data" {
  description = "Custom cloud-init user_data for the database server. When set, overrides the built-in MySQL/PostgreSQL bootstrap script."
  type        = string
  default     = null
  sensitive   = true
}

variable "database_volume_enabled" {
  description = "TOGGLE — Attach a dedicated Hetzner Cloud Volume to the database server for persistent data storage."
  type        = bool
  default     = true
}

variable "database_volume_size_gb" {
  description = "Size of the database data volume in GiB."
  type        = number
  default     = 100

  validation {
    condition     = var.database_volume_size_gb == 0 || var.database_volume_size_gb >= 10
    error_message = "database_volume_size_gb must be at least 10 GiB (or 0 when database tier is disabled)."
  }
}

variable "database_volume_format" {
  description = "Filesystem format for the database volume: ext4 or xfs."
  type        = string
  default     = "ext4"

  validation {
    condition     = contains(["ext4", "xfs"], var.database_volume_format)
    error_message = "database_volume_format must be ext4 or xfs."
  }
}


