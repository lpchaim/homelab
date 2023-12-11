{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-23.05";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ansible-language-server
            nixpkgs-fmt
            pre-commit
            (python311.withPackages (ps: with ps; [
              ansible-core
              jmespath
              proxmoxer
            ]))
          ];
          shellHook = ''
            export LANG=C.UTF-8;
            export PYTHONPATH="$(which python)"
            pre-commit install
          '';
        };
      }
    );
}
