output "database_instance_name" {
  value = google_sql_database_instance.default.name
}

output "cloud_run_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "load_balancer_ip" {
  value = google_compute_global_address.default.address
}
