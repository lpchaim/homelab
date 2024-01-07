{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";

    flake-utils.url = "github:numtide/flake-utils";
    mmproxy = {
      flake = false;
      url = "github:cloudflare/mmproxy";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, flake-utils, nixpkgs, nixos-generators, sops-nix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        makePkgs = nixpkgs:
          import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
            overlays = (import ./overlays { inherit inputs pkgs; });
          };
        pkgs = makePkgs nixpkgs;

        makeCommonConfig = { modules ? [ ], pkgs ? pkgs }: {
          inherit system;
          modules = [{ system.stateVersion = "23.11"; } ./modules sops-nix.nixosModules.sops] ++ modules;
          specialArgs = { inherit inputs pkgs system; };
        };
        makeProxmoxLxcConfig = { modules ? [ ], pkgs ? pkgs, generator ? nixpkgs.lib.nixosSystem }:
          generator (
            makeCommonConfig {
              inherit pkgs;
              modules = (modules ++ [
                { my.platforms.proxmox-lxc.enable = true; }
                nixos-generators.nixosModules.proxmox-lxc
              ]);
            }
          );
        makeProxmoxLxcTarball = { pkgs, modules ? [ ] }:
          nixos-generators.nixosGenerate ({
            format = "proxmox-lxc";
            pkgs = nixpkgs.legacyPackages.${system};
            lib = nixpkgs.legacyPackages.${system}.lib;
          } // makeCommonConfig {
            inherit pkgs;
            modules = modules;
          });

        serviceFiles = builtins.removeAttrs (builtins.readDir ./modules/services) [ "default.nix" ];
        services = builtins.map (name: pkgs.lib.removeSuffix ".nix" name) (builtins.attrNames serviceFiles);
      in
      with pkgs.lib;
      rec {
        nixosConfigurations = genAttrs
          services
          (name: makeProxmoxLxcConfig {
            inherit pkgs;
            modules = [{ config.my.services.${name}.enable = true; }];
          });

        packages = rec {
          default = lxc-base;
          lxc-base = makeProxmoxLxcTarball { inherit pkgs; };
        } // genAttrs services (name: makeProxmoxLxcTarball {
          modules = [{ config.my.services.${name}.enable = true; }];
          inherit pkgs;
        });
        legacyPackages.nixosConfigurations = nixosConfigurations; # Workaround for the Terraform provider

        apps =
          let
            makeTfVarsPackage = tfVars: pkgs.runCommand "terraform-vars" { } ''
              echo '${builtins.toJSON tfVars}' | ${pkgs.jq}/bin/jq > $out
            '';
            makeGenerateTfVars = name: package:
              let tfVarsFile = "${name}.auto.tfvars.json";
              in
              {
                type = "app";
                program = toString (pkgs.writers.writeBash "package-${package.name}" ''
                  if [[ -e ${tfVarsFile} ]]; then rm -f ${tfVarsFile}; fi
                  cp ${package} ${tfVarsFile}
                '');
              };
            enableBuild = makeGenerateTfVars "nix-build" (makeTfVarsPackage { build = true; });
            disableBuild = makeGenerateTfVars "nix-build" (makeTfVarsPackage { build = false; });
            generateTerraformVars = makeGenerateTfVars "nix-lxcs" (makeTfVarsPackage { lxcs = import ./lxcs { lib = pkgs.lib; }; });
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
                (ssh-keyscan "$1" | ${pkgs.ssh-to-age}/bin/ssh-to-age) 2>/dev/null
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
            rnix-lsp
            sops
          ];
        };
      });
}
