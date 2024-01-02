{
  systemd.network.networks.eth0 = {
    matchConfig.Name = "eth0";
    linkConfig.RequiredForOnline = "routable"; # Workaround for the LXC sometimes not detecting a valid internet connection even though it's clearly up
    networkConfig.Description = "Default connection";
  };

  proxmoxLXC = {
    manageNetwork = false;
    manageHostName = false;
  };
}
