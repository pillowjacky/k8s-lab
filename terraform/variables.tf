variable "allowed_ips" {
  type    = list(string)
  default = null
}

variable "cluster_name" {
  type    = string
  default = "k8s-lab"
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token (Read & Write)"
  type        = string
  sensitive   = true
}

variable "k8s_version" {
  type    = string
  default = "1.35"
}

variable "location" {
  description = "Cheapest EU locations: fsn1 (Falkenstein), nbg1 (Nuremberg), hel1 (Helsinki). sin is more expensive."
  type        = string
  default     = "fsn1"
  validation {
    condition     = contains(["fsn1", "nbg1", "hel1", "sin", "ash", "hil"], var.location)
    error_message = "Valid locations: fsn1, nbg1, hel1, sin, ash, hil"
  }
}

variable "server_type" {
  description = "Cheapest viable type for CKA/CKS lab. cx23 = 2vCPU/4GB (x86). cax11 = 2vCPU/4GB (ARM, similar price)."
  type        = string
  default     = "cx23"
}

variable "ssh_public_key" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_hcloud.pub"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}
