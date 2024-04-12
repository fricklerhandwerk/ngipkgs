{
  lib,
  pkgs ? {},
  ...
} @ args: let
  baseDirectory = ./.;

  inherit
    (builtins)
    pathExists
    readDir
    trace
    ;

  inherit
    (lib.attrsets)
    mapAttrs
    concatMapAttrs
    recursiveUpdate
    ;

  names = name: type:
    if type != "directory"
    then assert name == "README.md" || name == "default.nix"; {}
    else {${name} = baseDirectory + "/${name}";};

  allProjectDirectories = concatMapAttrs names (readDir baseDirectory);

  projectDirectories = lib.filterAttrs (_: directory:
    if pathExists (directory + "/project.nix")
    then true
    else trace "No project.nix found in ${directory}, skipping." false)
  allProjectDirectories;
in
  mapAttrs (
    _: directory: let
      imported = import (directory + "/project.nix") args;
    in
      recursiveUpdate
      imported {nixos.tests = mapAttrs (_: pkgs.nixosTest) imported.nixos.tests or {};}
  )
  projectDirectories
