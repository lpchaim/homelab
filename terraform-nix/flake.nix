{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixpkgs, nixpkgs-unstable, nixos-generators, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        makePkgs = nixpkgs:
          import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
          };
        pkgs = makePkgs nixpkgs;
        pkgsUnstable = makePkgs nixpkgs-unstable;

        makeCommonConfig = modules: {
          inherit system;
          modules = [{ system.stateVersion = "23.11"; } ./modules] ++ modules;
          specialArgs = { inherit inputs pkgs system; };
        };
        makeProxmoxLxcConfig = modules:
          nixpkgs.lib.nixosSystem (
            makeCommonConfig (modules ++ [
              { my.platforms.proxmox-lxc.enable = true; }
              nixos-generators.nixosModules.proxmox-lxc
            ])
          );
        makeProxmoxLxcTarball = modules:
          nixos-generators.nixosGenerate (makeCommonConfig modules // {
            format = "proxmox-lxc";
            pkgs = nixpkgs.legacyPackages.${system};
            lib = nixpkgs.legacyPackages.${system}.lib;
          });

        serviceFiles = builtins.removeAttrs (builtins.readDir ./modules/services) [ "default.nix" ];
        services = builtins.map (name: pkgs.lib.removeSuffix ".nix" name) (builtins.attrNames serviceFiles);
      in
      with pkgs.lib;
      {
        apps =
          let
            makeDefaultTerraformCmd = cmd: {
              type = "app";
              program = toString (pkgs.writers.writeBash cmd ''
                ${self.apps.${system}.generateTerraformVars.program}
                ${pkgs.terraform}/bin/terraform ${cmd}
              '');
            };
          in
          {
            default = self.apps.${system}.apply;
            generateTerraformVars = {
              type = "app";
              program =
                let
                  tfVarsFile = "nix.auto.tfvars.json";
                in
                toString (pkgs.writers.writeBash "generateTerraformVars" ''
                  if [[ -e ${tfVarsFile} ]]; then rm -f ${tfVarsFile}; fi
                  cp ${self.packages.${system}.terraform-vars} ${tfVarsFile}
                '');
            };
          } // genAttrs [ "init" "plan" "apply" "destroy" ] makeDefaultTerraformCmd;

        legacyPackages.nixosConfigurations = genAttrs services (name: makeProxmoxLxcConfig [{ config.my.services.${name}.enable = true; }]);
        packages = rec {
          default = base-proxmox-lxc;
          base-proxmox-lxc = makeProxmoxLxcTarball [ ];
          terraform-vars =
            let
              tfVars = { lxcs = import ./lxcs; };
            in
            pkgs.runCommand "terraform-vars" { } ''
              echo '${builtins.toJSON tfVars}' | ${pkgs.jq}/bin/jq > $out
            '';
        } // genAttrs services (name: makeProxmoxLxcTarball [{ config.my.services.${name}.enable = true; }]);

        devShells.default =
          with pkgsUnstable;
          mkShell {
            buildInputs = [
              (terraform.withPlugins (b: with b; [
                external
                local
                null
                proxmox
              ]))
              rnix-lsp
              nixfmt
              nixpkgs-fmt
            ];
          };
      }
    );
}
