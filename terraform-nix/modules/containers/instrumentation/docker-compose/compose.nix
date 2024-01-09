{ config, ... }:

{
  name = "homelab";
  version = "3.6";

  services = config.my.containers.services;

  networks = {
    default = {
      internal = true;
      ipam.config = [{ subnet = "172.16.80.0/24"; }];
    };

    external.ipam.config = [{ subnet = "10.10.250.0/24"; }];
  };
}
