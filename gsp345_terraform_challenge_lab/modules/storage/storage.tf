resource "google_storage_bucket" "backend_bucket" {
  location = var.bucket_location
  name     = var.bucket_name
  force_destroy = true
  uniform_bucket_level_access = true
}