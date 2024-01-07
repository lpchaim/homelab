rec {
  main = "/srv/storage";
  appData = "${main}/AppData";
  getConfigPath = name: "${appData}/config/${name}";
  getDataPath = name: "${appData}/data/${name}";
}
