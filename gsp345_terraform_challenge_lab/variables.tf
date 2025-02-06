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
  default = "service.json"
}

variable "instance_ids" {
  description = "The unique identifier for the instance."
  type = list(string)
}

variable "instance_names" {
  description = "The name of the instance."
  type = list(string)
}

variable "instance_machine_types" {
  description = "The name of the instance."
  type    = list(string)
}

variable "instance_images" {
  description = "The name of the instance."
  type    = list(string)
}

variable "instance_networks" {
  description = "The name of the instance."
  type = list(string)
}

variable "instance_subnetworks" {
  description = "The name of the instance."
  type = list(string)
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

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
}
