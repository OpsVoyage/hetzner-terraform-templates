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
    network_id         = optional(number)
  }))
  default = {}
}
