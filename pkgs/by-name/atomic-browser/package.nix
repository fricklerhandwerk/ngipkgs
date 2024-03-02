{ pkgs, fetchFromGitHub, mkPnpmPackage, fetchYarnDeps, fetchpatch, ... }:
let
  source = fetchFromGitHub {
    owner = "atomicdata-dev";
    repo = "atomic-server";
    rev = "v0.37.0";
    hash = "sha256-+Lk2MvkTj+B+G6cNbWAbPrN5ECiyMJ4HSiiLzBLd74g=";
  };
in
mkPnpmPackage rec {
  name = "atomic-browser";
  version = "v0.37.0";
  src = "${source}/browser";

  installPhase = "";
  distPhase = "";

   packageJSON = "${source}/browser/package.json";
   # Upstream does not contain a yarn.lock
   yarnLock = ./yarn.lock;
   offlineCache = fetchYarnDeps {
     yarnLock = ./yarn.lock;
     hash = "sha256-GK5Ehk82VQ5ajuBTQlPwTB0aaxhjAoD2Uis8wiam7Z0=";
   };
}
