terraform {
  # Uncomment the following code when needed
  # backend "gcs" {
  #   bucket  = var.bucket_name
  #   prefix  = "terraform/state"
  # }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}