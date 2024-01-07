# Documentation: https://github.com/Mic92/sops-nix

{ config, lib, options, ... }:

with lib;
{
  sops = {
    defaultSopsFile = mkDefault ../../secrets/default.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
