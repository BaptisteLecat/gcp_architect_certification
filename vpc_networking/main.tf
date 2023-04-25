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

resource "google_compute_network" "default" {
  name                    = "mynetwork"
  auto_create_subnetworks = true #TODO change to true or false depending on the task
}

resource "google_compute_firewall" "default-allow-internal" {
  name    = "default-allow-internal"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }


  source_ranges = ["10.128.0.0/9"]
}

resource "google_compute_firewall" "default-allow-rdp" {
  name    = "default-allow-rdp"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "default-allow-icmp" {
  name    = "default-allow-icmp"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}



resource "google_compute_firewall" "default-allow-ssh" {
  name    = "default-allow-ssh"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "instance1" {
  name         = "mynet-us-vm"
  zone         = var.zone
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.default.name

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "instance2" {
  name         = "mynet-eu-vm"
  zone         = "europe-west1-c"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.default.name

    access_config {
      // Ephemeral public IP
    }
  }
}




resource "google_compute_network" "managementnet" {
  name                    = "managementnet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "managementsubnet-us" {
  name          = "managementsubnet-us"
  ip_cidr_range = "10.240.0.0/20"
  region        = var.region
  network       = google_compute_network.managementnet.name
}

resource "google_compute_network" "privatenet" {
  name                    = "privatenet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "privatesubnet-us" {
  name          = "privatesubnet-us"
  ip_cidr_range = "172.16.0.0/24"
  region        = var.region
  network       = google_compute_network.privatenet.name
}

resource "google_compute_subnetwork" "privatesubnet-eu" {
  name          = "privatesubnet-eu"
  ip_cidr_range = "172.20.0.0/20"
  region        = "europe-west1"
  network       = google_compute_network.privatenet.name
}

resource "google_compute_firewall" "managementnet-allow-icmp-ssh-rdp" {
  name    = "managementnet-allow-icmp-ssh-rdp"
  network = google_compute_network.managementnet.name
  priority = 1000

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "privatenet-allow-icmp-ssh-rdp" {
  name    = "privatenet-allow-icmp-ssh-rdp"
  network = google_compute_network.privatenet.name
  priority = 1000

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "managementnet-us-vm" {
  name         = "managementnet-us-vm"
  zone         = var.zone
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.managementnet.name
    subnetwork = google_compute_subnetwork.managementsubnet-us.name

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "privatenet-us-vm" {
  name         = "privatenet-us-vm"
  zone         = var.zone
  machine_type = "e2-micro"

  boot_disk {
    device_name = "privatenet-us-vm"
    initialize_params {
      size = 10
      image = "debian-cloud/debian-11"
      type = "pd-standard"
    }
  }

  network_interface {
    network = google_compute_network.privatenet.name
    subnetwork = google_compute_subnetwork.privatesubnet-us.name

    access_config {
      // Ephemeral public IP
    }
  }
}