variable "servers" {
  description = "Map of server configurations keyed by server name."
  type = map(object({
    server_type = string
    location    = string
    image       = string
    ssh_keys    = optional(list(string), [])
    backups     = optional(bool, false)
    user_data   = optional(string)
    labels      = optional(map(string), {})
    # IDs are strings in HCL; the hcloud provider coerces them to numbers.
    firewall_ids       = optional(list(string), [])
    placement_group_id = optional(number)
    ipv4_enabled       = optional(bool, true)
    ipv6_enabled       = optional(bool, true)
    # Network attachment — subnet_id is preferred; network_id is the fallback.
    # Set subnet_id to place the server in a specific subnet (e.g. "public",
    # "private", "db"). network_id alone attaches to the last subnet by ip_range.
    network_id      = optional(number)
    subnet_id       = optional(string)
    network_enabled = optional(bool, false)
    # Optional static private IP and additional alias IPs within the subnet.
    ip        = optional(string)
    alias_ips = optional(set(string), [])
  }))
  default = {}
}
