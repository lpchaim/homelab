{ pkgs, ... }:

{
  imports = [
    ./base.nix
    ./config
    ./containers
    ./platforms
    ./secrets
    ./services
  ];
}
