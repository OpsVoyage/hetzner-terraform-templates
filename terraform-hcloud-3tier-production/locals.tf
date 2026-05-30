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
  # SSH keys: use existing keys only (ssh_key_existing_names variable).
  # ---------------------------------------------------------------------------
  all_ssh_keys = var.ssh_key_existing_names

  # ---------------------------------------------------------------------------
  # Resolved network ID from the network module
  # ---------------------------------------------------------------------------
  network_id = module.network.network_id

  # ---------------------------------------------------------------------------
  # Resolved subnet IDs per tier.
  #
  # network_create = true  → auto-assigned from the subnets this stack creates:
  #   bastion  → public
  #   web      → private (behind LB) or public (no LB)
  #   backend  → private
  #   database → db
  #
  # network_create = false → caller supplies *_subnet_id variables directly
  #   (Hetzner resource ID format: "{network_id}-{cidr}")
  # ---------------------------------------------------------------------------
  bastion_subnet_id = var.network_create ? module.network.subnets["public"].id : var.bastion_subnet_id

  web_server_subnet_id = var.network_create ? (
    var.load_balancer_enabled
    ? module.network.subnets["private"].id
    : module.network.subnets["public"].id
  ) : var.web_server_subnet_id

  backend_server_subnet_id = var.network_create ? module.network.subnets["private"].id : var.backend_server_subnet_id

  database_server_subnet_id = var.network_create ? module.network.subnets["db"].id : var.database_server_subnet_id

  load_balancer_subnet_id = var.network_create ? module.network.subnets["private"].id : var.load_balancer_subnet_id

  # ---------------------------------------------------------------------------
  # Default bastion cloud-init: server hardening only (ufw + fail2ban).
  # NAT gateway functionality is handled by the dedicated nat-gateway server
  # in the terraform-hcloud-network module when nat_gateway_enabled = true.
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

  # ---------------------------------------------------------------------------
  # Database cloud-init scripts
  #
  # Credentials are written to a temporary SQL file (permissions 0600) and
  # deleted after execution so they do not linger in shell history or /proc.
  #
  # NOTE: database_root_password must not contain single quotes.
  # For passwords with special characters, provide a custom database_server_user_data.
  # ---------------------------------------------------------------------------

  mysql_cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - mysql-server
    write_files:
      - path: /root/.db-init.sql
        permissions: "0600"
        content: |
          ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.database_root_password}';
          CREATE USER IF NOT EXISTS '${var.database_root_user}'@'%' IDENTIFIED WITH mysql_native_password BY '${var.database_root_password}';
          GRANT ALL PRIVILEGES ON *.* TO '${var.database_root_user}'@'%' WITH GRANT OPTION;
          FLUSH PRIVILEGES;
    runcmd:
      - mysql < /root/.db-init.sql
      - rm -f /root/.db-init.sql
      - sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
      - systemctl restart mysql
      - systemctl enable mysql
  CLOUDINIT

  postgres_cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - postgresql
      - postgresql-contrib
    write_files:
      - path: /root/.db-init.sql
        permissions: "0600"
        content: |
          ALTER USER postgres PASSWORD '${var.database_root_password}';
          DO $$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${var.database_root_user}') THEN
              CREATE ROLE "${var.database_root_user}" WITH LOGIN SUPERUSER PASSWORD '${var.database_root_password}';
            END IF;
          END
          $$;
    runcmd:
      - sudo -u postgres psql -f /root/.db-init.sql
      - rm -f /root/.db-init.sql
      - sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
      - echo "host all all 10.0.0.0/8 scram-sha-256" >> /etc/postgresql/*/main/pg_hba.conf
      - systemctl restart postgresql
      - systemctl enable postgresql
  CLOUDINIT

  database_user_data = var.database_server_user_data != null ? var.database_server_user_data : (
    var.database_engine == "mysql" ? local.mysql_cloud_init : local.postgres_cloud_init
  )
}
