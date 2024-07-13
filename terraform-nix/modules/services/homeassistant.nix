# Documentation: https://nixos.wiki/wiki/Home_Assistant

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.my.services.homeassistant;
  themes.catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "home-assistant";
    rev = "v1.0.2";
    sha256 = "sha256-eUqYlaXNLPfaKn3xcRm5AQwTOKf70JF8cepibBb9KXc=";
  };
in
{
  options.my.services.homeassistant = {
    enable = mkEnableOption "home-assistant";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.home-assistant = {
        enable = true;
        package = pkgs.home-assistant;
        openFirewall = true;
        configDir = "/var/lib/hass/data";
        extraComponents = [
          "esphome"
          "google_translate"
          "met"
          "radio_browser"
        ];
        customComponents = with pkgs.home-assistant-custom-components; [
          gpio
          localtuya
        ];
        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
          mini-graph-card
          mini-media-player
        ];
        config = {
          default_config = {};
          http = {};
          homeassistant = {
            unit_system = "metric";
            temperature_unit = "C";
            name = "Casa";
            time_zone = "America/Sao_Paulo";
            latitude = -23.6672252892582;
            longitude = -52.6239323616028;
          };
          frontend.themes = "!include_dir_merge_named themes";
          automation = {
            alias = "startup";
            description = "";
            mode = "single";
            trigger = [
              {
                platform = "homeassistant";
                event = "start";
              }
            ];
            condition = [];
            action = [
              {
                service = "frontend.set_theme";
                data = {
                  "mode" = "dark";
                  "name" = "Catppuccin Mocha";
                };
              }
            ];
          };
        };
      };

      home-manager.users.hass = {
        programs.home-manager.enable = true;
        home = {
          username = "hass";
          homeDirectory = config.services.home-assistant.configDir;
          stateVersion = "23.11";
          file = {
            "themes/catppuccin.yaml".source = themes.catppuccin + "/themes/catppuccin.yaml";
          };
        };
      };
    }
  ]);
}
