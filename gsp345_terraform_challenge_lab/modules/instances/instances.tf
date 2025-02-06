resource "google_compute_instance" "default" {
  count = length(var.instance_names)
  name         = var.instance_names[count.index]
  machine_type = var.instance_machine_types[count.index]

  boot_disk {
    initialize_params {
      image = var.instance_images[count.index]
    }
  }

  network_interface {
    network    = var.instance_networks[count.index]
    subnetwork = var.instance_subnetworks[count.index]
    access_config {
    }
  }

  metadata = {
    startup-script = <<-EOT
    #!/bin/bash
    EOT
  }

  allow_stopping_for_update = true
}