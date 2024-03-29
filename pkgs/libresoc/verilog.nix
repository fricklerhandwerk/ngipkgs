{
  runCommand,
  python3,
  python3Packages,
  pinmux,
}: let
  script = ''
    mkdir pinmux
    ln -s ${pinmux} pinmux/ls180
    export PINMUX="$(realpath ./pinmux)"
    python3 -m soc.simple.issuer_verilog \
      --debug=jtag --enable-core --enable-pll \
      --enable-xics --enable-sram4x4kblock --disable-svp64 \
      $out
  '';
in
  runCommand "libresoc.v" {
    nativeBuildInputs =
      (with python3Packages; [
        libresoc-soc
      ])
      ++ [pinmux];
  }
  script
