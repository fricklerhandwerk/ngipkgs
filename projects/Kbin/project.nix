{
  pkgs,
  lib,
  ...
} @ args: {
  packages = {inherit (pkgs) kbin kbin-frontend kbin-backend;};
  nixos = rec {
    modules.service = ./service.nix;
    configurations = {
      base = {
        path = ./configuration.nix;
        description = "Basic configuration, mainly used for testing purposes.";
      };
    };
    tests.kbin = import ./test.nix (lib.recursiveUpdate args {
      sources.configurations.kbin = configurations.base.path;
    });
  };
}
