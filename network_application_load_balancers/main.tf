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

resource "google_compute_instance" "ww1" {
  name         = "www1"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["network-lb-tag"]
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

  metadata_startup_script = <<EOT
    #!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www1</h3>" | tee /var/www/html/index.html'
    EOT
}
resource "google_compute_instance" "ww2" {
  name         = "www2"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["network-lb-tag"]
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

  metadata_startup_script = <<EOT
    #!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www2</h3>" | tee /var/www/html/index.html'
    EOT
}
resource "google_compute_instance" "ww3" {
  name         = "www3"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["network-lb-tag"]
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

  metadata_startup_script = <<EOT
    #!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www3</h3>" | tee /var/www/html/index.html'
    EOT
}

resource "google_compute_firewall" "rules" {
  project     = var.project
  name        = "www-firewall-network-lb"
  network     = "default"
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["network-lb-tag"]
}

resource "google_compute_address" "ip_address" {
  name   = "network-lb-ip-1"
  region = var.region
}

resource "google_compute_http_health_check" "default" {
  name = "basic-check"
}

resource "google_compute_target_pool" "default" {
  name   = "www-pool"
  region = var.region

  instances = [
    google_compute_instance.ww1.self_link,
    google_compute_instance.ww2.self_link,
    google_compute_instance.ww3.self_link,
  ]

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  name       = "www-rule"
  region     = var.region
  port_range = "80"
  ip_address = google_compute_address.ip_address.id
  target     = google_compute_target_pool.default.id
}

resource "google_compute_instance_template" "template" {
  name         = "lb-backend-template"
  machine_type = "e2-medium"
  region       = var.region
  tags         = ["allow-health-check"]
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
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2'
    EOT
}

resource "google_compute_instance_group_manager" "group" {
  name        = "lb-backend-group"
  description = "Backend group for load balancer"
  zone        = var.zone
  target_size = 2
  base_instance_name = "lb-backend-template"

  version {
    instance_template  = google_compute_instance_template.template.self_link
  }
}

resource "google_compute_firewall" "health-check-firewall-rule" {
  project     = var.project
  name        = "fw-allow-health-check"
  network     = "default"
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
}

#resource "google_compute_global_address" "static" {
#  name          = "lb-ipv4-1"
#  address_type  = "EXTERNAL"
#  ip_version = "IPV4"
#}

resource "google_compute_health_check" "http-basic-check" {
  name = "http-basic-check"
  tcp_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "web-backend-service" {
  name        = "web-backend-service"
  description = "Backend service for load balancer"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [
    google_compute_health_check.http-basic-check.self_link,
  ]

  backend {
    group = google_compute_instance_group_manager.group.instance_group
  }
}

resource "google_compute_url_map" "web-map-http" {
  name            = "web-map-http"
  default_service = google_compute_backend_service.web-backend-service.self_link
}

resource "google_compute_target_http_proxy" "http-lb-proxy" {
  name        = "http-lb-proxy"
  url_map     = google_compute_url_map.web-map-http.self_link
  description = "Target HTTP proxy for load balancer"
}

resource "google_compute_global_forwarding_rule" "http-content-rule" {
  name                  = "http-content-rule"
  target                = google_compute_target_http_proxy.http-lb-proxy.self_link
  ip_address            = var.static_http_load_balancer_ip #Static IP Address created previously from the CLI because Terraform doesn't work on this
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}