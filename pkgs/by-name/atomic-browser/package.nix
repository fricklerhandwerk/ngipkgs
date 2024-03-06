{ pkgs, fetchFromGitHub, mkPnpmPackage, fetchYarnDeps, fetchpatch, ... }:
let
  source = fetchFromGitHub {
    owner = "ngi-nix";
    repo = "atomic-server";
    rev = "v0.37.0";
    hash = "sha256-+Lk2MvkTj+B+G6cNbWAbPrN5ECiyMJ4HSiiLzBLd74g=";
  };
in
mkPnpmPackage rec {
  name = "atomic-browser";
  version = "v0.37.0";
  src = "${source}/browser";

  installInPlace = true;

  distDir = "."; # Copy everything to the output

  extraBuildInputs = [pkgs.typescript];
}
