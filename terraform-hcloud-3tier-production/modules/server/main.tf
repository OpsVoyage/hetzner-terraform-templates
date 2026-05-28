# ==============================================================================
# SERVER MODULE
#
# Creates Hetzner Cloud servers and attaches them to a private network via a
# separate `hcloud_server_network` resource.
#
# The inline `network {}` block is intentionally NOT used because hcloud
# provider v1.63.0 introduced a CustomizeDiff validation that fires for any
# server that has both `network_id` (computed by Hetzner after creation) and
# `subnet_id` stored in state, causing plan failures on subsequent runs.
# The `hcloud_server_network` resource has supported `subnet_id` since
# provider v1.56.0 and does not have this validation issue.
# ==============================================================================

resource "hcloud_server" "this" {
  for_each = var.servers

  name               = each.key
  server_type        = each.value.server_type
  location           = each.value.location
  image              = each.value.image
  ssh_keys           = each.value.ssh_keys
  backups            = each.value.backups
  user_data          = each.value.user_data
  labels             = each.value.labels
  firewall_ids       = [for id in each.value.firewall_ids : tonumber(id)]
  placement_group_id = each.value.placement_group_id

  public_net {
    ipv4_enabled = each.value.ipv4_enabled
    ipv6_enabled = each.value.ipv6_enabled
  }

  lifecycle {
    ignore_changes = [ssh_keys, user_data]
  }
}

# Attach servers to their private subnet via a separate resource.
# This avoids the hcloud provider v1.63.0 CustomizeDiff bug where having both
# `network_id` (Hetzner-computed) and `subnet_id` in state causes plan errors.
resource "hcloud_server_network" "this" {
  for_each = { for k, v in var.servers : k => v if v.network_enabled }

  server_id = hcloud_server.this[each.key].id
  subnet_id = each.value.subnet_id
  ip        = each.value.ip != "" ? each.value.ip : null
  alias_ips = each.value.alias_ips
}
