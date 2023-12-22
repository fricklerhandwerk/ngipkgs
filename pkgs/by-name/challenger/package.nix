{
  lib,
  stdenv,
  fetchgit,
  autoreconfHook,
  gnunet,
  jansson,
  libgcrypt,
  libgnurl,
  curlWithGnuTls,
  libmicrohttpd,
  pkg-config,
  postgresql,
  taler-exchange,
  taler-merchant,
  libsodium,
}: let
  version = "0.9.3";
in
  stdenv.mkDerivation rec {
    name = "challenger";
    inherit version;

    src = fetchgit {
      url = "https://git.taler.net/challenger.git";
      rev = "v${version}";
      hash = "sha256-nEEQbU/WogRhciIaIROSxFXtq0q99AifV3XOPQdZZTw=";
    };

    # Taken from ./bootstrap
    autoreconfPhase = ''
      cd contrib
      rm -f Makefile.am
      find wallet-core/challenger/ -type f -printf '  %p \\\n' | sort > Makefile.am.ext
      # Remove extra '\' at the end of the file
      truncate -s -2 Makefile.am.ext
      cat Makefile.am.in Makefile.am.ext >> Makefile.am
      # Prevent accidental editing of the generated Makefile.am
      chmod -w Makefile.am
      cd ..


      echo "$0: Running autoreconf"
      autoreconf -if

    '';

    nativeBuildInputs = [
      pkg-config
      autoreconfHook
    ];

    buildInputs = [
      taler-exchange
      taler-merchant
      gnunet

      libmicrohttpd
      postgresql

      libgcrypt
      jansson
      libgnurl
      curlWithGnuTls
      libsodium
    ];

    meta = {
      homepage = "https://git.taler.net/challenger.git";
      description = "OAuth 2.0-based authentication service that validates user can receive messages at a certain address.";
      license = lib.licenses.agpl3Plus;
    };
  }
