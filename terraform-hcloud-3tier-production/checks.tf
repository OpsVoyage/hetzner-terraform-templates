# ==============================================================================
# CAPACITY CHECKS
#
# These run at plan time and emit a WARNING if a chosen server type currently
# has no capacity in the target location — surfacing the issue before `apply`
# fails with the cryptic `resource_unavailable` error.
#
# ARM server types (cax*) experience capacity constraints more often than x86
# types. The check lets users know upfront so they can switch types without
# wasting a failed apply run.
# ==============================================================================

# Fetch all Hetzner datacenters so we can filter by location and inspect the
# available_server_type_ids list for each.
data "hcloud_datacenters" "all" {}

# Look up the numeric ID for each unique server type that is actually enabled.
# The check blocks compare these IDs against available_server_type_ids.
locals {
  active_server_types = toset(compact([
    var.bastion_enabled ? var.bastion_server_type : null,
    var.backend_server_enabled ? var.backend_server_type : null,
    var.web_server_enabled ? var.web_server_type : null,
    var.database_enabled ? var.database_server_type : null,
  ]))

  # Datacenters located in the chosen location (e.g. "nbg1")
  location_datacenters = [
    for dc in data.hcloud_datacenters.all.datacenters : dc
    if dc.location.name == var.location
  ]

  # Server types with no available capacity in the target location
  unavailable_server_types = [
    for type_name in local.active_server_types : type_name
    if !anytrue([
      for dc in local.location_datacenters :
      contains(dc.available_server_type_ids, data.hcloud_server_type.checked[type_name].id)
    ])
  ]
}

data "hcloud_server_type" "checked" {
  for_each = local.active_server_types
  name     = each.value
}

# Warns during plan if any enabled server type has no current capacity in the
# target location — before apply fails with the cryptic resource_unavailable.
check "server_type_capacity" {
  assert {
    condition     = length(local.unavailable_server_types) == 0
    error_message = "No capacity for server type(s) [${join(", ", local.unavailable_server_types)}] in location '${var.location}'. ARM types (cax*) are often constrained — switch to the x86 equivalent (e.g. cx22 instead of cax11, cpx21 instead of cax21)."
  }
}
