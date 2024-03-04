{ pkgs, fetchFromGitHub, mkPnpmPackage, fetchYarnDeps, fetchpatch, ... }:
let
  source = fetchFromGitHub {
    owner = "ngi-nix";
    repo = "atomic-server";
    rev = "fix-ts-5.3.2";
    hash = "sha256-gcw7Py1GhDZt+lvcehDULij5mOCcZ1wZDlyWLZu693E=";
  };
in
mkPnpmPackage rec {
  name = "atomic-browser";
  version = "v0.37.0";
  src = "${source}/browser";

  extraBuildInputs = [pkgs.typescript];
}
