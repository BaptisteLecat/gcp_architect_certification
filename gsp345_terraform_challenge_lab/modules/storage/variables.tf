variable "project" {
  description = "The ID of the project in which the resources will be provisioned."
  type        = string
}

variable "region" {
  description = "The region in which the resources will be provisioned."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone in which the resources will be provisioned."
  type        = string
  default     = "us-central1-a"
}

variable "bucket_name" {
  description = "The name of the Cloud Storage bucket."
  type        = string
}

variable "bucket_location" {
  description = "The location of the Cloud Storage bucket."
  type        = string
  default     = "US"
}