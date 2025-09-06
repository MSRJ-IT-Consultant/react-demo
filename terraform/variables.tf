# terraform/variables.tf

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "production-469102"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "react-demo-cluster"
}

variable "service_name" {
  description = "The name of the application service"
  type        = string
  default     = "react-demo-app"
}

variable "repository" {
  description = "The name of the Artifact Registry repository"
  type        = string
  default     = "sb-repository"
}

variable "image_tag" {
  description = "The Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "node_count" {
  description = "The initial number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "The machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}