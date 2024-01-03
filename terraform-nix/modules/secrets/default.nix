# Documentation: https://github.com/Mic92/sops-nix

{ config, options, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
