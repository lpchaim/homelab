 # Homelab

Declarative home server deployment and management powered by [Terraform], [Ansible] and [Nix].

## About

This is a collection of tools to manage my personal home server/NAS setup, still very much a WIP. Right now, all it really does is setup some services and configurations through Ansible. On the Nix side, it also generates proxmox-ready images! `nix build` outputs a basic, ready to use Proxmox LXC template. The outputs also build specific LXC images Terraform is able to deploy, only `caddy` has been implemented so far.

I've been working on this in private for a while, and didn't originally intend to make it public. I've since changed my mind but that does mean it's a bit rough, not very cohesive, with stray commented blocks here and there and whatnot. That said, I'm always working on it one way or another and it's only going to improve from here!

## General layout

### Storage

A variety of disks powered by MergerFS + Snapraid. Services access said storage through a mixture of NFS and LXC mount points.

Backups of critical data are performed daily to a Hetzner storage box. No local backup yet.

### Services

Everything runs on a single Proxmox host as of now. It's a pretty standard build with and Intel CPU for QSV encoding.

The following are all LXC containers:

- Caddy - Reverse proxy, also keeps DNS records updated
- Docker - Runs smaller, non critical workloads. Auto updates through Watchtower.
- Jellyfin Media server
- Nextcloud
- Tailscale

## Planned enhancements
- [ ] Experiment with migrating all docker workloads, plus possibly Jellyfin and Nextcloud, to a simple kubernetes cluster for more robust declarativeness.
- [ ] Make Proxmox infrastructure declarative. Although some configuration has been automated, all of the LXCs are created manually right now.

[ansible]: https://www.ansible.com/
[hmrepo]: https://github.com/lpchaim/home-manager
[home manager]: https://nix-community.github.io/home-manager/
[nerd fonts]: https://www.nerdfonts.com/
[nix]: https://nixos.org/
[proxmox]: https://www.proxmox.com/
[terraform]: https://www.terraform.io/
