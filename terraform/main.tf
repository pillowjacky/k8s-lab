resource "hcloud_ssh_key" "default" {
  name       = "${var.cluster_name}-key"
  public_key = file(var.ssh_public_key)
}

resource "hcloud_network" "k8s" {
  name     = "${var.cluster_name}-net"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k8s" {
  network_id = hcloud_network.k8s.id
  type       = "cloud"
  network_zone = startswith(var.location, "fsn") || startswith(var.location, "nbg") || startswith(var.location, "hel") ? "eu-central" : (
    var.location == "ash" ? "us-east" : (
      var.location == "hil" ? "us-west" : "ap-southeast"
    )
  )
  ip_range = "10.0.1.0/24"
}

resource "hcloud_firewall" "k8s" {
  name = "${var.cluster_name}-fw"

  # ssh
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_ips
  }

  # mosh
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "60000-61000"
    source_ips = var.allowed_ips
  }

  # k8s api
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = var.allowed_ips
  }

  # node-to-node internal traffic
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = ["10.0.0.0/16"]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = ["10.0.0.0/16"]
  }
}

resource "hcloud_server" "master" {
  name         = "${var.cluster_name}-master"
  image        = "ubuntu-24.04"
  server_type  = var.server_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k8s.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k8s.id
    ip         = "10.0.1.10"
  }

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    cluster_name = var.cluster_name
    hostname     = "${var.cluster_name}-master"
    k8s_version  = var.k8s_version
    node_ip      = "10.0.1.10"
  })

  depends_on = [hcloud_network_subnet.k8s]
}

resource "hcloud_server" "worker" {
  count = var.worker_count

  name         = "${var.cluster_name}-worker-${count.index + 1}"
  image        = "ubuntu-24.04"
  server_type  = var.server_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k8s.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.k8s.id
    ip         = "10.0.1.${20 + count.index}"
  }

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    cluster_name = var.cluster_name
    hostname     = "${var.cluster_name}-worker-${count.index + 1}"
    k8s_version  = var.k8s_version
    node_ip      = "10.0.1.${20 + count.index}"
  })

  depends_on = [hcloud_network_subnet.k8s]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/hosts.yml.tftpl", {
    master_name       = hcloud_server.master.name
    master_public_ip  = hcloud_server.master.ipv4_address
    master_private_ip = "10.0.1.10"

    workers = [
      for i, server in hcloud_server.worker : {
        name       = server.name
        public_ip  = server.ipv4_address
        private_ip = "10.0.1.${20 + i}"
      }
    ]
  })

  filename = "${path.module}/../ansible/inventory/hosts.yml"
}

resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/templates/ssh-config.tftpl", {
    master_name      = hcloud_server.master.name
    master_public_ip = hcloud_server.master.ipv4_address

    workers = [
      for i, server in hcloud_server.worker : {
        name       = server.name
        private_ip = "10.0.1.${20 + i}"
      }
    ]
  })

  directory_permission = "0700"
  file_permission      = "0600"
  filename             = pathexpand("~/.ssh/conf.d/${var.cluster_name}")
}
