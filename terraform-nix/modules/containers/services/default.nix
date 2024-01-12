{ config, lib, pkgs, ... }@args:

with lib;
let
  cfg = config.my.containers.services;
  utils = pkgs.callPackage ./utils.nix args;
  inherit (utils) makeEnableOptionDefaultTrue;
in
{
  imports =
    let importArgs = args // { inherit utils; };
    in [
      (import ./management importArgs)
      (import ./media importArgs)
      (import ./misc importArgs)
      (import ./storage importArgs)
      (import ./networking importArgs)
    ];

  options.my.containers.services =
    let
      enabledServices = filterAttrs (_: service: service.condition) cfg.contents;
      rawServices = mapAttrs (_: service: service.content) enabledServices;
    in
    {
      enable = makeEnableOptionDefaultTrue "containerized services";
      contents = mkOption { default = { }; };
      out = mkOption { default = rawServices; };
    };
}
