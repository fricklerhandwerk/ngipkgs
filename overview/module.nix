{ lib, ... }:
let
  inherit (lib) mkOption types;
  project =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        __toString = mkOption {
          type = with types; functionTo str;
          default =
            self: with lib; ''
              <article>
              <h1>${self.name}</h1>

              <!-- todo -->
              </article>
            '';

        };
      };
    };
in
{
  options.overview = mkOption {
    type = types.submodule (
      { config, ... }:
      {
        # TODO: this could do
        # import = [ ./document.nix ] as in
        # https://github.com/fricklerhandwerk/htmnix/blob/main/structure/default.nix
        # so it will also have an outpath (but simpler, without different output types)
        options = {
          projects = mkOption {
            type = with types; attrsOf (submodule project);
            default = { };
          };
        };
      }
    );
    default = { };
  };
  options.__toString = mkOption {
    type = with types; functionTo str;
    default =
      self: with lib; ''
        <article>
          <h1>Project overview<h1>

          ${concatMapAttrsStringSep "\n" (name: project: toString project) self.overview.projects}
        </article>
      '';
  };
}
