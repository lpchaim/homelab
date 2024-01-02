# Documentation: https://nixos.wiki/wiki/Caddy

{
  services.caddy = {
      enable = true;
    virtualHosts."localhost".extraConfig = ''
      respond "Hello, world!"
    '';
  };
}
