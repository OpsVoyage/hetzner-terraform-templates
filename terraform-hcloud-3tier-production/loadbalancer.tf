# ==============================================================================
# LOAD BALANCER
# ==============================================================================

resource "hcloud_load_balancer" "this" {
  count = var.load_balancer_enabled ? 1 : 0

  name               = "${local.name_prefix}-lb"
  load_balancer_type = var.load_balancer_type
  location           = var.location
  labels             = merge(local.common_labels, { role = "load-balancer" })

  algorithm {
    type = var.load_balancer_algorithm
  }
}

# Attach the load balancer to the private network so it can reach web servers
# via private IPs (preferred over public routing).
resource "hcloud_load_balancer_network" "this" {
  count = var.load_balancer_enabled ? 1 : 0

  load_balancer_id        = hcloud_load_balancer.this[0].id
  network_id              = local.network_id
  subnet_id               = local.load_balancer_subnet_id
  enable_public_interface = !var.load_balancer_private_only

  depends_on = [module.network]
}

# ==============================================================================
# LOAD BALANCER TARGETS — web servers
# ==============================================================================

resource "hcloud_load_balancer_target" "web" {
  for_each = var.load_balancer_enabled && var.web_server_enabled ? module.web_servers.servers : {}

  type             = "server"
  load_balancer_id = hcloud_load_balancer.this[0].id
  server_id        = each.value.id
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.this,
    module.web_servers,
  ]
}

# ==============================================================================
# HTTP SERVICE (port 80)
# ==============================================================================

resource "hcloud_load_balancer_service" "http" {
  count = var.load_balancer_enabled && var.load_balancer_http_enabled ? 1 : 0

  load_balancer_id = hcloud_load_balancer.this[0].id
  protocol         = "http"
  listen_port      = 80
  destination_port = var.load_balancer_backend_port
  proxyprotocol    = false

  http {
    sticky_sessions = var.load_balancer_sticky_sessions_enabled
    cookie_name     = var.load_balancer_sticky_sessions_enabled ? "LB_SESSION" : null
    cookie_lifetime = var.load_balancer_sticky_sessions_enabled ? 300 : null
  }

  health_check {
    protocol = "http"
    port     = var.load_balancer_backend_port
    interval = var.load_balancer_health_check_interval
    timeout  = var.load_balancer_health_check_timeout
    retries  = var.load_balancer_health_check_retries

    http {
      path         = var.load_balancer_health_check_path
      status_codes = ["2??"]
    }
  }
}

# ==============================================================================
# HTTPS SERVICE (port 443, TLS termination)
# Requires at least one certificate ID in load_balancer_certificate_ids.
# ==============================================================================

resource "hcloud_load_balancer_service" "https" {
  count = var.load_balancer_enabled && var.load_balancer_https_enabled ? 1 : 0

  load_balancer_id = hcloud_load_balancer.this[0].id
  protocol         = "https"
  listen_port      = 443
  destination_port = var.load_balancer_backend_port
  proxyprotocol    = false

  http {
    sticky_sessions = var.load_balancer_sticky_sessions_enabled
    cookie_name     = var.load_balancer_sticky_sessions_enabled ? "LB_SESSION" : null
    cookie_lifetime = var.load_balancer_sticky_sessions_enabled ? 300 : null
    certificates    = var.load_balancer_certificate_ids
    redirect_http   = var.load_balancer_redirect_http
  }

  health_check {
    protocol = "http"
    port     = var.load_balancer_backend_port
    interval = var.load_balancer_health_check_interval
    timeout  = var.load_balancer_health_check_timeout
    retries  = var.load_balancer_health_check_retries

    http {
      path         = var.load_balancer_health_check_path
      status_codes = ["2??"]
    }
  }
}
