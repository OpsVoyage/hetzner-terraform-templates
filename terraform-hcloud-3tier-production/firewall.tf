# ==============================================================================
# BASTION FIREWALL
# Allows SSH from configurable source CIDRs and ICMP.
# ==============================================================================

resource "hcloud_firewall" "bastion" {
  count = var.firewall_create && var.bastion_enabled ? 1 : 0

  name   = "${local.name_prefix}-bastion-fw"
  labels = merge(local.common_labels, { role = "bastion" })

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.firewall_ssh_allowed_cidrs
    description = "SSH access from allowed source CIDRs"
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "ICMP (ping) from anywhere"
  }
}

# ==============================================================================
# WEB SERVER FIREWALL
# Allows HTTP traffic (from LB or internet) and SSH from the private network.
# ==============================================================================

resource "hcloud_firewall" "web" {
  count = var.firewall_create && var.web_server_enabled ? 1 : 0

  name   = "${local.name_prefix}-web-fw"
  labels = merge(local.common_labels, { role = "web" })

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = tostring(var.load_balancer_backend_port)
    source_ips  = var.firewall_http_allowed_cidrs
    description = "HTTP traffic from load balancer or internet"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = [var.network_ip_range]
    description = "SSH from private network (via bastion)"
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = [var.network_ip_range]
    description = "ICMP within private network"
  }
}

# ==============================================================================
# BACKEND SERVER FIREWALL
# Private network only: app traffic from web tier, SSH from private network.
# ==============================================================================

resource "hcloud_firewall" "backend" {
  count = var.firewall_create && var.backend_server_enabled ? 1 : 0

  name   = "${local.name_prefix}-backend-fw"
  labels = merge(local.common_labels, { role = "backend" })

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "8080"
    source_ips  = [var.network_subnet_public]
    description = "App traffic from web tier"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "8443"
    source_ips  = [var.network_subnet_public]
    description = "App TLS traffic from web tier"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = [var.network_ip_range]
    description = "SSH from private network (via bastion)"
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = [var.network_ip_range]
    description = "ICMP within private network"
  }
}

# ==============================================================================
# DATABASE FIREWALL (self-managed only)
# Accepts PostgreSQL and MySQL only from the servers subnet.
# ==============================================================================

resource "hcloud_firewall" "database" {
  count = var.firewall_create && var.database_enabled ? 1 : 0

  name   = "${local.name_prefix}-db-fw"
  labels = merge(local.common_labels, { role = "database" })

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "5432"
    source_ips  = [var.network_subnet_private, var.network_subnet_db]
    description = "PostgreSQL from backend tier"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "3306"
    source_ips  = [var.network_subnet_private, var.network_subnet_db]
    description = "MySQL from backend tier"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = [var.network_ip_range]
    description = "SSH from private network (via bastion)"
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = [var.network_ip_range]
    description = "ICMP within private network"
  }
}
