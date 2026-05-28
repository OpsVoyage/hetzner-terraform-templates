# ==============================================================================
# SERVER MODULE
#
# Creates Hetzner Cloud servers and attaches them to a private network via an
# inline `network {}` block so that the attachment is part of the CREATE call.
#
# This is required by the hcloud API when both `ipv4_enabled` and
# `ipv6_enabled` are false — the server must have at least one interface at
# creation time.
#
# hcloud provider v1.63.0 introduced a CustomizeDiff that fires on subsequent
# plans when `subnet_id` (set by us) and the computed `network_id` both appear
# in state. We suppress that re-plan with `lifecycle.ignore_changes = [network]`.
# The initial apply still applies the block correctly; only updates are skipped.
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
    # ssh_keys / user_data: standard drift-ignore for bootstrapped servers.
    # network: suppress the hcloud provider v1.63.0 CustomizeDiff that fires
    # when both the computed `network_id` and our `subnet_id` are in state.
    # The block is still applied on initial creation; subsequent plans are a no-op.
    ignore_changes = [ssh_keys, user_data, network]
  }
}
