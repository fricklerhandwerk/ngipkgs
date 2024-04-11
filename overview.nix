{
  self,
  lib,
  ngipkgs,
  options,
  ...
}: let
  title = "NGIpkgs Overview";
  ngipkgsValues = builtins.attrValues ngipkgs;

  empty = xs: assert builtins.isList xs; xs == [];
  heading = i: text: "${lib.strings.replicate i "#"} ${text}";
  isPrefixOf = prefix: candidate: prefix == lib.lists.commonPrefix prefix candidate;

  anyOption = options: actual: builtins.any ((lib.trivial.flip isPrefixOf) actual) options;

  version = if self ? rev then "[`${builtins.substring 0 7 self.rev}`](https://github.com/ngi-nix/ngipkgs/tree/${self.rev})" else self.dirtyRev;

  projects = lib.lists.unique (
    map (x: x.meta.ngi.project) (builtins.filter (x: x ? meta.ngi) ngipkgsValues)
  );

  packagesByProject = project: builtins.filter (x: x.meta.ngi.project or null == project) ngipkgsValues;

  packagesWithoutProject = packagesByProject null;

  # Options

  optionSpecByProject = project:
    lib.lists.unique (
      builtins.concatMap (x: x.meta.ngi.options) (builtins.filter (x: x ? meta.ngi.options) ngipkgsValues)
    );

  optionsByProject = project:
    builtins.filter
    (option: anyOption (optionSpecByProject project) option.loc)
    (builtins.attrValues options);

  renderOptions = projectOptions:
    lib.strings.optionalString (!empty projectOptions)
    "<dl>${lib.strings.concatLines (map renderOption projectOptions)}</dl>";

  renderOption = value: let
    dottedName = builtins.concatStringsSep "." value.loc;
    maybeDefault = lib.strings.optionalString (value ? default.text) "`${value.default.text}`";
  in ''
    <dt>`${dottedName}`</dt>
    <dd>
      <table>
        <tr>
          <td>Description:</td>
          <td>${value.description}</td>
        </tr>
        <tr>
          <td>Type:</td>
          <td>`${value.type}`</td>
        </tr>
        <tr>
          <td>Default:</td>
          <td>${maybeDefault}</td>
        </tr>
      </table>
    </dd>
  '';

  # Packages

  renderPackage = package: ''
    <dt>`${package.name}`</dt>
    <dd>
      <table>
        <tr>
          <td>Version:</td>
          <td>${package.version}</td>
        </tr>
      </table>
    </dd>
  '';

  renderPackages = packages:
    lib.strings.optionalString (!empty packages)
    "<dl>${lib.strings.concatLines (map renderPackage packages)}</dl>";

  renderProject = project: let
    projectPackages = packagesByProject project;
    maybePackagesHeader = lib.strings.optionalString (!empty projectPackages) (heading 3 "Packages");
    renderedPackages = renderPackages projectPackages;
    projectOptions = optionsByProject project;
    maybeOptionsHeader = lib.strings.optionalString (!empty projectOptions) (heading 3 "Options");
    renderedOptions = renderOptions projectOptions;
  in ''
    ${heading 2 project}
    <https://nlnet.nl/project/${project}>

    ${maybePackagesHeader}
    ${renderedPackages}
    ${maybeOptionsHeader}
    ${renderedOptions}
  '';
in ''
  <html lang="en">
  <head>
  <title>${title}</title>
  </head>
  <body>

  ${heading 1 title}

  ${lib.strings.concatLines (map renderProject projects)}

  ${heading 2 "Packages without Project Metadata"}

  ${renderPackages packagesWithoutProject}

  <hr>
  <footer>Version: ${version}</footer>
  </body>
  </html>
''
