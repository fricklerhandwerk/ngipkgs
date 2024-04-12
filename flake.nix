{
  description = "NGIpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # Set default system to `x86_64-linux`,
  # as we currently only support Linux.
  # See <https://github.com/ngi-nix/ngipkgs/issues/24> for plans to support Darwin.
  inputs.systems.url = "github:nix-systems/x86_64-linux";
  inputs.flake-utils.inputs.systems.follows = "systems";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  inputs.rust-overlay.inputs.flake-utils.follows = "flake-utils";
  inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  inputs.dream2nix.url = "github:nix-community/dream2nix";
  inputs.dream2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    sops-nix,
    rust-overlay,
    dream2nix,
    ...
  } @ inputs: let
    inherit
      (builtins)
      mapAttrs
      attrValues
      isAttrs
      concatStringsSep
      ;

    inherit
      (nixpkgs.lib)
      concatMapAttrs
      mapAttrs'
      foldr
      recursiveUpdate
      nameValuePair
      nixosSystem
      filterAttrs
      attrByPath
      foldlAttrs
      ;

    flattenAttrs = {
      prefix ? [],
      sep ? ".",
    }: x: let
      f = path:
        foldlAttrs (acc: name: value:
          (
            if isAttrs value
            then (f "${path}${name}${sep}" value)
            else {"${path}${name}" = value;}
          )
          // acc) {};
    in
      f (
        if prefix == []
        then ""
        else (concatStringsSep sep prefix) + sep
      )
      x;

    importProjects = {
      pkgs ? {},
      lib ? inputs.nixpkgs.lib,
      sources ? {},
    }:
      import ./projects {inherit lib pkgs sources;};

    mapAttrByPath = attrPath: default: mapAttrs (_: attrByPath attrPath default);

    pickNixosModules = mapAttrByPath ["nixos" "modules"] {};

    pickPackages = mapAttrByPath ["packages"] {};

    pickNixosTests = mapAttrByPath ["nixos" "tests"] {};

    pickNixosConfigurations = x: mapAttrs (_: v: mapAttrs (_: v: v.path) v) (mapAttrByPath ["nixos" "configurations"] {} x);

    importPackages = pkgs: let
      nixosTests = pickNixosTests (importProjects {
        inherit pkgs;
        lib = inputs.nixpkgs.lib;
        sources.configurations = rawNixosConfigs;
        sources.modules = extendedModules;
      });

      callPackage = pkgs.newScope (
        allPackages // {inherit callPackage nixosTests;}
      );

      pkgsByName = import ./pkgs/by-name {
        inherit (pkgs) lib;
        inherit callPackage dream2nix pkgs;
      };

      explicitPkgs = import ./pkgs {
        inherit (pkgs) lib;
        inherit callPackage;
      };

      allPackages = pkgsByName // explicitPkgs;
    in
      allPackages;

    importNixpkgs = system: overlays:
      import nixpkgs {inherit system overlays;};

    rawNixosConfigs = flattenAttrs {sep = "/";} (pickNixosConfigurations (importProjects {}));

    loadTreefmt = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

    # Overlays a package set (e.g. nixpkgs) with the packages defined in this flake.
    overlay = final: prev: importPackages prev;

    # Attribute set containing all modules obtained via `inputs` and defined
    # in this flake towards definition of `nixosConfigurations` and `nixosTests`.
    extendedModules =
      self.nixosModules
      // {
        sops-nix = sops-nix.nixosModules.default;
      };

    nixosConfigurations =
      mapAttrs
      (_: config: nixosSystem {modules = [config ./dummy.nix] ++ attrValues extendedModules;})
      rawNixosConfigs;

    eachDefaultSystemOutputs = flake-utils.lib.eachDefaultSystem (system: let
      pkgs = importNixpkgs system [rust-overlay.overlays.default];
      treefmtEval = loadTreefmt pkgs;
      toplevel = name: config: nameValuePair "nixosConfigurations/${name}" config.config.system.build.toplevel;

      importPack = importPackages pkgs;

      dummy = import (nixpkgs + "/nixos/lib/eval-config.nix") {
        inherit system;
        modules =
          builtins.attrValues self.nixosModules
          ++ [
            {
              networking = {
                domain = "invalid";
                hostName = "options";
              };
            }
          ];
      };
      options = builtins.mapAttrs (name: _: dummy.options.services.${name} or {}) self.nixosModules;
      optionsDoc = pkgs.nixosOptionsDoc {inherit options;};
    in {
      packages =
        importPack
        // {
          overview =
            pkgs.runCommand "overview" {
              nativeBuildInputs = with pkgs; [jq pandoc validator-nu];
              build = pkgs.writeTextFile {
                name = "overview.html";
                text = import ./overview.nix {
                  inherit self;
                  inherit (pkgs) lib;
                  ngipkgs = importPack;
                  options = optionsDoc.optionsNix;
                };
              };
            } ''
              mkdir $out
              echo "<!DOCTYPE html>" > $out/index.html
              pandoc --from=markdown+raw_html --to=html < $build >> $out/index.html
              vnu --Werror --format json $out 2>&1 | jq
            '';

          options =
            pkgs.runCommand "options.json" {
              build = optionsDoc.optionsJSON;
            } ''
              mkdir $out
              cp $build/share/doc/nixos/options.json $out/
            '';
        };

      formatter = treefmtEval.config.build.wrapper;
      checks = mapAttrs' toplevel nixosConfigurations;
    });

    x86_64-linuxOutputs = let
      system = flake-utils.lib.system.x86_64-linux;
      pkgs = importNixpkgs system [self.overlays.default];
      treefmtEval = loadTreefmt pkgs;
      # Dream2nix is failing to pass through the meta attribute set.
      # As a workaround, consider packages with empty meta as non-broken.
      nonBrokenPkgs = filterAttrs (_: v: !(attrByPath ["meta" "broken"] false v)) self.packages.${system};
    in {
      # Github Actions executes `nix flake check` therefore this output
      # should only contain derivations that can built within CI.
      # See `.github/workflows/ci.yaml`.
      checks.${system} =
        # For `nix flake check` to *build* all packages, because by default
        # `nix flake check` only evaluates packages and does not build them.
        (mapAttrs' (name: check: nameValuePair "packages/${name}" check) nonBrokenPkgs)
        // {
          formatting = treefmtEval.config.build.check self;
        };

      # To generate a Hydra jobset for CI builds of all packages and tests.
      # See <https://hydra.ngi0.nixos.org/jobset/ngipkgs/main>.
      hydraJobs = let
        passthruTests = concatMapAttrs (name: value:
          if value ? passthru.tests
          then {${name} = value.passthru.tests;}
          else {})
        nonBrokenPkgs;
      in {
        packages.${system} = nonBrokenPkgs;
        tests.${system} = passthruTests;

        nixosConfigurations.${system} =
          mapAttrs
          (name: config: config.config.system.build.toplevel)
          nixosConfigurations;
      };
    };

    systemAgnosticOutputs = {
      inherit nixosConfigurations;

      nixosModules =
        (import ./modules/all-modules.nix)
        // (
          flattenAttrs {sep = "/";} (pickNixosModules (importProjects {
            sources = {
              inherit inputs;
              inherit self;
              modules = extendedModules;
              configurations = rawNixosConfigs;
            };
          }))
        )
        // {
          # The default module adds the default overlay on top of nixpkgs.
          # This is so that `ngipkgs` can be used alongside `nixpkgs` in a configuration.
          default.nixpkgs.overlays = [self.overlays.default];
        };

      overlays.default = overlay;
    };
  in
    foldr recursiveUpdate {} [
      eachDefaultSystemOutputs
      x86_64-linuxOutputs
      systemAgnosticOutputs
    ];
}
