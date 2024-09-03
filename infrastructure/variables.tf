variable "project_id" {
  description = "ID of the Google Cloud project"
  type        = string
}

variable "region" {
  description = "Google Cloud region for the resources"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "docker_repo_name" {
  description = "Name of the repository in Cloud Registry"
  type        = string
}
