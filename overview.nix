self: lib: packages: options: let
  startsWith = a: b: builtins.substring 0 (builtins.stringLength a) b == a;
  concatDot = builtins.concatStringsSep ".";
  thisOption = actual: expected: startsWith expected actual;
  anyOption = options: actual: builtins.any (thisOption actual) (map concatDot options);

  header = "<html><head><title>${self.rev or self.dirtyRev}</title></head><body>";
  footer = "</body></html>";

  ngiDetails = ngi: "<p><b>NLNet Project:</b> <a href=\"https://nlnet.nl/project/${ngi.project}\">${ngi.project}</a></p>";

  myoption = name: value: "<dt><code>${name}</code></dt><dd><table><tr><td>Type</td><td>${value.type}</td></tr><tr><td>Description</td><td>${value.description}</td></tr></table></dd>";
in
  header
  + "<h1>Packages</h1>"
  + builtins.concatStringsSep "" (
    builtins.attrValues
    (builtins.mapAttrs (
        name: x:
          "<section><h2>Package: <code>${name}</code></h2>"
          + (
            if x ? meta.ngi
            then ngiDetails x.meta.ngi
            else ""
          )
          + (
            "<h3>Options</h3><dl>"
            + (
              builtins.concatStringsSep "" (
                builtins.attrValues (
                  builtins.mapAttrs myoption (
                    lib.filterAttrs (n: v: anyOption (x.meta.ngi.options or []) n)
                    options
                  )
                )
              )
              + "</dl>"
            )
          )
          + "</section>"
      )
      packages)
  )
  + footer
