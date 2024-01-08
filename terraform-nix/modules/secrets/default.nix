# Documentation: https://github.com/Mic92/sops-nix

{ lib, ... }:

with lib;
{
  sops = {
    defaultSopsFile = mkDefault ../../secrets/default.env;
    defaultSopsFormat = "dotenv";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
