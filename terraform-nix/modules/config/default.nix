{ lib, ... }@args:

with lib;
let
  mkReadonlyOption = default: mkOption { inherit default; readOnly = true; };
in
{
  options.my = {
    domain = mkReadonlyOption "lpcha.im";
    email = mkReadonlyOption "lpchaim@gmail.com";
    networking = mkReadonlyOption (import ./networking.nix);
    storage = mkReadonlyOption (import ./storage.nix);
    lxcs = mkReadonlyOption (import ../../lxcs args);
  };
}
