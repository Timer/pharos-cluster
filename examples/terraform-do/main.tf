variable "do_token" {}

variable "ssh_keys" {
  type = "list"
}

variable "region" {
  default = "ams3"
}

variable "master_count" {
  default = 3
}

variable "worker_count" {
  default = 3
}

variable "master_size" {
  default = "2gb"
}

variable "worker_size" {
  default = "2gb"
}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "pharos_master" {
  count              = "${var.master_count}"
  image              = "ubuntu-16-04-x64"
  name               = "pharos-master-${count.index}"
  region             = "${var.region}"
  size               = "${var.master_size}"
  private_networking = true
  ssh_keys           = "${var.ssh_keys}"
}

resource "digitalocean_droplet" "pharos_worker" {
  count              = "${var.worker_count}"
  image              = "ubuntu-16-04-x64"
  name               = "pharos-worker-${count.index}"
  region             = "${var.region}"
  size               = "${var.worker_size}"
  private_networking = true
  ssh_keys           = "${var.ssh_keys}"
}

resource "digitalocean_loadbalancer" "pharos_master_lb" {
  name   = "pharos-master-lb"
  region = "${var.region}"

  forwarding_rule {
    entry_port     = 6443
    entry_protocol = "tcp"

    target_port     = 6443
    target_protocol = "tcp"
  }

  healthcheck {
    port     = 6443
    protocol = "tcp"
  }

  droplet_ids = ["${digitalocean_droplet.pharos_master.*.id}"]
}

output "pharos_api" {
  value = {
    endpoint = "${digitalocean_loadbalancer.pharos_master_lb.ip}"
  }
}

output "pharos_hosts" {
  value = {
    masters = {
      address         = "${digitalocean_droplet.pharos_master.*.ipv4_address}"
      private_address = "${digitalocean_droplet.pharos_master.*.ipv4_address_private}"
      role            = "master"
      user            = "root"
    }

    workers = {
      address         = "${digitalocean_droplet.pharos_worker.*.ipv4_address}"
      private_address = "${digitalocean_droplet.pharos_worker.*.ipv4_address_private}"
      role            = "worker"
      user            = "root"
    }
  }
}
