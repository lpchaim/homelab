{ lib, ... }@args:

with lib;
let
  mkReadonlyOption = default: mkOption { inherit default; readOnly = true; };
in
{
  options.my = {
    domain = mkReadonlyOption "lpcha.im";
    email = mkReadonlyOption "lpchaim@gmail.com";
    lxcs = mkReadonlyOption (import ../../lxcs args);
    networking = mkReadonlyOption (import ./networking.nix args);
    storage = mkReadonlyOption (import ./storage.nix);
    timezone = mkReadonlyOption "America/Sao_Paulo";
  };
}
