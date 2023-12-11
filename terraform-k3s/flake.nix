{
  inputs = {
    unstable.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let unstablePkgs = import unstable { inherit system; config.allowUnfree = true; };
      in {
        devShells.default =
          unstablePkgs.mkShell {
            buildInputs = with unstablePkgs; [
              (terraform.withPlugins (b: with b; [
                local
                proxmox
              ]))
            ];
          };
      }
    );
}
