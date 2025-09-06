# terraform/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
  
  backend "gcs" {
    bucket = "terraform-state-bucket-production-469102"
    prefix = "gke-react-demo"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Get GKE cluster data
data "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone
  
  depends_on = [google_container_cluster.primary]
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

# Get current client config
data "google_client_config" "default" {}

# Create GKE cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Networking
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  
  # IP allocation policy for VPC-native networking
  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }
  
  # Enable network policy
  network_policy {
    enabled = true
  }
  
  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }
  
  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
  }
  
  # Enable binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
  
  # Release channel
  release_channel {
    channel = "REGULAR"
  }
  
  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T09:00:00Z"
      end_time   = "2023-01-01T17:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }
}

# Create separately managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  
  # Auto scaling
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  
  # Node configuration
  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.kubernetes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      env        = "production"
      managed-by = "terraform"
    }
    
    tags = ["gke-node", "${var.cluster_name}-node"]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    # Enable Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # Enable shielded nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
  
  # Upgrade settings
  upgrade_settings {
    strategy = "SURGE"
    max_surge = 1
    max_unavailable = 0
  }
  
  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/14"
  }
  
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.52.0.0/20"
  }
}

# Service Account for Kubernetes nodes
resource "google_service_account" "kubernetes" {
  account_id = "${var.cluster_name}-sa"
}

# IAM binding for the service account
resource "google_project_iam_binding" "kubernetes" {
  project = var.project_id
  role    = "roles/container.nodeServiceAccount"
  
  members = [
    "serviceAccount:${google_service_account.kubernetes.email}"
  ]
}

# Kubernetes namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.service_name
    
    labels = {
      name        = var.service_name
      environment = "production"
      managed-by  = "terraform"
    }
  }
  
  depends_on = [google_container_node_pool.primary_nodes]
}

# Kubernetes deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.service_name
    namespace = kubernetes_namespace.app.metadata.0.name
    
    labels = {
      app         = var.service_name
      version     = var.image_tag
      environment = "production"
      managed-by  = "terraform"
    }
  }
  
  spec {
    replicas = 3
    
    selector {
      match_labels = {
        app = var.service_name
      }
    }
    
    template {
      metadata {
        labels = {
          app         = var.service_name
          version     = var.image_tag
          environment = "production"
        }
      }
      
      spec {
        container {
          image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository}/${var.service_name}:${var.image_tag}"
          name  = var.service_name
          
          port {
            container_port = 3000
          }
          
          env {
            name  = "NODE_ENV"
            value = "production"
          }
          
          env {
            name  = "PORT"
            value = "3000"
          }
          
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          
          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
        
        restart_policy = "Always"
      }
    }
  }
  
  depends_on = [kubernetes_namespace.app]
}

# Kubernetes service
resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.service_name}-service"
    namespace = kubernetes_namespace.app.metadata.0.name
    
    labels = {
      app        = var.service_name
      managed-by = "terraform"
    }
  }
  
  spec {
    selector = {
      app = var.service_name
    }
    
    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
    
    type = "LoadBalancer"
    
    load_balancer_source_ranges = ["0.0.0.0/0"]
  }
  
  depends_on = [kubernetes_deployment.app]
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "${var.service_name}-hpa"
    namespace = kubernetes_namespace.app.metadata.0.name
  }
  
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata.0.name
    }
    
    min_replicas = 2
    max_replicas = 10
    
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
    
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
  
  depends_on = [kubernetes_deployment.app]
}

# Pod Disruption Budget
resource "kubernetes_pod_disruption_budget_v1" "app" {
  metadata {
    name      = "${var.service_name}-pdb"
    namespace = kubernetes_namespace.app.metadata.0.name
  }
  
  spec {
    min_available = 1
    
    selector {
      match_labels = {
        app = var.service_name
      }
    }
  }
  
  depends_on = [kubernetes_deployment.app]
}