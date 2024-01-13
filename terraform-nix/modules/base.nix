{ lib, pkgs, ... }:

with lib;
{
  # Packages and services
  environment.systemPackages = with pkgs; [
    bat
    helix
    vim
  ];
  services.avahi = {
    enable = true;
    openFirewall = true;
  };

  # Environment
  environment.sessionVariables = {
    EDITOR = "hx";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # Package manager
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = flakes nix-command
    '';
    settings = {
      keep-outputs = true;
    };
    gc = {
      automatic = true;
      dates = "daily";
    };
  };

  # Networking
  networking.firewall.enable = mkDefault true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.enableIPv6 = mkDefault false;

  # Internationalization
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;
  services.xserver.xkb.layout = "br";
}
