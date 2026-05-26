# ==============================================================================
# NETWORK
# ==============================================================================

output "network_id" {
  description = "ID of the private network managed (or referenced) by this stack."
  value       = module.network.network_id
}

output "network_name" {
  description = "Name of the private network."
  value       = module.network.network_name
}

output "network_ip_range" {
  description = "CIDR of the private network."
  value       = module.network.network_ip_range
}

output "network_subnets" {
  description = "Subnets created within the private network (when network_create = true)."
  value       = module.network.subnets
}

# ==============================================================================
# SSH KEY
# ==============================================================================

output "ssh_key_id" {
  description = "ID of the Hetzner Cloud SSH key created by this stack (null if ssh_key_create = false)."
  value       = var.ssh_key_create ? hcloud_ssh_key.this[0].id : null
}

output "ssh_key_name" {
  description = "Name of the Hetzner Cloud SSH key (null if ssh_key_create = false)."
  value       = var.ssh_key_create ? hcloud_ssh_key.this[0].name : null
}

# ==============================================================================
# BASTION
# ==============================================================================

output "bastion_server_id" {
  description = "Hetzner Cloud server ID of the bastion (null if disabled)."
  value       = var.bastion_enabled ? hcloud_server.bastion[0].id : null
}

output "bastion_public_ipv4" {
  description = "Public IPv4 of the bastion server (floating IP when enabled, otherwise primary IP)."
  value = var.bastion_enabled ? (
    var.bastion_floating_ip_enabled
    ? hcloud_floating_ip.bastion[0].ip_address
    : hcloud_server.bastion[0].ipv4_address
  ) : null
}

output "bastion_private_ip" {
  description = "Private IPv4 of the bastion within the private network."
  value       = var.bastion_enabled ? hcloud_server_network.bastion[0].ip : null
}

output "bastion_floating_ip" {
  description = "Floating IPv4 assigned to the bastion (null if floating IP is disabled)."
  value       = var.bastion_enabled && var.bastion_floating_ip_enabled ? hcloud_floating_ip.bastion[0].ip_address : null
}

# ==============================================================================
# LOAD BALANCER
# ==============================================================================

output "load_balancer_id" {
  description = "ID of the Hetzner Cloud Load Balancer (null if disabled)."
  value       = var.load_balancer_enabled ? hcloud_load_balancer.this[0].id : null
}

output "load_balancer_public_ipv4" {
  description = "Public IPv4 of the load balancer (null if disabled or private-only)."
  value       = var.load_balancer_enabled && !var.load_balancer_private_only ? hcloud_load_balancer.this[0].ipv4 : null
}

output "load_balancer_public_ipv6" {
  description = "Public IPv6 of the load balancer (null if disabled or private-only)."
  value       = var.load_balancer_enabled && !var.load_balancer_private_only ? hcloud_load_balancer.this[0].ipv6 : null
}

# ==============================================================================
# WEB SERVERS
# ==============================================================================

output "web_server_ids" {
  description = "List of Hetzner Cloud server IDs for the web tier."
  value       = var.web_server_enabled ? [for s in hcloud_server.web : s.id] : []
}

output "web_server_names" {
  description = "List of server names for the web tier."
  value       = var.web_server_enabled ? [for s in hcloud_server.web : s.name] : []
}

output "web_server_private_ips" {
  description = "Private IPv4 addresses of web servers within the private network."
  value       = var.web_server_enabled ? [for n in hcloud_server_network.web : n.ip] : []
}

# ==============================================================================
# BACKEND SERVERS
# ==============================================================================

output "backend_server_ids" {
  description = "List of Hetzner Cloud server IDs for the backend tier."
  value       = var.backend_server_enabled ? [for s in hcloud_server.backend : s.id] : []
}

output "backend_server_names" {
  description = "List of server names for the backend tier."
  value       = var.backend_server_enabled ? [for s in hcloud_server.backend : s.name] : []
}

output "backend_server_private_ips" {
  description = "Private IPv4 addresses of backend servers within the private network."
  value       = var.backend_server_enabled ? [for n in hcloud_server_network.backend : n.ip] : []
}

# ==============================================================================
# DATABASE
# ==============================================================================

output "database_server_id" {
  description = "Hetzner Cloud server ID of the self-managed database server (null if not self_managed)."
  value       = var.database_enabled && var.database_mode == "self_managed" ? hcloud_server.database[0].id : null
}

output "database_server_private_ip" {
  description = "Private IPv4 of the self-managed database server within the private network."
  value       = var.database_enabled && var.database_mode == "self_managed" ? hcloud_server_network.database[0].ip : null
}

output "database_volume_id" {
  description = "ID of the database block volume (null if not created)."
  value       = var.database_enabled && var.database_mode == "self_managed" && var.database_volume_enabled ? hcloud_volume.database[0].id : null
}

output "database_managed_id" {
  description = "ID of the Hetzner Managed Database cluster (null if not using managed mode)."
  value       = var.database_enabled && var.database_mode == "managed" ? hcloud_database_cluster.this[0].id : null
}

output "database_managed_host" {
  description = "Private hostname of the Hetzner Managed Database (null if not using managed mode)."
  value       = var.database_enabled && var.database_mode == "managed" ? hcloud_database_cluster.this[0].host : null
  sensitive   = true
}

output "database_managed_port" {
  description = "Port of the Hetzner Managed Database (null if not using managed mode)."
  value       = var.database_enabled && var.database_mode == "managed" ? hcloud_database_cluster.this[0].port : null
}

# ==============================================================================
# PLACEMENT GROUPS
# ==============================================================================

output "placement_group_ids" {
  description = "Map of tier name to placement group ID."
  value = {
    web     = var.placement_group_enabled && var.web_server_enabled ? hcloud_placement_group.web[0].id : null
    backend = var.placement_group_enabled && var.backend_server_enabled ? hcloud_placement_group.backend[0].id : null
    database = (
      var.placement_group_enabled &&
      var.database_enabled &&
      var.database_mode == "self_managed"
      ? hcloud_placement_group.database[0].id
      : null
    )
  }
}

# ==============================================================================
# FIREWALLS
# ==============================================================================

output "firewall_ids" {
  description = "Map of tier name to firewall ID (null if firewall_create = false or tier disabled)."
  value = {
    bastion  = var.firewall_create && var.bastion_enabled ? hcloud_firewall.bastion[0].id : null
    web      = var.firewall_create && var.web_server_enabled ? hcloud_firewall.web[0].id : null
    backend  = var.firewall_create && var.backend_server_enabled ? hcloud_firewall.backend[0].id : null
    database = var.firewall_create && var.database_enabled && var.database_mode == "self_managed" ? hcloud_firewall.database[0].id : null
  }
}

# ==============================================================================
# SUMMARY (convenience output for OpsVoyage UI)
# ==============================================================================

output "summary" {
  description = "High-level summary of all deployed resources for display in OpsVoyage."
  value = {
    project     = var.project_name
    environment = var.environment
    location    = var.location

    network = {
      id       = module.network.network_id
      name     = module.network.network_name
      ip_range = module.network.network_ip_range
    }

    bastion = var.bastion_enabled ? {
      id         = hcloud_server.bastion[0].id
      name       = hcloud_server.bastion[0].name
      public_ip  = var.bastion_floating_ip_enabled ? hcloud_floating_ip.bastion[0].ip_address : hcloud_server.bastion[0].ipv4_address
      private_ip = hcloud_server_network.bastion[0].ip
    } : null

    load_balancer = var.load_balancer_enabled ? {
      id        = hcloud_load_balancer.this[0].id
      name      = hcloud_load_balancer.this[0].name
      public_ip = !var.load_balancer_private_only ? hcloud_load_balancer.this[0].ipv4 : null
    } : null

    web_servers = {
      count       = var.web_server_enabled ? var.web_server_count : 0
      server_type = var.web_server_type
      private_ips = var.web_server_enabled ? [for n in hcloud_server_network.web : n.ip] : []
    }

    backend_servers = {
      count       = var.backend_server_enabled ? var.backend_server_count : 0
      server_type = var.backend_server_type
      private_ips = var.backend_server_enabled ? [for n in hcloud_server_network.backend : n.ip] : []
    }

    database = var.database_enabled ? {
      mode       = var.database_mode
      private_ip = var.database_mode == "self_managed" ? hcloud_server_network.database[0].ip : null
    } : null
  }
}
