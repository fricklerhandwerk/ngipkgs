{ version }:

{ stdenv, python3Packages, runCommand, python2, yosys }:

let
  # If we use ../. as source, then any change to
  # any unrelated Nix file would cause a rebuild,
  # since the build would have access to it.
  src = runCommand "libresoc-verilog-source" {} ''
    mkdir $out
    cp -r ${../src} -T $out/src
    cp -r ${../mkpinmux.sh} -T $out/mkpinmux.sh
    cp -r ${../pinmux} -T $out/pinmux
    cp -r ${../Makefile} -T $out/Makefile
  '';
in
stdenv.mkDerivation {
  pname = "libresoc.v";
  inherit version;

  inherit src;

  strictDeps = true;

  nativeBuildInputs = (with python3Packages; [
    c4m-jtag nmigen-soc python libresoc-ieee754fpu libresoc-openpower-isa
  ]) ++ [ yosys ];

  configurePhase = "true";

  buildPhase = ''
    runHook preBuild
    env -C pinmux ${python2}/bin/python src/pinmux_generator.py -v -s ls180 -o ls180
    cp pinmux/ls180/ls180_pins.py src/soc/debug
    cp pinmux/ls180/ls180_pins.py src/soc/litex/florent/libresoc
    cd src
    export PYTHONPATH="$PWD:$PYTHONPATH"
    python3 soc/simple/issuer_verilog.py \
      --debug=jtag --enable-core --enable-pll \
      --enable-xics --enable-sram4x4kblock --disable-svp64 \
      libresoc.v
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv libresoc.v $out
    runHook postInstall
  '';

  fixupPhase = "true";
}
