{ lib, ... }:

with lib;
let
  makeDefaultModules = name: [{ config.my.services.${name}.enable = true; }];
  byId = {
    "241" = {
      name = "caddy";
      enable = false;
      ip = "10.10.2.41";
      tags = [ "networking" ];
      cores = 2;
      memory = 256;
      nix.modules = makeDefaultModules "caddy";
    };
    "300" = {
      name = "traefik";
      enable = false;
      remotebuild = false;
      ip = "10.10.3.0";
      tags = [ "networking" ];
      cores = 2;
      memory = 512;
      mountpoints = [
        { mp = "/etc/crowdsec"; volume = "/srv/storage/AppData/config/crowdsec"; }
        { mp = "/var/lib/crowdsec"; volume = "/srv/storage/AppData/data/crowdsec"; }
      ];
      nix.modules = makeDefaultModules "traefik";
    };
    "810" = rec {
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
      mountpoints = [
        { mp = "/data"; volume = "/srv/storage"; }
        { mp = "/config"; volume = "/srv/storage/AppData/config/jellyfin"; }
        { mp = "/var/lib/jellyfin/data"; volume = "/srv/storage/AppData/config/jellyfin/data/data"; }
        { mp = "/var/lib/jellyfin/metadata"; volume = "/srv/storage/AppData/config/jellyfin/data/metadata"; }
        { mp = "/var/lib/jellyfin/plugins"; volume = "/srv/storage/AppData/config/jellyfin/data/plugins"; }
        { mp = "/var/lib/jellyfin/root"; volume = "/srv/storage/AppData/config/jellyfin/data/root"; }
        { mp = "/var/cache/jellyfin"; volume = "/srv/storage/AppData/config/jellyfin/cache"; }
      ];
      nix.modules = makeDefaultModules "jellyfin";
    };
  };
in
rec {
  inherit byId;
  asList = attrValues byId;
  byName = mapAttrs' (_: lxc: nameValuePair lxc.name lxc) byId;
  byRole = { reverseProxy = byName.traefik; };
}
