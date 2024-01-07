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
  lxcs = {
    for vmid, lxc in var.lxcs : vmid => merge(lxc, {
      flake = coalesce(lxc.flake, lxc.name)
    }) if lxc.enable
  }
}

resource "proxmox_lxc" "nixos" {
  for_each = local.lxcs

  vmid         = each.key
  tags         = join(";", sort(concat(["nixos", "terraform"], each.value.tags)))
  start        = true
  onboot       = each.value.onboot
  unprivileged = !each.value.privileged

  cores  = each.value.cores
  memory = each.value.memory
  swap   = each.value.swap

  rootfs {
    storage = "local-lvm"
    size    = each.value.rootfs_size
  }
  dynamic "mountpoint" {
    for_each = each.value.mountpoints
    content {
      slot    = coalesce(mountpoint.value["slot"], mountpoint.key)
      mp      = mountpoint.value["mp"]
      storage = mountpoint.value["storage"]
      volume  = mountpoint.value["volume"]
      key     = mountpoint.value["key"]
      size    = mountpoint.value["size"]
    }
  }

  hostname = each.value.name
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${each.value.ip}/${var.network_subnet}"
    gw     = var.network_gateway
  }

  target_node     = var.pm_node_name
  ostemplate      = var.pm_lxc_template
  ssh_public_keys = var.authorized_keys
  cmode           = "console"

  features {
    nesting = true
  }

  lifecycle {
    ignore_changes = [
      rootfs,
    ]
  }

  connection {
    type        = "ssh"
    user        = var.pm_user
    host        = var.pm_host
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = length(each.value.extra_config) > 0 ? concat(
      [for line in each.value.extra_config : "echo '${line}' >> /etc/pve/lxc/${each.key}.conf"],
      [
        "awk -i inplace '!a[$0]++' /etc/pve/lxc/${each.key}.conf", # Removes duplicate lines, just in case
        "pct reboot ${each.key}"
      ]
    ) : [":"]
  }
}

module "nixos" {
  for_each = { for key, val in local.lxcs : key => val if var.build }

  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host  = "${each.value.user}@${each.value.ip}"
  flake = ".#${each.value.flake}"

  arguments = each.value.remotebuild ? [
    # You can build on another machine, including the target machine, by
    # enabling this option, but if you build on the target machine then make
    # sure that the firewall and security group permit outbound connections.
    "--build-host", "${each.value.user}@${each.value.ip}",
  ] : []

  ssh_options = "-o StrictHostKeyChecking=accept-new"

  depends_on = [proxmox_lxc.nixos]
}
