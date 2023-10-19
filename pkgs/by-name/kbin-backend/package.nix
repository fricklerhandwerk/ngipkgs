{
  lib,
  fetchgit,
  php,
  moreutils,
  yq,
  withS3 ? false,
}: let
  phpWithExtensions = php.withExtensions ({
    enabled,
    all,
  }:
    enabled ++ (with all; [amqp redis]));
in
  phpWithExtensions.buildComposerProject (finalAttrs: let
    pname = "kbin";
    version = "0.0.1";
  in {
    inherit pname version;

    src = fetchgit {
      url = "https://codeberg.org/Kbin/kbin-core/";
      rev = "cc727b9133b60fe7411b8c4dbd90c0319d225916";
      hash = "sha256-3y9Q+s2ImCFrsET76VXB9uzQ24F3SKfOk+fDINRZjWc=";

      postFetch = ''
        # Work around <https://github.com/NixOS/nixpkgs/pull/257337>.
        substituteInPlace $out/yarn.lock \
          --replace '@symfony/stimulus-bundle' '_symfony/stimulus-bundle' \
          --replace '@symfony/ux-autocomplete' '_symfony/ux-autocomplete' \
          --replace '@symfony/ux-chartjs'      '_symfony/ux-chartjs'
      '';
    };

    nativeBuildInputs = [
      yq
      moreutils
    ];

    postPatch =
      ''
        # .env file must be used, because it is used to set the default values
        cp .env.example .env

        yq '.oneup_flysystem.adapters.default_adapter.local.location = "/var/lib/kbin/media"' \
          < config/packages/oneup_flysystem.yaml \
          | sponge config/packages/oneup_flysystem.yaml
      ''
      + (lib.optionalString withS3 ''
        yq '(
          .oneup_flysystem.filesystems.public_uploads_filesystem.adapter = "kbin.s3_adapter" |
          .oneup_flysystem.adapters.kbin.s3_adapter.awss3v3 = {client: "kbin.s3_client", bucket: "%amazon.s3.bucket%"}
        )' \
          < config/packages/oneup_flysystem.yaml \
          | sponge config/packages/oneup_flysystem.yaml
      '');

    vendorHash = "sha256-lv13ze8PlJyOMDIrXrPzvQr4AgDpYx8Ns9+lUEFUEJ4=";

    composerNoPlugins = false;
    composerStrictValidation = false;
    doInstallCheck = false;

    installCheckPhase = ''
      runHook preInstallCheck

      export DATABASE_URL="sqlite:///test.db"
      php bin/console doctrine:database:create
      php bin/console doctrine:migrations:migrate
      SYMFONY_DEPRECATIONS_HELPER=disabled php bin/phpunit --testdox tests/Functional

      runHook postInstallCheck
    '';

    passthru = {
      inherit withS3;
      php = phpWithExtensions;
    };
  })
