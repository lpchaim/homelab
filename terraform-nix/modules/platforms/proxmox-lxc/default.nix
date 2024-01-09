{ config, lib, options, pkgs, ... }:

with lib;

let
  cfg = config.my.platforms.proxmox-lxc;
in {
  options.my.platforms.proxmox-lxc = {
    enable = mkEnableOption "custom LXC tweaks";
  };

  config = mkIf cfg.enable {
    systemd.network.networks.eth0 = {
      matchConfig.Name = "eth0";
      linkConfig.RequiredForOnline = "routable"; # Workaround for the LXC sometimes not detecting a valid internet connection even though it's clearly up
      networkConfig.Description = "Default connection";
    };

    proxmoxLXC = {
      manageNetwork = mkDefault false;
      manageHostName = false;
    };
  };
}
