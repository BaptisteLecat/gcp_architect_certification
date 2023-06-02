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

resource "google_compute_network" "vpc-demo" {
  name                    = "vpc-demo"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc-demo-subnet1" {
  name          = "vpc-demo-subnet1"
  network       = google_compute_network.vpc-demo.name
  region        = "us-central1"
  ip_cidr_range = "10.1.1.0/24"
}

resource "google_compute_subnetwork" "vpc-demo-subnet2" {
  name          = "vpc-demo-subnet2"
  network       = google_compute_network.vpc-demo.name
  region        = "us-east1"
  ip_cidr_range = "10.2.1.0/24"
}

resource "google_compute_firewall" "vpc-demo-allow-custom" {
  name    = "vpc-demo-allow-custom"
  network = google_compute_network.vpc-demo.name

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

  source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_firewall" "vpc-demo-allow-ssh-icmp" {
  name    = "vpc-demo-allow-ssh-icmp"
  network = google_compute_network.vpc-demo.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "vpc-demo-instance1" {
  name         = "vpc-demo-instance1"
  zone         = "us-central1-b"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork         = google_compute_subnetwork.vpc-demo-subnet1.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance" "vpc-demo-instance2" {
  name         = "vpc-demo-instance2"
  zone         = "us-east1-b"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork         = google_compute_subnetwork.vpc-demo-subnet2.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_network" "on-prem" {
  name                    = "on-prem"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "on-prem-subnet1" {
  name          = "on-prem-subnet1"
  network       = google_compute_network.on-prem.name
  region        = "us-central1"
  ip_cidr_range = "192.168.1.0/24"
}

resource "google_compute_firewall" "on-prem-allow-custom" {
  name    = "on-prem-allow-custom"
  network = google_compute_network.on-prem.name

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

  source_ranges = ["192.168.0.0/16"]
}

resource "google_compute_firewall" "on-prem-allow-ssh-icmp" {
  name    = "on-prem-allow-ssh-icmp"
  network = google_compute_network.on-prem.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "on-prem-instance1" {
  name         = "on-prem-instance1"
  zone         = "us-central1-a"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork         = google_compute_subnetwork.on-prem-subnet1.self_link
    subnetwork_project = var.project

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_ha_vpn_gateway" "vpc-demo-vpn-gw1" {
  name    = "vpc-demo-vpn-gw1"
  region  = "us-central1"
  network = google_compute_network.vpc-demo.name
}

resource "google_compute_ha_vpn_gateway" "on-prem-vpn-gw1" {
  name    = "on-prem-vpn-gw1"
  region  = "us-central1"
  network = google_compute_network.on-prem.name
}

resource "google_compute_router" "vpc-demo-router1" {
  name    = "vpc-demo-router1"
  network = google_compute_network.vpc-demo.name
  region  = "us-central1"
  bgp {
    asn = 65001
  }
}

resource "google_compute_router" "on-prem-router1" {
  name    = "on-prem-router1"
  network = google_compute_network.on-prem.name
  region  = "us-central1"
  bgp {
    asn = 65002
  }
}

resource "google_compute_vpn_tunnel" "vpc-demo-tunnel0" {
  name                  = "vpc-demo-tunnel0"
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  region                = "us-central1"
  ike_version           = 2
  shared_secret         = var.shared_secret
  router                = google_compute_router.vpc-demo-router1.name
  vpn_gateway           = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "vpc-demo-tunnel1" {
  name                  = "vpc-demo-tunnel1"
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  region                = "us-central1"
  ike_version           = 2
  shared_secret         = var.shared_secret
  router                = google_compute_router.vpc-demo-router1.name
  vpn_gateway           = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "on-prem-tunnel0" {
  name                  = "on-prem-tunnel0"
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  region                = "us-central1"
  ike_version           = 2
  shared_secret         = var.shared_secret
  router                = google_compute_router.on-prem-router1.name
  vpn_gateway           = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "on-prem-tunnel1" {
  name                  = "on-prem-tunnel1"
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  region                = "us-central1"
  ike_version           = 2
  shared_secret         = var.shared_secret
  router                = google_compute_router.on-prem-router1.name
  vpn_gateway           = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "if-tunnel0-to-on-prem" {
  name       = "if-tunnel0-to-on-prem"
  router     = google_compute_router.vpc-demo-router1.name
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpc-demo-tunnel0.name
  region     = "us-central1"
}

resource "google_compute_router_peer" "bgp-on-prem-tunnel0" {
  name            = "bgp-on-prem-tunnel0"
  interface       = google_compute_router_interface.if-tunnel0-to-on-prem.name
  peer_ip_address = "169.254.0.2"
  peer_asn        = 65002
  router          = google_compute_router.vpc-demo-router1.name
  region          = "us-central1"
}

resource "google_compute_router_interface" "if-tunnel1-to-on-prem" {
  name       = "if-tunnel1-to-on-prem"
  router     = google_compute_router.vpc-demo-router1.name
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpc-demo-tunnel1.name
  region     = "us-central1"
}

resource "google_compute_router_peer" "bgp-on-prem-tunnel1" {
  name            = "bgp-on-prem-tunnel1"
  interface       = google_compute_router_interface.if-tunnel1-to-on-prem.name
  peer_ip_address = "169.254.1.2"
  peer_asn        = 65002
  router          = google_compute_router.vpc-demo-router1.name
  region          = "us-central1"
}

resource "google_compute_router_interface" "if-tunnel0-to-vpc-demo" {
  name       = "if-tunnel0-to-vpc-demo"
  router     = google_compute_router.on-prem-router1.name
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.on-prem-tunnel0.name
  region     = "us-central1"
}

resource "google_compute_router_peer" "bgp-vpc-demo-tunnel0" {
  name            = "bgp-vpc-demo-tunnel0"
  interface       = google_compute_router_interface.if-tunnel0-to-vpc-demo.name
  peer_ip_address = "169.254.0.1"
  peer_asn        = 65001
  router          = google_compute_router.on-prem-router1.name
  region          = "us-central1"
}

resource "google_compute_router_interface" "if-tunnel1-to-vpc-demo" {
  name       = "if-tunnel1-to-vpc-demo"
  router     = google_compute_router.on-prem-router1.name
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.on-prem-tunnel1.name
  region     = "us-central1"
}

resource "google_compute_router_peer" "bgp-vpc-demo-tunnel1" {
  name            = "bgp-vpc-demo-tunnel1"
  interface       = google_compute_router_interface.if-tunnel1-to-vpc-demo.name
  peer_ip_address = "169.254.1.1"
  peer_asn        = 65001
  router          = google_compute_router.on-prem-router1.name
  region          = "us-central1"
}

resource "google_compute_firewall" "vpc-demo-allow-subnets-from-on-prem" {
  name    = "vpc-demo-allow-subnets-from-on-prem"
  network = google_compute_network.vpc-demo.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["192.168.1.0/24"]
}

resource "google_compute_firewall" "on-prem-allow-subnets-from-vpc-demo" {
  name    = "on-prem-allow-subnets-from-vpc-demo"
  network = google_compute_network.on-prem.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.1.1.0/24", "10.2.1.0/24"]
}