provider "google" {
}

resource "google_compute_network" "samg-vpc" {
  name = "samg-vpc"
  project  = var.project
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

