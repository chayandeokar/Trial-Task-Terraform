provider "google" {
  project = "32919635075"
  region  = "us-central1"
}

resource "google_sql_database_instance" "default" {
  name             = "trail-task"
  database_version = "POSTGRES_12"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "default" {
  name     = "trail-task"
  instance = google_sql_database_instance.default.name
}

resource "google_sql_user" "default" {
  name     = "chayan"
  instance = google_sql_database_instance.default.name
  password = "Chayan@123"
}

# Setting up cloud run
resource "google_cloud_run_service" "default" {
  name     = "cloud-run-service"
  location = "us-central1"
  template {
    spec {
      containers {
        image = "gcr.io/modular-virtue-429117-h8/trail-task"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "default" {
  service = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role    = "roles/run.invoker"
  member  = "allUsers"
}

## Setting up loadbalancer

resource "google_compute_global_address" "default" {
  name = "global-address"
}

resource "google_compute_region_backend_service" "default" {
  name     = "backend-service"
  region   = "us-central1"
  protocol = "HTTP"

  backend {
    group = google_cloud_run_service.default.name
  }

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name = "health-check"

  http_health_check {
    request_path = "/"
    port         = "80"
  }
}

resource "google_compute_region_url_map" "default" {
  name            = "url-map"
  region          = "us-central1"
  default_service = google_compute_region_backend_service.default.id
}

resource "google_compute_region_target_http_proxy" "default" {
  name   = "http-proxy"
  region = "us-central1"
  url_map = google_compute_region_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "forwarding-rule"
  target     = google_compute_region_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}
