variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = false
}

variable "pm_host" {
  description = "Hostname or IP of the proxmox server"
  type        = string
}

variable "pm_user" {
  description = "PVE node user"
  type        = string
  default     = "root"
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

variable "lxcs" {
  description = "List of maps describing LXC containers"
  type = list(object({
    name        = string
    vmid        = number
    ip          = string
    enable      = optional(bool, true)
    onboot      = optional(bool, true)
    rootfs_size = optional(string, "8G")
    privileged  = optional(bool, false)
    user        = optional(string, "root")
    flake       = optional(string, null)
    tags        = optional(list(string), [])
    memory      = optional(number, 1024)
    swap        = optional(number, 0)
    cores       = optional(number, 6)
    mountpoints = optional(list(object({
      mp      = string
      volume  = string
      slot    = optional(number)
      key     = optional(string, "")
      storage = optional(string, "")
      size    = optional(string, "0T")
    })), [])
    extra_config = optional(list(string), [])
  }))
}

variable "build" {
  description = "Whether to build the NixOS configurations"
  type = bool
  default = false
}
