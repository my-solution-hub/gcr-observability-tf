# GitLab on Kubernetes

This directory contains GitLab CE deployment with GitLab Runner for CI/CD on EKS.

## Components

- **GitLab CE**: Self-hosted GitLab Community Edition
- **GitLab Runner**: Kubernetes-based CI/CD runner
- **Persistent Storage**: 20GB for GitLab data, 1GB for config
- **ALB Ingress**: External access via Application Load Balancer

## Deployment

### 1. Deploy GitLab

```bash
./scripts/deploy-gitlab.sh
```

### 2. Get Initial Setup Info

**Get GitLab URL:**
```bash
kubectl get ingress gitlab-ingress -n gitlab
```

**Get root password:**
```bash
kubectl exec -it deployment/gitlab -n gitlab -- grep 'Password:' /etc/gitlab/initial_root_password
```

### 3. Configure GitLab Runner

1. Login to GitLab as root
2. Go to **Admin Area** > **CI/CD** > **Runners**
3. Copy the registration token
4. Deploy runner with token:

```bash
./scripts/deploy-gitlab.sh glrt-xxxxxxxxxxxxxxxxxxxx
```

## Configuration

### GitLab Settings

- **External URL**: Configured via ALB ingress
- **SSH Port**: 22 (for Git operations)
- **Monitoring**: Disabled (using external observability)
- **Backup Retention**: 7 days

### Runner Settings

- **Executor**: Kubernetes
- **Concurrent Jobs**: 4
- **Privileged Mode**: Enabled (for Docker builds)
- **Resource Limits**: 1 CPU, 1GB RAM per job

## CI/CD Pipeline

Example `.gitlab-ci.yml` included with stages:

1. **Validate**: Terraform format and validation
2. **Build**: Docker image build and push to ECR
3. **Deploy**: Kubernetes deployment (manual trigger)

### Required Variables

Set in GitLab project settings:

- `AWS_REGION`: AWS region (e.g., cn-north-1)
- `ECR_REGISTRY`: ECR registry URL
- `EKS_CLUSTER_NAME`: EKS cluster name

## Storage

- **GitLab Data**: 20GB PVC (`gitlab-data`)
- **GitLab Config**: 1GB PVC (`gitlab-config`)
- **Storage Class**: `gp2` (EBS)

## Access

- **Web UI**: Via ALB ingress URL
- **Git SSH**: Port 22 via service
- **API**: Available at `/api/v4/`

## Monitoring

GitLab integrates with the observability stack:
- Logs forwarded to CloudWatch
- Metrics available via Prometheus endpoints
- Traces via OpenTelemetry (if configured)

## Scaling

- GitLab: Single replica (stateful)
- Runner: Can scale replicas for more concurrent jobs
- Storage: Can expand PVC sizes as needed
