{ lib, ... }@args:

with lib;
let
  config.my = {
    networking = import ../modules/config/networking.nix args;
    storage = import ../modules/config/storage.nix args;
  };

  makeDefault = lxc: lxc // {
    nix.modules = (lxc.nix.modules or [ ]) ++ [
      (enableServiceByName lxc.name)
      (manageNetwork lxc.ip)
    ];
  };
  enableServiceByName = name: { config.my.services.${name}.enable = true; };
  manageNetwork = ip: {
    config.proxmoxLXC.manageNetwork = true;
    config.networking = {
      interfaces = {
        eth0.ipv4.addresses = [{
          address = ip;
          prefixLength = config.my.networking.ipv4.prefixLength;
        }];
      };
      defaultGateway = {
        address = config.my.networking.ipv4.gateway;
        interface = "eth0";
      };
      nameservers = [ "10.0.0.2" ];
    };
  };

  byId = {
    "241" = makeDefault {
      name = "caddy";
      enable = false;
      ip = "10.10.2.41";
      tags = [ "networking" ];
      cores = 2;
      memory = 256;
    };
    "300" = makeDefault {
      name = "traefik";
      enable = false;
      ip = "10.10.3.0";
      tags = [ "networking" ];
      cores = 2;
      memory = 512;
      mountpoints = [
        { mp = "/etc/crowdsec"; volume = "/srv/storage/AppData/config/crowdsec"; }
        { mp = "/var/lib/crowdsec"; volume = "/srv/storage/AppData/data/crowdsec"; }
      ];
    };
    "810" = makeDefault rec {
      name = "jellyfin";
      privileged = true;
      ip = "10.10.8.10";
      services = [ "http://${ip}:8096" ];
      tags = [ "media" ];
      memory = 4096;
      cores = 6;
      extra_config = [
        "lxc.cgroup2.devices.allow: c 226:0 rwm"
        "lxc.cgroup2.devices.allow: c 226:128 rwm"
        "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file,mode=0666"
        "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file"
      ];
      mountpoints =
        let
          cfgPath = config.my.storage.getConfigPath "jellyfin";
        in
        [
          { mp = "/data"; volume = config.my.storage.main; }
          { mp = "/config"; volume = cfgPath; }
          { mp = "/var/lib/jellyfin/data"; volume = "${cfgPath}/data/data"; }
          { mp = "/var/lib/jellyfin/metadata"; volume = "${cfgPath}/data/metadata"; }
          { mp = "/var/lib/jellyfin/plugins"; volume = "${cfgPath}/data/plugins"; }
          { mp = "/var/lib/jellyfin/root"; volume = "${cfgPath}/data/root"; }
          { mp = "/var/cache/jellyfin"; volume = "${cfgPath}/cache"; }
        ];
    };
    "1000" = makeDefault {
      name = "docker";
      privileged = true;
      ip = "10.10.10.0";
      tags = [ "docker" ];
      memory = 4096;
      cores = 6;
      rootfs_size = "30G";
      mountpoints = [
        { mp = "/srv/storage"; volume = "/srv/storage"; }
      ];
      nix.modules = [{
        config.my.containers = {
          instrumentation.compose.enable = true;
          services = {
            adguardhome-sync.enable = false;
            jackett.enable = false;
            jellyfin.enable = false;
            mylar.enable = false;
            readarr.enable = false;
          };
        };
      }];
    };
  };
in
rec {
  inherit byId;
  asList = attrValues byId;
  byName = mapAttrs' (_: lxc: nameValuePair lxc.name lxc) byId;
  byRole = { reverseProxy = byName.traefik; };
}
