# ==============================================================================
# SERVER MODULE
#
# Creates Hetzner Cloud servers and attaches them to a private network via an
# inline `network {}` block so the interface exists from the moment the server
# boots (Hetzner requires at least one interface).
#
# The dynamic block's for_each uses the static `network_enabled` boolean
# (always known at plan time) so key stability is guaranteed even when
# `subnet_id` is "(known after apply)" on a fresh network. `network_id` is
# intentionally never set inside the block — passing an unknown network_id
# triggers the validateUniqueNetworkIDs CustomizeDiff panic in hcloud
# provider v1.63.0.
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

  # Attach to private subnet at creation time (required when public IPs are
  # disabled). The for_each key is the static network_enabled bool so it is
  # always known at plan time. subnet_id may be unknown on a new network;
  # that is fine inside content {} — it resolves at apply time.
  dynamic "network" {
    for_each = each.value.network_enabled ? [1] : []
    content {
      subnet_id = each.value.subnet_id
      ip        = each.value.ip
      alias_ips = each.value.alias_ips
    }
  }

  lifecycle {
    ignore_changes = [ssh_keys, user_data, network]
  }
}
