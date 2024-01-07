{
  defaultGateway = "10.0.0.1";
  defaultPrefixLength = "8";
  cidrs = rec {
    trusted = private ++ cloudflare;
    private = [ "10.0.0.0/8" "fe80::/10" ];
    cloudflare = builtins.filter
      (x: stringLength (x) > 0)
      (splitString "\n" (builtins.readFile pkgs.cloudflare-ips));
  };
}
