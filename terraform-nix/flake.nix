{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
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
        makeNixosConfig = modules:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              nixos-generators.nixosModules.proxmox-lxc
              ./modules/proxmox-lxc-base.nix
            ] ++ modules;
          };
        makeProxmoxLxc = modules:
          nixos-generators.nixosGenerate {
            inherit system modules;
            format = "proxmox-lxc";
            pkgs = nixpkgs.legacyPackages.${system};
            lib = nixpkgs.legacyPackages.${system}.lib;
            specialArgs = { inherit inputs pkgs system; };
          };
      in {
        legacyPackages.nixosConfigurations =
          let
            servicesPath = ./services;
            services = builtins.readDir servicesPath;
          in
          pkgs.lib.mapAttrs'
            (file: _: pkgs.lib.nameValuePair
              (pkgs.lib.removeSuffix ".nix" file)
              (makeNixosConfig [ "${servicesPath}/${file}" ]))
            services;
        packages = rec {
          default = base-proxmox-lxc;
          base-proxmox-lxc = makeProxmoxLxc [];
        };
        devShells.default =
          with pkgsUnstable;
          mkShell {
            buildInputs = [
              (terraform.withPlugins (b: with b; [
                external
                local
                b.null
                proxmox
              ]))
            ];
          };
      }
    );
}
