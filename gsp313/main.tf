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

resource "google_compute_instance" "default" {
  name         = "nucleus-jumphost-259"
  machine_type = "f1-micro"
  zone         = var.zone

  tags = ["jumphost"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance_template" "default" {
  name = "nucleus-instance-template"

  tags = ["template"]

  machine_type = "f1-micro"
  region       = var.region

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = "default"
    subnetwork = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = <<EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    service nginx start
    sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
    EOT
}

resource "google_compute_target_pool" "default" {
  name = "nucleus-target-pool"

  instances = [google_compute_instance.default.self_link]
}


resource "google_compute_instance_group_manager" "default" {
  name               = "nucleus-instance-group-manager"
  zone               = var.zone
  base_instance_name = "nucleus-instance-template"

  target_size = 2

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.default.self_link
  }

  target_pools = [google_compute_target_pool.default.self_link]
}

resource "google_compute_firewall" "default" {
  name    = "allow-tcp-rule-794"
  network = "default"
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_health_check" "tcp-health-check" {
  name = "tcp-health-check"

  tcp_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "default" {
  name          = "backend-service"
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 10
  health_checks = [google_compute_health_check.tcp-health-check.id]

  backend {
    group = google_compute_instance_group_manager.default.instance_group
  }
}

resource "google_compute_url_map" "web-map-http" {
  name            = "web-map-http"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "http-lb-proxy" {
  name        = "http-lb-proxy"
  url_map     = google_compute_url_map.web-map-http.self_link
  description = "Target HTTP proxy for load balancer"
}

resource "google_compute_global_forwarding_rule" "google_compute_forwarding_rule" {
  name                  = "lb-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http-lb-proxy.self_link
  ip_address            = var.static_http_load_balancer_ip
}