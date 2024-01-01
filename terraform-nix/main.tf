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

locals {
  lxcs = [
    for lxc in var.lxcs : merge(lxc, {
      flake = coalesce(lxc.flake, lxc.name)
    }) if lxc.enable
  ]
}

resource "proxmox_lxc" "nixos_lxc" {
  count = length(local.lxcs)

  vmid   = local.lxcs[count.index].vmid
  tags   = join(";", sort(concat([ "nixos", "terraform" ], local.lxcs[count.index].tags)))

  cores  = local.lxcs[count.index].cores
  memory = local.lxcs[count.index].memory
  swap = local.lxcs[count.index].swap

  hostname = "nixos-${local.lxcs[count.index].name}"
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${local.lxcs[count.index].ip}/${var.network_subnet}"
    ip6    = "dhcp"
    gw     = var.network_gateway
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
  count  = length(local.lxcs)
  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host  = "${local.lxcs[count.index].user}@${local.lxcs[count.index].ip}"
  flake = ".#${local.lxcs[count.index].flake}"

  arguments = [
    # You can build on another machine, including the target machine, by
    # enabling this option, but if you build on the target machine then make
    # sure that the firewall and security group permit outbound connections.
    "--build-host", "${local.lxcs[count.index].user}@${local.lxcs[count.index].ip}",
  ]

  ssh_options = "-o StrictHostKeyChecking=no"

  depends_on = [proxmox_lxc.nixos_lxc]
}
