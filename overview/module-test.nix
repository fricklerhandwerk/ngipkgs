{ lib, ... }:
let
  # TODO: this should be in a check that produces something, so at least it evals/builds once
  eval = lib.evalModules {
    modules = [
      ./module.nix
      # TODO: read from `//projects`
      {
        overview.projects = {
          example1 = { };
          example2 = { };
        };
      }
    ];
  };

in
eval.config
