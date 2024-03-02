{ pkgs, fetchFromGitHub, mkPnpmPackage, fetchYarnDeps, fetchpatch, ... }:
let
  source = fetchFromGitHub {
    owner = "atomicdata-dev";
    repo = "atomic-server";
  };
in
mkPnpmPackage rec {
  name = "atomic-web";
  version = "v0.34.5";
  src = "${source}/browser";

  patches = [
    ./workspaces.patch
  ];

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
