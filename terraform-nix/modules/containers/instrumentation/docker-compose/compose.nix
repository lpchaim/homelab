{ config, lib, ... }:

with lib;
{
  name = "homelab";
  version = "3.6";

  services =
    let
      enabledServices = filterAttrs (_: service: if service ? _type then service.condition else true) config.my.containers.services.contents;
      serviceContents = mapAttrs (_: service: if service ? _type then service.content else service) enabledServices;
    in serviceContents;

  networks = {
    default = {
      internal = true;
      ipam.config = [{ subnet = "172.16.80.0/24"; }];
    };

    external.ipam.config = [{ subnet = "10.10.250.0/24"; }];
  };
}
