output "servers" {
  description = "Map of server name to attributes (id, name, ipv4, ipv6, status, private_ips)."
  value = {
    for k, s in hcloud_server.this : k => {
      id          = s.id
      name        = s.name
      ipv4        = s.ipv4_address
      ipv6        = s.ipv6_address
      status      = s.status
      private_ips = [for n in s.network : n.ip]
    }
  }
}

output "ids" {
  description = "Server IDs sorted by name."
  value       = [for k in sort(keys(hcloud_server.this)) : hcloud_server.this[k].id]
}

output "names" {
  description = "Server names sorted."
  value       = sort(keys(hcloud_server.this))
}

output "private_ips" {
  description = "Flat list of private network IPs across all servers (sorted by name)."
  value       = flatten([for k in sort(keys(hcloud_server.this)) : [for n in hcloud_server.this[k].network : n.ip]])
}

# ---------------------------------------------------------------------------
# Convenience outputs for single-server modules (bastion, database).
# try() returns null gracefully when no servers are present.
# ---------------------------------------------------------------------------

output "first_id" {
  description = "ID of the first server — intended for single-server modules."
  value       = try(values(hcloud_server.this)[0].id, null)
}

output "first_name" {
  description = "Name of the first server — intended for single-server modules."
  value       = try(values(hcloud_server.this)[0].name, null)
}

output "first_ipv4" {
  description = "Public IPv4 of the first server — intended for single-server modules."
  value       = try(values(hcloud_server.this)[0].ipv4_address, null)
}

output "first_private_ip" {
  description = "First private network IP of the first server — intended for single-server modules."
  value       = try(values(hcloud_server.this)[0].network[0].ip, null)
}
