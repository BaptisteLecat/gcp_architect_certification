module "instances" {
  source                 = "./modules/instances"
  instance_names         = var.instance_names
  instance_machine_types = var.instance_machine_types
  instance_images        = var.instance_images
  instance_networks      = var.instance_networks
  instance_subnetworks   = var.instance_subnetworks
}

# Uncomment the following code when needed
# module "storage" {
#   project          = var.project
#   source          = "./modules/storage"
#   bucket_name     = var.bucket_name
#   bucket_location = var.bucket_location
# }

# Uncomment the following code when needed
# module "network" {
#   source       = "terraform-google-modules/network/google"
#   version      = "6.0.0"
#   network_name = var.network_name
#   subnets = [
#     {
#       subnet_name   = "subnet-01"
#       subnet_ip     = "10.10.10.0/24"
#       subnet_region = var.subnet_region
#     },
#     {
#       subnet_name   = "subnet-02"
#       subnet_ip     = "10.10.20.0/24"
#       subnet_region = var.subnet_region
#     }
#   ]
#   routing_mode = "GLOBAL"
# }

# Uncomment the following code when needed
# resource "google_compute_firewall" "default" {
#   name    = "tf-firewall"
#   network = var.network_name
#
#   allow {
#     protocol = "tcp"
#     ports    = ["80"]
#   }
#
#   source_ranges = ["0.0.0.0/0"]
# }

