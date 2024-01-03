{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, flake-utils, nixpkgs, nixpkgs-unstable, nixos-generators, sops-nix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        my.config = import ./config.nix;

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
          modules = [{ system.stateVersion = "23.11"; } ./modules sops-nix.nixosModules.sops] ++ modules;
          specialArgs = { inherit inputs my pkgs system; };
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
            makeTfVarsPackage = tfVars: pkgs.runCommand "terraform-vars" { } ''
                echo '${builtins.toJSON tfVars}' | ${pkgs.jq}/bin/jq > $out
              '';
            makeGenerateTfVars = name: package:
              let tfVarsFile = "${name}.auto.tfvars.json";
              in {
                type = "app";
                program = toString (pkgs.writers.writeBash "package-${package.name}" ''
                  if [[ -e ${tfVarsFile} ]]; then rm -f ${tfVarsFile}; fi
                  cp ${package} ${tfVarsFile}
                '');
              };
            enableBuild = makeGenerateTfVars "nix-build" (makeTfVarsPackage { build = true; });
            disableBuild = makeGenerateTfVars "nix-build" (makeTfVarsPackage { build = false; });
            generateTerraformVars = makeGenerateTfVars "nix-lxcs" (makeTfVarsPackage { lxcs = import ./lxcs; });
          in
          {
            default = self.apps.${system}.deploy;
            deploy = {
              type = "app";
              program = toString (pkgs.writers.writeBash "deploy" ''
                ${enableBuild.program}
                ${generateTerraformVars.program}
                ${pkgs.terraform}/bin/terraform apply
              '');
            };
            ageFromSsh = {
              type = "app";
              program = toString (pkgs.writers.writeBash "ageFromSsh" ''
                ssh-keyscan "$1" | ${pkgs.ssh-to-age}/bin/ssh-to-age
              '');
            };
          } // genAttrs [ "init" "plan" "apply" "destroy" ] (cmd: {
            type = "app";
            program = toString (pkgs.writers.writeBash cmd ''
              ${disableBuild.program}
              ${generateTerraformVars.program}
              ${pkgs.terraform}/bin/terraform ${cmd}
            '');
          });

        legacyPackages.nixosConfigurations = genAttrs services (name: makeProxmoxLxcConfig [{ config.my.services.${name}.enable = true; }]);
        packages = rec {
          default = base-proxmox-lxc;
          base-proxmox-lxc = makeProxmoxLxcTarball [ ];
        } // genAttrs services (name: makeProxmoxLxcTarball [{ config.my.services.${name}.enable = true; }]);

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            age
            (terraform.withPlugins (b: with b; [
              external
              local
              b.null
              proxmox
            ]))
            nixd
            nixpkgs-fmt
            sops
          ];
        };
      });
}
