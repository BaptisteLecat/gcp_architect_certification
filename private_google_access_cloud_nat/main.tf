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

resource "google_compute_network" "privatenet" {
  name                    = "privatenet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "privatesubnet-us" {
  name                     = "privatenet-us"
  network                  = google_compute_network.privatenet.name
  region                   = var.region
  ip_cidr_range            = "10.130.0.0/20"
  private_ip_google_access = true # TODO change to true to enable Private Google Access
}

resource "google_compute_firewall" "privatenet-allow-ssh" {
  name    = "privatenet-allow-ssh"
  network = google_compute_network.privatenet.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google's IAP IP range
}

resource "google_compute_instance" "vm-internal" {
  name         = "vm-internal"
  zone         = var.zone
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.privatenet.name
    subnetwork = google_compute_subnetwork.privatesubnet-us.name
  }
}

resource "google_storage_bucket" "default" {
  name                     = var.project
  location                 = "EU"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "default" {
  name         = "access.svg"
  bucket       = google_storage_bucket.default.name
  source       = "./assets/access.svg"
  content_type = "image/svg+xml"
}

## Create Cloud Router

resource "google_compute_router" "router" {
  name    = "nat-router"
  network = google_compute_network.privatenet.name
  region  = var.region
}

## Create Nat Gateway

resource "google_compute_router_nat" "nat" {
  name                               = "nat-config"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}