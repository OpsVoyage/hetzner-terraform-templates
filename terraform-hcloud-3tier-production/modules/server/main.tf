# ==============================================================================
# SERVER MODULE
#
# Creates Hetzner Cloud servers with an optional inline private network
# attachment so each server starts with the network interface already present.
#
# Using an inline `network {}` block instead of a separate
# `hcloud_server_network` resource avoids the "no public or private network
# interfaces found" error that occurs when both public IPv4 and IPv6 are
# disabled and the network is attached after creation.
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
  firewall_ids       = each.value.firewall_ids
  placement_group_id = each.value.placement_group_id

  public_net {
    ipv4_enabled = each.value.ipv4_enabled
    ipv6_enabled = each.value.ipv6_enabled
  }

  # Attach to the private network atomically at server creation time.
  dynamic "network" {
    for_each = each.value.network_id != null ? [each.value.network_id] : []
    content {
      network_id = network.value
    }
  }

  lifecycle {
    ignore_changes = [ssh_keys, user_data]
  }
}
