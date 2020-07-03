provider "google" {
  project  = var.project
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

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "vault-prim-uswest1-a" {
  name         = "vault-prim-uswest1-a"
  machine_type = var.machine_type
  zone         = "us-west1-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.samg-vpc.name
    }
  }

  
}
