{pkgs, ...}: {
  packages =
    if pkgs == {}
    then builtins.throw "wut?"
    else {inherit (pkgs) flarum;};
  nixos.module.service = ./service.nix;
}
