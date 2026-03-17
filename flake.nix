{
  description = "Rust cross-compilation environment for RustPotato";

  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Set the build target
        rustTarget = "x86_64-pc-windows-gnu";

        # Use nightly-2025-02-14 as build toolchain
        rustToolchain = pkgs.rust-bin.nightly."2025-02-14".default.override {
          extensions = ["rust-src"];
          targets = [rustTarget];
        };

        # Define variables to use mingwW64 stdenv within buildInputs
        mingwPkgs = pkgs.pkgsCross.mingwW64;
        mingwCc = mingwPkgs.stdenv.cc;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rustToolchain

            # Use the Windows cross-compiler and pthreads
            mingwCc
            mingwPkgs.windows.pthreads
          ];

          # Set the default build target to the rustTarget so we don't need --target
          CARGO_BUILD_TARGET = rustTarget;
        };
      }
    );
}
