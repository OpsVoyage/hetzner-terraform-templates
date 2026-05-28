# ==============================================================================
# SERVER MODULE
#
# Creates Hetzner Cloud servers with an inline `network {}` block so the
# subnet attachment is part of the CREATE call.
#
# This is required by the hcloud API when both `ipv4_enabled` and
# `ipv6_enabled` are false — the server must have at least one interface at
# creation time.
#
# hcloud provider v1.63.0 introduced a CustomizeDiff that incorrectly errored
# when both `subnet_id` (config) and the computed `network_id` coexisted in
# state. This was fixed in v1.64.0 (#1430). We require >= 1.64.0.
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

  dynamic "network" {
    for_each = each.value.network_enabled ? [each.value] : []
    content {
      subnet_id = network.value.subnet_id
      ip        = network.value.ip != "" ? network.value.ip : null
      alias_ips = network.value.alias_ips
    }
  }

  lifecycle {
    ignore_changes = [ssh_keys, user_data]
  }
}
