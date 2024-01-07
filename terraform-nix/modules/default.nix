{ pkgs, ... }:

{
  imports = [
    ./base.nix
    ./config
    ./platforms
    ./secrets
    ./services
  ];
}
