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
  #TODO add name
  name     = "memories-bucket-68687"
  location = "EU"

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
}

resource "google_pubsub_topic" "topic" {
  #TODO add name
  name = "memories-topic-872"
}

resource "google_storage_bucket" "bucket_function" {
  name     = var.project
  location = "EU"

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
}

resource "google_storage_bucket_object" "archive" {
  name   = "function.zip"
  bucket = google_storage_bucket.bucket_function.name
  source = "./function.zip"
  content_encoding    = "zip"
  content_type        = "application/zip"
}

resource "google_cloudfunctions_function" "function" {
  #TODO add name
  name    = "memories-thumbnail-generator"
  runtime = "nodejs14"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket_function.name
  source_archive_object = google_storage_bucket_object.archive.name
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.bucket.name
  }
  entry_point = "thumbnail"
}
