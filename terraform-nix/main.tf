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
      name = "proxmox-nix"
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

resource "proxmox_lxc" "nixos-caddy" {
  vmid   = "241"
  tags   = "nixos,caddy"
  memory = var.default_mem
  cores  = 4

  hostname = "nixos-caddy"
  network {
    name   = "eth0"
    bridge  = "vmbr0"
    ip      = "10.10.2.41/${var.network_subnet}"
    ip6     = "dhcp"
    gw = var.network_gateway
  }

  target_node     = var.pm_node_name
  ostemplate      = var.pm_lxc_template
  ssh_public_keys = var.authorized_keys
  start           = true
  cmode           = "console"

  features {
    nesting = true
  }
  lifecycle {
    ignore_changes = [
      rootfs
    ]
  }
}

module "nixos" {
  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host = "root@10.10.2.41"

  flake = ".#caddy"

  arguments = [
    # You can build on another machine, including the target machine, by
    # enabling this option, but if you build on the target machine then make
    # sure that the firewall and security group permit outbound connections.
    # "--build-host", "root@${var.caddy_ip}",
  ]

  ssh_options = "-o StrictHostKeyChecking=accept-new"

  depends_on = [proxmox_lxc.nixos-caddy]
}
