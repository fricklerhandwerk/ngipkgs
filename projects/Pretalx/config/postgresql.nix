{config, ...}: {
  services = {
    pretalx.database = {
      backend = "postgresql";
      user = "pretalx";
    };

    postgresql = {
      enable = true;
      authentication = "local all all trust";
      ensureUsers = [
        {
          name = config.services.pretalx.database.user;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [config.services.pretalx.database.name];
    };
  };
}
