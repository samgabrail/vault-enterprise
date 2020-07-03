terraform {
  required_providers {
    google = "~> 3.28"
    null = "~> 2.1"
  }
}

provider "google" {
  # version = "= 2.5.1"
  project  = var.project
}

resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "google_compute_network" "samg-vpc" {
  name = "samg-vpc"
}

resource "google_compute_firewall" "vault-fw" {
  name    = "vault-fw"
  network = google_compute_network.samg-vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "8200"]
  }

  direction = "INGRESS"

  // Allow traffic from everywhere to instances with vault-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vault-server"]
}

resource "google_compute_instance" "vault-prim-uswest1-a" {
  name         = "vault-prim-uswest1-a"
  machine_type = var.machine_type
  zone         = "us-west1-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = google_compute_network.samg-vpc.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh-key.public_key_openssh)} terraform"
  }

  tags = ["vault-server"]
}


resource "null_resource" "configure-vault" {
  depends_on = [
    google_compute_instance.vault-prim-uswest1-a
  ]

  triggers = {
    build_number = timestamp()
  }

  provisioner "file" {
    source      = "scripts/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      timeout     = "300s"
      private_key = tls_private_key.ssh-key.private_key_pem
      host        = google_compute_instance.vault-prim-uswest1-a.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x *.sh",
      "sudo ./vaultprimaryactive.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      timeout     = "300s"
      private_key = tls_private_key.ssh-key.private_key_pem
      host        = google_compute_instance.vault-prim-uswest1-a.network_interface.0.access_config.0.nat_ip
    }
  }
}