output "machine_type" {
  value = google_compute_instance.default.*.machine_type
}