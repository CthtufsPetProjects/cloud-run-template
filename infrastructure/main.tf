provider "google" {
  project = var.project_id
  region  = var.region
}

# Включение необходимых API
resource "google_project_service" "cloud_run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_registry_api" {
  service            = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

# Создание сервисного аккаунта для Cloud Run
resource "google_service_account" "cloud_run_service_account" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

# Создание репозитория в Google Artifact Registry
resource "google_artifact_registry_repository" "docker_repository" {
  provider      = google
  project       = var.project_id
  location      = var.region
  repository_id = var.docker_repo_name  # Название вашего репозитория
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry_api]
}

# Назначение роли admin для Google Artifact Registry
resource "google_project_iam_binding" "artifact_registry_service_account_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"

  members = [
    "serviceAccount:${google_service_account.cloud_run_service_account.email}"
  ]
}

# Назначение роли admin для Google Container Registry
resource "google_project_iam_binding" "container_registry_service_account_admin" {
  project = var.project_id
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.cloud_run_service_account.email}"
  ]
}

# Назначение роли admin для Cloud Run
resource "google_project_iam_binding" "cloud_run_service_account_admin" {
  project = var.project_id
  role    = "roles/run.admin"

  members = [
    "serviceAccount:${google_service_account.cloud_run_service_account.email}"
  ]
}

# Создание bucket для хранения состояния Terraform
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-terraform-state"
  location      = var.region
  force_destroy = true
}

# Назначение роли serviceAccountUser для использования сервисного аккаунта Cloud Run
resource "google_project_iam_binding" "cloud_run_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.cloud_run_service_account.email}"
  ]
}

# Создание сервиса Cloud Run
resource "google_cloud_run_service" "cloud_run_service" {
  name     = var.cloud_run_service_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_service_account.email
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.docker_repo_name}/${var.cloud_run_service_name}:latest"
        resources {
          limits = {
            cpu    = "1"
            memory = "128Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run_api,
    google_project_service.artifact_registry_api,
    google_project_service.container_registry_api,
    google_artifact_registry_repository.docker_repository
  ]
}

# Добавление IAM Binding для неаутентифицированного доступа к Cloud Run
resource "google_cloud_run_service_iam_binding" "noauth" {
  location = google_cloud_run_service.cloud_run_service.location
  project  = var.project_id
  service  = google_cloud_run_service.cloud_run_service.name

  role    = "roles/run.invoker"
  members = ["allUsers"]
}
