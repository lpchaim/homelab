{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";

    # Misc
    flake-utils.url = "github:numtide/flake-utils";
    mmproxy = { url = "github:cloudflare/mmproxy"; flake = false; };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Docker inputs
    catppuccin-theme-park = { url = "github:catppuccin/theme.park"; flake = false; };
  };

  outputs = { self, flake-utils, nixpkgs, nixos-generators, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        makePkgs = nixpkgs:
          import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
            overlays = import ./overlays { inherit inputs pkgs; };
          };
        pkgs = makePkgs nixpkgs;

        makeCommonConfig = { modules ? [ ], pkgs ? pkgs }: {
          inherit system;
          modules = [
            { system.stateVersion = "23.11"; }
            inputs.sops-nix.nixosModules.sops
            ./modules
          ] ++ modules;
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
            inherit (pkgs) lib;
          } // makeCommonConfig {
            inherit pkgs;
            modules = modules;
          });

        lxcs = import ./lxcs { inherit (pkgs) lib; };
      in
      with pkgs.lib;
      rec {
        nixosConfigurations = mapAttrs
          (_: lxc: makeProxmoxLxcConfig {
            inherit pkgs;
            modules = lxc.nix.modules or [ ];
          })
          lxcs.byName;

        packages = rec {
          default = lxc-base;
          lxc-base = makeProxmoxLxcTarball { inherit pkgs; };
        }
        // mapAttrs'
          (name: lxc: nameValuePair
            "lxc-${name}"
            (makeProxmoxLxcTarball {
              inherit pkgs;
              modules = lxc.nix.modules or [ ];
            })
          )
          lxcs.byName
        // mapAttrs'
          (vmid: lxc: nameValuePair
            "lxc-${vmid}"
            (makeProxmoxLxcTarball {
              inherit pkgs;
              modules = lxc.nix.modules or [ ];
            })
          )
          lxcs.byId;
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
            generateTerraformVars = makeGenerateTfVars "nix-lxcs" (makeTfVarsPackage { lxcs = lxcs.byId; });
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
            buildOsConfig = {
              type = "app";
              program = toString (pkgs.writers.writeBash "buildosconfig" ''
                nix build ".#nixosConfigurations.${system}.$1.config.system.build.toplevel" --show-trace
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
            nil
            nixd
            nixpkgs-fmt
            rnix-lsp
            sops
          ];
        };
      });
}
