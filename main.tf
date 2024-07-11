provider "google" {
  project = "your-gcp-project-id"
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
  name     = "database-name"
  instance = google_sql_database_instance.default.name
}

resource "google_sql_user" "default" {
  name     = "user"
  instance = google_sql_database_instance.default.name
  password = "your-password"
}

# Setting up cloud run
resource "google_cloud_run_service" "default" {
  name     = "cloud-run-service"
  location = "us-central1"
  template {
    spec {
      containers {
        image = "gcr.io/your-gcp-project-id/your-image"
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

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name   = "http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

resource "google_compute_backend_service" "default" {
  name = "backend-service"
  backend {
    group = google_compute_instance_group.cloud-run-service.default.url
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
