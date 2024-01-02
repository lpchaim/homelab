[
  {
    name = "caddy";
    enable = false;
    vmid = "241";
    ip = "10.10.2.41";
    tags = [ "networking" ];
    cores = 2;
    memory = 256;
  }
  {
    name = "jellyfin";
    enable = true;
    privileged = true;
    vmid = "810";
    ip = "10.10.8.10";
    tags = [ "media" ];
    memory = 4096;
    cores = 6;
    extra_config = [
      "lxc.cgroup2.devices.allow: c 226:0 rwm"
      "lxc.cgroup2.devices.allow: c 226:128 rwm"
      "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file,mode=0666"
      "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file"
    ];
    mountpoints = [
      { mp = "/data"; storage = "/srv/storage"; }
      { mp = "/config"; storage = "/srv/storage/AppData/config/jellyfin"; }
      { mp = "/var/lib/jellyfin/data"; storage = "/srv/storage/AppData/config/jellyfin/data/data"; }
      { mp = "/var/lib/jellyfin/metadata"; storage = "/srv/storage/AppData/config/jellyfin/data/metadata"; }
      { mp = "/var/lib/jellyfin/plugins"; storage = "/srv/storage/AppData/config/jellyfin/data/plugins"; }
      { mp = "/var/lib/jellyfin/root"; storage = "/srv/storage/AppData/config/jellyfin/data/root"; }
      { mp = "/var/cache/jellyfin"; storage = "/srv/storage/AppData/config/jellyfin/cache"; }
    ];
  }
]
