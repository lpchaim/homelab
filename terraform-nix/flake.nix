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
        commonPkgConfig = {
          inherit system;
          config.allowUnfree = true;
        };
        pkgsUnstable = import nixpkgs-unstable commonPkgConfig;
        pkgs = import nixpkgs-unstable commonPkgConfig;
        makeProxmoxLxc = modules:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              nixos-generators.nixosModules.proxmox-lxc
              ./modules/base.nix
            ] ++ modules;
          };
      in {
        packages = rec {
          default = base-proxmox-lxc;
          base-proxmox-lxc = nixos-generators.nixosGenerate {
            inherit system;
            modules = [ ./modules/base.nix ];
            format = "proxmox-lxc";
            pkgs = nixpkgs.${system};
            lib = nixpkgs.legacyPackages.${system}.lib;
          };
          nixosConfigurations = rec {
            default = caddy;
            caddy = makeProxmoxLxc [ ./modules/caddy.nix ];
          };
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
