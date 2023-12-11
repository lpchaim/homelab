pm_host             = "10.10.0.1"
pm_node_name        = "pve01"
pm_tls_insecure     = true
pm_template_vm_name = "ubuntu-cloudinit-mantic-k3s"

private_key = "~/.ssh/id_rsa"

k3s_server_count = 1
k3s_server_mem   = 2048
k3s_server_ips = [
  "10.2.1.0",
  "10.2.1.1",
  "10.2.1.2",
]

k3s_agent_count = 1
k3s_agent_mem   = 4096
k3s_agent_ips = [
  "10.2.2.0",
  "10.2.2.1",
]

network_gateway = "10.0.0.1"
network_subnet  = "8"
