{
  description = "Luanti game engine flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    miniCompileCommands = {
      url = "github:danielbarter/mini_compile_commands/v0.6";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , nixpkgs-unstable
    , miniCompileCommands
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      package = import ./default.nix { inherit system pkgs; };
    in
    {
      packages.default = package;
      devShells.default = package.shell;
      formatter = pkgs.alejandra;
    }
    );
}
