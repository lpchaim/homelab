variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = false
}

variable "pm_host" {
  description = "Hostname or IP of the proxmox server"
  type        = string
}

variable "pm_node_name" {
  description = "Name of the proxmox node to create the VMs on"
  type        = string
  default     = "pve"
}

variable "pm_lxc_template" {
  description = "Name of the LXC image to use"
  type        = string
}

variable "network_subnet" {
  description = "Subnet to use for each VM's network adapter"
  default     = 8
}

variable "network_gateway" {
  description = "Default gateway to use for each VM's network adapter"
  default     = "10.0.0.1"
}

variable "authorized_keys" {
  description = "Authorized keys"
  type        = string
}

variable "default_mem" {
  description = "Number of server nodes to provision"
  type        = string
}
