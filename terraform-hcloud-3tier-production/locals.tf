locals {
  # ---------------------------------------------------------------------------
  # Naming
  # ---------------------------------------------------------------------------
  name_prefix = "${var.project_name}-${var.environment}"

  # ---------------------------------------------------------------------------
  # Labels applied to every resource
  # ---------------------------------------------------------------------------
  common_labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )

  # ---------------------------------------------------------------------------
  # Hetzner network zone derived from the chosen datacenter location.
  # All subnets in a single network must share the same zone.
  # ---------------------------------------------------------------------------
  network_zone = lookup(
    {
      "nbg1" = "eu-central"
      "fsn1" = "eu-central"
      "hel1" = "eu-central"
      "ash"  = "us-east"
      "hil"  = "us-west"
      "sin"  = "ap-southeast"
    },
    var.location,
    "eu-central"
  )

  # ---------------------------------------------------------------------------
  # SSH keys: combine newly-created key with any pre-existing ones.
  # hcloud_server.ssh_keys accepts names or IDs.
  # ---------------------------------------------------------------------------
  all_ssh_keys = concat(
    var.ssh_key_create ? [hcloud_ssh_key.this[0].name] : [],
    var.ssh_key_existing_names
  )

  # ---------------------------------------------------------------------------
  # Resolved network ID from the network module
  # ---------------------------------------------------------------------------
  network_id = module.network.network_id

  # ---------------------------------------------------------------------------
  # Default bastion cloud-init: minimal hardening (ufw + fail2ban)
  # ---------------------------------------------------------------------------
  default_bastion_user_data = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - fail2ban
      - ufw
    runcmd:
      - ufw default deny incoming
      - ufw default allow outgoing
      - ufw allow 22/tcp
      - ufw --force enable
      - systemctl enable --now fail2ban
  CLOUDINIT

  bastion_user_data = var.bastion_user_data != null ? var.bastion_user_data : local.default_bastion_user_data
}
