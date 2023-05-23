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

resource "google_compute_network" "managementnet" {
  name                    = "managementnet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "managementsubnet-us" {
  name          = "managementsubnet-us"
  network       = google_compute_network.managementnet.name
  region        = "us-east1"
  ip_cidr_range = "10.130.0.0/20"
}

resource "google_compute_network" "privatenet" {
  name                    = "privatenet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "privatesubnet-us" {
  name          = "privatesubnet-us"
  network       = google_compute_network.privatenet.name
  region        = "us-east1"
  ip_cidr_range = "172.16.0.0/24"
}

resource "google_compute_subnetwork" "privatesubnet-eu" {
  name          = "privatesubnet-eu"
  network       = google_compute_network.privatenet.name
  region        = "europe-west1"
  ip_cidr_range = "172.20.0.0/20"
}

resource "google_compute_firewall" "managementnet-allow-icmp-ssh-rdp" {
  name    = "managementnet-allow-icmp-ssh-rdp"
  network = google_compute_network.managementnet.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "privatenet-allow-icmp-ssh-rdp" {
  name    = "privatenet-allow-icmp-ssh-rdp"
  network = google_compute_network.privatenet.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "managementnet-us-vm" {
  name         = "managementnet-us-vm"
  zone         = "us-east1-b"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.managementsubnet-us.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "privatenet-us-vm" {
  name         = "privatenet-us-vm"
  zone         = "us-east1-b"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privatesubnet-us.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "vm-appliance" {
  name         = "vm-appliance"
  zone         = "us-east1-b"
  machine_type = "e2-standard-4"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privatesubnet-us.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.managementsubnet-us.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }

  network_interface {
    network = "mynetwork"

    access_config {
      // Ephemeral public IP
    }
  }
}