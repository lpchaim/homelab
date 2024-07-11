# Documentation: https://nixos.wiki/wiki/Podman

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.services.podman;
in
with lib;
{
  options.my.services.podman = {
    enable = mkEnableOption "podman";
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" "--force" ];
        dates = "weekly";
      };
    };

    environment.systemPackages = with pkgs; [
      podman-compose
    ];
  };
}
