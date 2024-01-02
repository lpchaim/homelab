# Documentation: https://nixos.wiki/wiki/Jellyfin

{ config, lib, options, pkgs, ... }:

let
  cfg = config.my.services.jellyfin;
in
with lib;
{
  options.my.services.jellyfin = {
    enable = mkEnableOption "jellyfin";
  };

  config = mkIf cfg.enable {
    proxmoxLXC.privileged = true;

    users = {
      extraUsers.jellyfin = {
        uid = 1000;
        group = "jellyfin";
        extraGroups = [ "host-render" "host-video" ];
      };
      extraGroups = {
        host-render.gid = 103;
        host-video.gid = 44;
        jellyfin.gid = 1000;
      };
    };

    environment.systemPackages = with pkgs; [
      intel-gpu-tools
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
      libva-utils
    ];

    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };

    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };
}
