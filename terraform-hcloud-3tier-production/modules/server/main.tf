# ==============================================================================
# SERVER MODULE
#
# Creates Hetzner Cloud servers and attaches them to a private network via a
# separate hcloud_server_network resource.
#
# Note: The inline `network {}` block inside hcloud_server triggers a bug in
# hcloud provider v1.63.0 (validateUniqueNetworkIDs panics on unknown values
# at plan time). Using a separate resource avoids this entirely.
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

# Attach each server to its private network after creation.
# Kept separate from hcloud_server to avoid the validateUniqueNetworkIDs
# CustomizeDiff panic that occurs when network_id is unknown at plan time.
#
# subnet_id is preferred — it uniquely identifies both the network and the
# subnet tier (public / private / db). network_id alone is the fallback and
# attaches the server to the last subnet ordered by ip_range.
resource "hcloud_server_network" "this" {
  # Filter using the static network_enabled flag so for_each keys are always
  # known at plan time (subnet_id / network_id are unknown until apply).
  for_each = { for k, v in var.servers : k => v if v.network_enabled }

  server_id = hcloud_server.this[each.key].id

  # Use subnet_id when available; fall back to network_id.
  subnet_id  = each.value.subnet_id
  network_id = each.value.subnet_id == null ? each.value.network_id : null

  ip        = each.value.ip
  alias_ips = each.value.alias_ips
}
