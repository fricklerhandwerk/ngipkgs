{
  stdenv,
  fetchgit,
  python3,
}:
stdenv.mkDerivation {
  name = "libresoc-pinmux";

  src = fetchgit {
    url = "https://git.libre-soc.org/git/pinmux.git";
    hash = "sha256-Tux2RvcRmlpXMsHwve/+5rOyBRSThg9MVW2NGP3ZJxs=";
  };

  nativeBuildInputs = [python3];

  configurePhase = "true";

  buildPhase = ''
    runHook preBuild
    python src/pinmux_generator.py -v -s ls180 -o ls180
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv ls180 $out
    runHook postInstall
  '';

  fixupPhase = "true";
}
