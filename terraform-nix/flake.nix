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
        commonModules = [ { system.stateVersion = "23.11"; } ];
        makeProxmoxLxcConfig = modules:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = commonModules ++ modules ++ [
              ./modules/proxmox-lxc-base.nix
              nixos-generators.nixosModules.proxmox-lxc
            ];
            specialArgs = { inherit inputs pkgs system; };
          };
        makeProxmoxLxcTarball = modules:
          nixos-generators.nixosGenerate {
            inherit system;
            modules = commonModules ++ modules;
            format = "proxmox-lxc";
            pkgs = nixpkgs.legacyPackages.${system};
            lib = nixpkgs.legacyPackages.${system}.lib;
            specialArgs = { inherit inputs pkgs system; };
          };
        servicesPath = ./services;
        services = builtins.readDir servicesPath;
        makeAttrsetFromServices = action:
          pkgs.lib.mapAttrs'
            (file: _: pkgs.lib.nameValuePair (pkgs.lib.removeSuffix ".nix" file) (action "${servicesPath}/${file}"))
            services;
      in {
        legacyPackages.nixosConfigurations = makeAttrsetFromServices (path: makeProxmoxLxcConfig [ path ]);
        packages = rec {
          default = base-proxmox-lxc;
          base-proxmox-lxc = makeProxmoxLxcTarball [];
        } // makeAttrsetFromServices (path: makeProxmoxLxcTarball [ path ]);
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
            ];
          };
      }
    );
}
