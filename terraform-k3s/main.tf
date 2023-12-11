terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=2.9.14"
    }
  }

  cloud {
    organization = "lpchaim"
    workspaces {
      name = "k3s-proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://${var.pm_host}:8006/api2/json"
  pm_tls_insecure = var.pm_tls_insecure
  pm_parallel     = 10
  pm_timeout      = 60
  pm_log_enable   = true
  pm_log_file     = "./logs/terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

resource "proxmox_vm_qemu" "proxmox_vm_server" {
  count = var.k3s_server_count

  target_node = var.pm_node_name
  pool        = "k8s"

  vmid       = "21${format("%02d", count.index)}"
  name       = "k3s-server-${count.index}"
  tags       = "k3s,k3s-server"
  ipconfig0  = "ip=${var.k3s_server_ips[count.index]}/${var.network_subnet},gw=${var.network_gateway}"
  memory     = var.k3s_server_mem
  cores      = 4
  os_type    = "cloud-init"
  scsihw     = "virtio-scsi-pci"
  agent      = 1
  clone      = var.pm_template_vm_name
  full_clone = false

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }
}

resource "proxmox_vm_qemu" "proxmox_vm_agent" {
  count = var.k3s_agent_count

  target_node = var.pm_node_name
  pool        = "k8s"

  vmid       = "22${format("%02d", count.index)}"
  name       = "k3s-agent-${count.index}"
  tags       = "k3s,k3s-agent"
  ipconfig0  = "ip=${var.k3s_agent_ips[count.index]}/${var.network_subnet},gw=${var.network_gateway}"
  memory     = var.k3s_agent_mem
  cores      = 4
  os_type    = "cloud-init"
  scsihw     = "virtio-scsi-pci"
  agent      = 1
  clone      = var.pm_template_vm_name
  full_clone = false

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }
}
