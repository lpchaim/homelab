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

variable "pm_template_vm_name" {
  description = "Name of the cloud-init VM template to use"
  type        = string
}

variable "private_key" {
  description = "Path of the private key to use"
  type        = string
}

variable "k3s_server_count" {
  description = "Number of server nodes to provision"
  type        = number
  default     = 1
}

variable "k3s_server_mem" {
  description = "Memory of server nodes in MiB"
  default     = "2048"
}

variable "k3s_server_ips" {
  description = "List of IP addresses for server nodes"
}

variable "k3s_agent_count" {
  description = "Number of agent nodes to provision"
  type        = number
  default     = 2
}

variable "k3s_agent_mem" {
  description = "Memory of agent nodes in MiB"
  default     = "2048"
}

variable "k3s_agent_ips" {
  description = "List of IP addresses for agent nodes"
}

variable "network_subnet" {
  description = "Subnet to use for each VM's network adapter"
  default     = 8
}

variable "network_gateway" {
  description = "Default gateway to use for each VM's network adapter"
  default = "10.0.0.1"
}
