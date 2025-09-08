{
  description = "Luanti game engine flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    compileCommandsFor = {
      url = "github:coldelectrons/compileCommandsFor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , compileCommandsFor
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      package = import ./default.nix { inherit system pkgs; };
      inherit (compileCommandsFor.lib.${system}) compileCommands;
    in
    {
      packages.default = package;
      packages.compileCommands = compileCommands package;
      devShells.default = package.shell;
      formatter = pkgs.alejandra;
    }
    );
}
