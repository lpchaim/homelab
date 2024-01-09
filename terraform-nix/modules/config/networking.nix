{ lib ? pkgs.lib, pkgs ? import <nixpkgs>, ... }:

{
  ipv4 = {
    gateway = "10.0.0.1";
    prefixLength = 8;
  };
  ports.internal = {
    http = 8099;
    https = 44399;
  };
  cidrs = rec {
    trusted = private ++ cloudflare;
    private = [ "10.0.0.0/8" "fe80::/10" ];
    cloudflare = builtins.filter
      (x: builtins.stringLength (x) > 0)
      (lib.splitString "\n" (builtins.readFile pkgs.cloudflare-ips));
  };
}
