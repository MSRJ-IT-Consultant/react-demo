# GKE Deployment with Terraform

This repository contains Terraform configurations to deploy a React application to Google Kubernetes Engine (GKE) with comprehensive CI/CD pipeline using GitHub Actions.

## Architecture Overview

- **GKE Cluster**: Regional cluster with node auto-scaling
- **VPC Network**: Custom VPC with secondary IP ranges for pods and services
- **Security**: Workload Identity, Binary Authorization, Shielded Nodes
- **Auto-scaling**: Horizontal Pod Autoscaler and Cluster Autoscaler
- **Load Balancing**: Google Cloud Load Balancer for external traffic
- **Monitoring**: Integration with Google Cloud Monitoring

## Prerequisites

1. **Google Cloud Project** with the following APIs enabled:
   - Kubernetes Engine API
   - Compute Engine API
   - Container Registry API
   - Cloud Resource Manager API

2. **Service Account** with the following roles:
   - Kubernetes Engine Admin
   - Compute Admin
   - Service Account Admin
   - Project IAM Admin

3. **Terraform State Bucket**:
   ```bash
   gsutil mb gs://terraform-state-bucket-production-469102
   gsutil versioning set on gs://terraform-state-bucket-production-469102
   ```

4. **GitHub Secrets**:
   - `GCP_SA_KEY`: Service account JSON key
   - `SNYK_TOKEN`: Snyk authentication token
   - `SLACK_WEBHOOK`: Slack webhook URL for notifications

## Directory Structure

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf           # Variable definitions
├── outputs.tf             # Output values
├── versions.tf            # Provider version constraints
└── terraform.tfvars.example  # Example variables file
```

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. **Configure Terraform variables**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### Main Components

#### GKE Cluster
- **Location**: Zonal cluster in asia-southeast1-a
- **Node Pool**: e2-medium instances with auto-scaling (1-3 nodes)
- **Networking**: VPC-native with private nodes
- **Security**: Workload Identity enabled, Binary Authorization

#### Kubernetes Resources
- **Namespace**: Dedicated namespace for the application
- **Deployment**: 3 replicas with resource limits and health checks
- **Service**: LoadBalancer type for external access
- **HPA**: Auto-scaling based on CPU (70%) and memory (80%) utilization
- **PDB**: Pod Disruption Budget for high availability

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | `production-469102` |
| `region` | GCP region | `asia-southeast1` |
| `zone` | GCP zone | `asia-southeast1-a` |
| `cluster_name` | GKE cluster name | `react-demo-cluster` |
| `service_name` | Application service name | `react-demo-app` |
| `image_tag` | Docker image tag | `latest` |
| `node_count` | Initial node count | `2` |
| `app_replicas` | Application replicas | `3` |

## CI/CD Pipeline

The GitHub Actions workflow includes:

### 1. Security Scanning
- **Snyk**: Dependency vulnerability scanning
- **Trivy**: Container image security scanning
- **Security Gates**: Pipeline stops if Critical/High vulnerabilities found

### 2. Build and Push
- **Docker Build**: Multi-stage build for optimized images
- **Artifact Registry**: Secure container image storage
- **Image Tagging**: Commit SHA-based tagging for traceability

### 3. Infrastructure as Code
- **Terraform Plan**: Infrastructure change preview
- **Terraform Apply**: Automated infrastructure provisioning
- **State Management**: Remote state in Google Cloud Storage

### 4. Deployment
- **Kubernetes Deployment**: Automated application deployment
- **Health Checks**: Application readiness verification
- **Load Balancer**: External IP provisioning and validation

### 5. Notifications
- **Slack Integration**: Success/failure notifications with detailed status
- **Audit Trail**: Security scan results and deployment artifacts

## Security Features

### Cluster Security
- **Private Nodes**: Nodes without public IP addresses
- **Authorized Networks**: Master API server access control
- **Network Policy**: Pod-to-pod communication control
- **Binary Authorization**: Container image verification
- **Workload Identity**: Secure access to Google Cloud services

### Application Security
- **Security Scanning**: Multi-layer vulnerability detection
- **Resource Limits**: Container resource constraints
- **Health Checks**: Liveness and readiness probes
- **Pod Security Standards**: Security context enforcement

## Monitoring and Observability

### Kubernetes Metrics
- **Resource Utilization**: CPU, memory, and storage metrics
- **Pod Health**: Pod status and restart counts
- **Service Metrics**: Request rates and response times

### Google Cloud Monitoring
- **Cluster Monitoring**: Node and cluster health metrics
- **Application Logs**: Centralized log aggregation
- **Alerting**: Custom alerting rules for critical events

## Scaling

### Horizontal Pod Autoscaler (HPA)
- **CPU Target**: 70% utilization
- **Memory Target**: 80% utilization
- **Min Replicas**: 2
- **Max Replicas**: 10

### Cluster Autoscaler
- **Min Nodes**: 1
- **Max Nodes**: 3
- **Auto-scaling**: Based on pod resource requests

## Disaster Recovery

### High Availability
- **Multi-Zone**: Node pool spans multiple zones
- **Pod Disruption Budget**: Minimum 1 pod always available
- **Rolling Updates**: Zero-downtime deployments

### Backup and Recovery
- **State Backup**: Terraform state versioning
- **Configuration Backup**: Infrastructure as Code in version control
- **Application Data**: Stateless application design

## Troubleshooting

### Common Issues

1. **Permission Denied**:
   ```bash
   # Check service account permissions
   gcloud projects get-iam-policy <project-id>
   ```

2. **Cluster Access**:
   ```bash
   # Get cluster credentials
   gcloud container clusters get-credentials <cluster-name> --zone=<zone> --project=<project-id>
   ```

3. **Pod Issues**:
   ```bash
   # Check pod status
   kubectl get pods -n <namespace>
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

4. **Service Issues**:
   ```bash
   # Check service status
   kubectl get svc -n <namespace>
   kubectl describe svc <service-name> -n <namespace>
   ```

### Useful Commands

```bash
# View cluster info
kubectl cluster-info

# Check node status
kubectl get nodes

# View all resources in namespace
kubectl get all -n <namespace>

# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5 -n <namespace>

# View HPA status
kubectl get hpa -n <namespace>

# Check pod resources
kubectl top pods -n <namespace>
```

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the cluster and associated data.

## Support

For issues and questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review GitHub Actions logs
3. Check Terraform plan output
4. Verify Google Cloud console for resource status

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.