{ config, lib, pkgs, ... }:

with lib;
{
  makeEnableOptionDefaultTrue = name: mkEnableOption name // { default = config.my.services.docker.enable; };

  makeDefault = dockerConfig:
    (dockerConfig // {
      environment = {
        TZ = config.my.timezone;
        PUID = 1000;
        GUID = 1000;
      } // (dockerConfig.environment or { });
      volumes = [
        "/dev/rtc:/dev/rtc:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/etc/timezone:/etc/timezone:ro"
      ] ++ (dockerConfig.volumes or [ ]);
      restart = dockerConfig.restart or "unless-stopped";
    });

  makeAssetsDerivation = name: path: pkgs.stdenvNoCC.mkDerivation {
    name = "${name}-assets";
    src = path;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
    '';
  };

  /**
   * Creates a directory at /run/${name} and optionally templates select files with envsubst
   */
  makeRuntimeAssetsDir =
    { name
    , assets
    , filesToTemplate ? [ ]
    , envPath ? null
    , extraEnv ? {}
    , envFile ? "docker.env"
    }:
    let
      configDir = "/run/${name}";
      hasTemplates = (envPath != null) && ((lib.length filesToTemplate) > 0);
    in {
      sops.secrets."${name}.env".sopsFile = lib.mkIf hasTemplates envPath;

      systemd.services = {
        "create-runtime-${name}" = {
          requiredBy = [ "multi-user.target" "docker.service" ];
          restartIfChanged = true;
          serviceConfig = {
            Type = "simple";
            ExecStart =
              let
                makeTemplateLogic = map (path: ''
                  ${pkgs.envsubst}/bin/envsubst -fail-fast -no-empty -no-unset \
                  < ${assets}/${path} \
                  > ${configDir}/${path}
                '');
              in
              pkgs.writers.writeBash "template-${name}" (''
                mkdir -p ${configDir}
                cp -r \
                  ${assets}/* \
                  ${configDir}/
              '' + (lib.optionalString hasTemplates ''
                while IFS= read -r line; do
                  export $line
                done < /run/secrets/${envFile}
                ${concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: val: "export ${name}=${val}") extraEnv))}
                ${concatStringsSep "\n" (makeTemplateLogic filesToTemplate)}
              '') + (lib.optionalString config.my.containers.instrumentation.compose.enable ''
                ${pkgs.docker}/bin/docker compose --file ~/compose.yaml restart ${name}
              ''));
          };
        };
      };
    };
}
