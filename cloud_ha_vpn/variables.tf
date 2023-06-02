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

variable "credentials_file" {
  description = "The path to the credentials file for the service account used to provision the resources."
  type        = string
}

variable "shared_secret" {
  description = "The shared secret for VPN tunnels connection."
  type        = string
}