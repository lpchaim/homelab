# Documentation: https://nixos.wiki/wiki/Traefik

{ config, inputs, lib, options, pkgs, system, ... }:

with lib;
let
  cfg = config.my.services.traefik;
  myCfg = config.my;

  dataDir = config.services.traefik.dataDir;
  domain = myCfg.domain;
  lxcs = filterAttrs (_: lxc: lxc ? services) config.my.lxcs;

  trustedIpsPrivate = myCfg.networking.cidrs.private;
  trustedIps = myCfg.networking.cidrs.trusted;
in
with lib;
{
  options.my.services.traefik = {
    enable = mkEnableOption "traefik";
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/traefik/traefik.env;
      defaultSopsFormat = "dotenv";
      secrets."traefik.env" = { };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 8080 ];

    services.traefik = {
      enable = true;
      package = pkgs.traefik-custom;
      environmentFiles = [ "/run/secrets/traefik.env" ];
      dynamicConfigOptions = {
        http = {
          routers = {
            api = {
              rule = "Host(`traefik.${domain}`)";
              entrypoints = [ "websecure" ];
              service = "api@internal";
              middlewares = [ "auth@file" "default@file" ];
              tls.certResolver = "letsEncrypt";
            };
          } // mapAttrs'
            (_: lxc: nameValuePair lxc.name {
              rule = "Host(`${lxc.name}.${domain}`)";
              entrypoints = [ "websecure" ];
              service = lxc.name;
              middlewares = [ "default@file" ];
              tls.certResolver = "letsEncrypt";
            })
            lxcs;
          services = mapAttrs'
            (_: lxc: nameValuePair lxc.name {
              loadBalancer.servers = map (url: { inherit url; }) lxc.services;
            })
            lxcs;
          middlewares = {
            default.chain.middlewares = [
              "cloudflarewarp"
              # "crowdsec"
              "default-security-headers"
              "gzip"
            ];
            auth.basicAuth.users = [ "{{ env `TRAEFIK_PASSWORD_HASHED` }}" ];
            cloudflarewarp.plugin.cloudflarewarp = {
              disableDefault = true;
              trustIp = trustedIps;
            };
            # crowdsec.plugin.bouncer = { # TODO Enable crowdsec
            #   enabled = true;
            #   logLevel = "INFO";
            #   crowdsecMode = "live"; # live | stream | alone
            #   updateIntervalSeconds = 60; # For stream mode
            #   defaultDecisionSeconds = 60; # For live mode
            #   crowdsecLapiKey = "$CROWDSEC_BOUNCER_API_KEY";
            #   crowdsecLapiHost = "crowdsec:8080";
            #   crowdsecLapiScheme = "http";
            #   crowdsecLapiTLSInsecureVerify = false;
            #   forwardedHeadersTrustedIPs: trustedIps
            #   clientTrustedIPs: trustedIpsPrivate
            #   forwardedHeadersCustomName = "X-Forwarded-For";
            # };
            default-security-headers.headers = {
              browserXssFilter = true; # X-XSS-Protection=1; mode=block
              contentTypeNosniff = true; # X-Content-Type-Options=nosniff
              forceSTSHeader = true; # Add the Strict-Transport-Security header even when the connection is HTTP
              frameDeny = false; # X-Frame-Options=deny
              customFrameOptionsValue = "SAMEORIGIN";
              referrerPolicy = "no-referrer-when-downgrade";
              sslRedirect = true; # Allow only https requests
              stsIncludeSubdomains = true; # Add includeSubdomains to the Strict-Transport-Security header
              stsPreload = true; # Add preload flag appended to the Strict-Transport-Security header
              stsSeconds = "31536000"; # Set the max-age of the Strict-Transport-Security header (63072000 = 2 years)
              customResponseHeaders = {
                "X-Robots-Tags" = "noindex, nofollow";
              };
            };
            gzip.compress = { };
            httpsRedirect.redirectScheme.scheme = "https";
            nextcloudSecureHeaders.headers = {
              hostsProxyHeaders = [
                "X-Forwarded-Host"
              ];
              referrerPolicy = "same-origin";
            };
          };
          serversTransports.ignoreCert.insecureSkipVerify = true;
        };
        tls.options = {
          modern = {
            minVersion = "versionTLS12";
            sniStrict = true;
          };
          intermediate = {
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
            ];
            minVersion = "versionTLS13";
            sniStrict = true;
          };
          old = {
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
              "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA"
              "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"
              "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA"
              "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"
              "TLS_RSA_WITH_AES_128_GCM_SHA256"
              "TLS_RSA_WITH_AES_256_GCM_SHA384"
              "TLS_RSA_WITH_AES_128_CBC_SHA256"
              "TLS_RSA_WITH_AES_128_CBC_SHA"
              "TLS_RSA_WITH_AES_256_CBC_SHA"
              "TLS_RSA_WITH_3DES_EDE_CBC_SHA"
            ];
            minVersion = "TLDv1";
            sniStrict = true;
          };
        };
      };
      staticConfigOptions = {
        api = {
          dashboard = true;
          insecure = true;
        };
        certificatesResolvers.letsEncrypt.acme = {
          email = myCfg.email;
          storage = "${dataDir}/acme/acme.json";
          dnsChallenge.provider = "cloudflare";
        };
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
            http.tls.certResolver = "letsEncrypt";
            forwardedHeaders.trustedIps = trustedIps;
          };
        };
        global = {
          checknewversion = false;
          sendanonymoususage = false;
        };
        # providers = { # TODO Consider how to properly implement docker
        #   docker = {
        #     endpoint = "ssh://root@10.10.10.0:22"; # Listen to the UNIX Docker socket
        #     exposedByDefault = false; # Only expose container that are explicitly enabled (using label traefik.enabled)
        #     network = "external"; # Default network to use for connections to all containers.
        #     watch = true; # Watch Docker Swarm events
        #   };
        #   providersThrottleDuration = 10;
        # };
        experimental.localPlugins = {
          bouncer.moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
          cloudflarewarp.moduleName = "github.com/BilikoX/cloudflarewarp";
        };
        log = { };
        accessLog = { };
      };
    };

    systemd.services.traefik = {
      serviceConfig.WorkingDirectory = dataDir;
      preStart = ''
        umask 077
        mkdir -p ${dataDir}/{acme,plugins-storage}
        ln -sfn ${config.services.traefik.package}/bin/plugins-local ${dataDir}
      '';
    };
  };
}
