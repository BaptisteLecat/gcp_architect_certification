terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "instance" {
  name = "lamp-1-vm"
  zone = "us-central1-a"

  machine_type = "n1-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    access_config {
    }
  }

  metadata_startup_script = <<EOT
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install apache2 php7.0 -y
  sudo service apache2 restart
  EOT

}

resource "google_compute_firewall" "default" {
  name    = "http-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["web"]
}

