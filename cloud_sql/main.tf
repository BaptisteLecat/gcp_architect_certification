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

resource "google_sql_database_instance" "database" {
  name             = "wordpress-db"
  database_version = "MYSQL_5_7"
  region           = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]


  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.

    #standard machine types
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = "projects/${var.project}/global/networks/default"
    }

    disk_size = "10"
    disk_type = "PD_SSD"
  }
}

resource "google_sql_user" "users" {
  name     = "root"
  instance = google_sql_database_instance.database.name
  host     = "%"
  password = "password"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "default"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "default"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
