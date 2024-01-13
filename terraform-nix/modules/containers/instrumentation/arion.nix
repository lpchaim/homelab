{ lib, ... }:

with lib;
{
  imports = [
    inputs.arion.nixosModules.arion
  ];

  virtualisation.arion = {
    backend = "docker";
    projects."homelab".settings = {
      services = {
        "whoami".service = {
          image = "traefik/whoami:latest";
          restart = "unless-stopped";
          ports = [ "80:80" ];
          networks = [ "default" "external" ];
        };
      };
      networks = {
        default = {
          name = mkForce "default";
          internal = true;
          ipam.config.subnet = [ "172.16.80.0/24" ];
        };
        external = {
          name = "external";
          ipam.config.subnet = [ "10.10.250.0/24" ];
        };
      };
    };
  };
}
