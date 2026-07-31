output "master_public_ipv4" {
  value = hcloud_server.master.ipv4_address
}

output "master_public_ipv6" {
  value = hcloud_server.master.ipv6_address
}

output "private_ips" {
  value = {
    master  = "10.0.1.10"
    workers = ["10.0.1.20", "10.0.1.21"]
  }
}

output "ssh_commands" {
  value = {
    # Direct to master (IPv4)
    master = "ssh root@${hcloud_server.master.ipv4_address}"

    # Workers via IPv6 (or use ProxyJump below)
    workers_ipv6 = [for ip in hcloud_server.worker[*].ipv6_address : "ssh root@${ip}"]

    # Recommended: jump through master over private network
    workers_via_master = [
      for i, ip in ["10.0.1.20", "10.0.1.21"] :
      "ssh -J root@${hcloud_server.master.ipv4_address} root@${ip}"
    ]
  }
}

output "worker_public_ipv6" {
  value = hcloud_server.worker[*].ipv6_address
}
