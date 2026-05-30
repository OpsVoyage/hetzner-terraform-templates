# ==============================================================================
# NETWORK
# ==============================================================================

variable "create_network" {
  description = "Create a new Hetzner Cloud network. Set to false to attach to an existing network."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the private network."
  type        = string
}

variable "ip_range" {
  description = "CIDR block for the private network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "existing_network_id" {
  description = "ID of an existing Hetzner Cloud network. Used when create_network = false."
  type        = number
  default     = null
}

variable "existing_network_name" {
  description = "Name of an existing network to look up by name. Used when create_network = false and existing_network_id is null."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to the network and all managed resources."
  type        = map(string)
  default     = {}
}

variable "network_zone" {
  description = "Hetzner network zone for the subnets (eu-central, us-east, us-west, ap-southeast)."
  type        = string
  default     = "eu-central"
}

variable "location" {
  description = "Hetzner Cloud datacenter location. Used by the NAT gateway server and floating IP."
  type        = string
  default     = "nbg1"
}

# ==============================================================================
# SUBNETS
# Subnets are only created when create_network = true.
# ==============================================================================

variable "subnet_public" {
  description = "CIDR for the public subnet (bastion / NAT gateway tier)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_private" {
  description = "CIDR for the private subnet (web / backend tier)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_db" {
  description = "CIDR for the database subnet."
  type        = string
  default     = "10.0.3.0/24"
}

# ==============================================================================
# NAT GATEWAY
# A dedicated server in the public subnet that masquerades outbound internet
# traffic for private-only servers (no public IP) via iptables MASQUERADE.
# ==============================================================================

variable "nat_gateway_enabled" {
  description = "Deploy a dedicated NAT gateway server. Provides outbound internet access for servers without public IPs."
  type        = bool
  default     = false
}

variable "nat_gateway_server_type" {
  description = "Hetzner Cloud server type for the NAT gateway. A small server (cx22) is sufficient."
  type        = string
  default     = "cx22"
}

variable "nat_gateway_image" {
  description = "OS image for the NAT gateway server."
  type        = string
  default     = "ubuntu-24.04"
}

variable "nat_gateway_ip" {
  description = "Static private IP for the NAT gateway within the public subnet. Defaults to the second usable host in subnet_public (e.g. 10.0.1.2)."
  type        = string
  default     = null
}

variable "nat_gateway_name" {
  description = "Name for the NAT gateway server. Defaults to <network-name>-nat-gw."
  type        = string
  default     = null
}

variable "nat_gateway_ssh_keys" {
  description = "List of pre-existing Hetzner SSH key names to add to the NAT gateway server."
  type        = list(string)
  default     = []
}

variable "nat_gateway_ssh_allowed_cidrs" {
  description = "Source CIDRs allowed to reach SSH (port 22) on the NAT gateway. Restrict to known IPs in production."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "nat_gateway_floating_ip_enabled" {
  description = "Assign a floating IPv4 to the NAT gateway for a stable public endpoint (useful for IP allowlisting)."
  type        = bool
  default     = false
}

variable "nat_gateway_user_data" {
  description = "Custom cloud-init user_data for the NAT gateway. When null, the default config (ip_forward + iptables-persistent MASQUERADE for subnet_private and subnet_db) is applied."
  type        = string
  default     = null
}

variable "nat_gateway_labels" {
  description = "Extra labels merged onto the NAT gateway server and its resources."
  type        = map(string)
  default     = {}
}
