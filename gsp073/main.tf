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

resource "google_storage_bucket" "bucket" {
  name     = var.project
  location = var.zone

  storage_class = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention = "inherited"
}

resource "google_storage_bucket_object" "object" {
  name   = "kitten.png"
  bucket = google_storage_bucket.bucket.name
  source = "kitten.png"
}

resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.object.output_name
  bucket = google_storage_bucket.bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "sub_folder_object" {
  name   = "folder1/folder2/kitten.png"
  bucket = google_storage_bucket.bucket.name
  source = "kitten.png"
}
