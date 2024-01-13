{ inputs, pkgs, ... }:

(final: prev: {
  cloudflare-ips = pkgs.runCommand "cloudflare-ips" { } ''
    cat ${inputs.mmproxy}/cloudflare-ip-ranges.txt > $out
  '';
})
