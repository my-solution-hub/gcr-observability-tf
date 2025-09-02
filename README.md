# AWS China Observability Demo

This project demonstrates observability best practices for AWS China regions (GCR) with EKS-based microservices architecture, including compatibility testing in Singapore region.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                            Public Subnets                                   ││
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ ││
│  │  │                        ALB Ingress                                      │ ││
│  │  │                         Port 80                                         │ ││
│  │  └─────────────────────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                           Private Subnets                                   ││
│  │                                                                             ││
│  │  ┌────────────────────────────────────────────────────────────────────────┐ ││
│  │  │                        EKS Cluster                                     │ ││
│  │  │                                                                        │ ││
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │ ││
│  │  │  │ Hello Service   │  │ World Service   │  │ OpenTelemetry   │         │ ││
│  │  │  │ (Java Spring)   │  │ (Python Flask)  │  │   Collector     │         │ ││
│  │  │  │   Port 8080     │  │   Port 5000     │  │ Port 4317/4318  │         │ ││
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘         │ ││
│  │  │           │                       │                       │            │ ││
│  │  │           └───────────┬───────────┘                       │            │ ││
│  │  │                       │                                   │            │ ││
│  │  └───────────────────────┼───────────────────────────────────┼────────────┘ ││
│  │                          │                                   │              ││
│  │    ┌─────────────────────┼─────────────────┐                 │              ││
│  │    │    ElastiCache                        │                 │              ││
│  │    │      Redis                            │                 │              ││
│  │    │    Port 6379                          │                 │              ││
│  │    └─────────────────────┼─────────────────┘                 │              ││
│  │                          │                                   │              ││
│  │    ┌─────────────────────┼─────────────────┐                 │              ││
│  │    │    RDS Aurora                         │                 │              ││
│  │    │      MySQL                            │                 │              ││
│  │    │    Port 3306                          │                 │              ││
│  │    └─────────────────────┼─────────────────┘                 │              ││
│  └──────────────────────────┼──────────────────────────────────────────────────┘│
└─────────────────────────────┼───────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   AWS Services  │
                    │                 │
                    │ • CloudWatch    │
                    │ • X-Ray         │
                    │ • CloudWatch    │
                    │   Logs          │
                    └─────────────────┘
```

## Data Flow

### User Request Flow

```text
User → ALB Ingress → Hello Service → Redis Cache
                                  ↓ (cache miss)
                                  World Service → MySQL Database
```

### Observability Flow

```text
Applications → OpenTelemetry Collector → AWS Services
             (traces/metrics/logs)      (X-Ray/CloudWatch/Logs)
```

## Infrastructure Components

### Container Platform

- **Amazon EKS**: Managed Kubernetes cluster with AWS Load Balancer Controller
  - Multi-region support (China + Singapore)
  - Managed node groups (t3.medium instances)
  - Auto-scaling (1-5 nodes, desired: 3)
  - Container Insights enabled

### Application Services

- **Hello Service (Java Spring Boot)**: Frontend microservice
  - Auto-instrumentation with AWS OpenTelemetry Java Agent
  - Multi-stage Docker build with China npm mirrors
  - Frontend bundling with webpack
  - Port 8080

- **World Service (Python Flask)**: Backend API microservice
  - Auto-instrumentation with OpenTelemetry Python
  - Lightweight Python 3.12 runtime
  - Port 5000

### Data Tier

- **ElastiCache Redis**: Caching layer (cache.t4g.micro)
- **RDS Aurora MySQL**: Primary storage (db.t4g.medium)

### Load Balancing & Networking

- **AWS Load Balancer Controller**: Kubernetes-native ALB integration
- **Ingress Controller**: Single ALB for both services
- **VPC**: 10.0.0.0/16 with public/private subnets

### Observability Stack

- **OpenTelemetry Collector**: Centralized telemetry with China region endpoints
  - Custom AWS config for China regions
  - Memory limiting and batch processing
  - OTLP receivers (gRPC: 4317, HTTP: 4318)

## Multi-Region Support

### Supported Regions

- **cn-north-1** (Beijing) - Primary China region
- **cn-northwest-1** (Ningxia) - Secondary China region  
- **ap-southeast-1** (Singapore) - Compatibility testing

### China Region Optimizations

- **Provider Configuration**: Custom AWS endpoints for China regions
- **Container Registry**: ECR repositories in China regions
- **Network Optimization**: China-specific npm mirrors (registry.npmmirror.com)
- **Service Endpoints**: Region-specific STS, X-Ray, CloudWatch endpoints

## Deployment Strategy

### Infrastructure (Terraform)

- **Multi-environment**: dev/prod with region-specific tfvars
- **Backend Configuration**: S3 backend with DynamoDB locking
- **Modular Design**: Reusable modules for different regions

### Application Deployment

- **Container Images**: Multi-platform builds (linux/amd64)
- **ECR Integration**: Automated image building and pushing
- **Kubernetes Manifests**: Direct kubectl deployment
- **GitLab CI/CD**: Automated pipeline integration

## Project Structure

```text
├── app/                           # Application source code
│   ├── hello/                    # Java Spring Boot + Frontend
│   │   ├── src/                  # Java source and static resources
│   │   ├── pom.xml              # Maven configuration
│   │   ├── package.json         # Frontend dependencies
│   │   └── Dockerfile           # Multi-stage build
│   └── world/                    # Python Flask application
│       ├── app.py               # Flask application
│       ├── requirements.txt     # Python dependencies
│       └── Dockerfile           # Python runtime
├── tf/                           # Terraform infrastructure
│   ├── environments/            # Region-specific configurations
│   │   └── dev/                 # Development environment
│   │       ├── cn-north-1.tfvars
│   │       ├── cn-northwest-1.tfvars
│   │       └── ap-southeast-1.tfvars
│   ├── backend-configs/         # Terraform state backends
│   ├── modules/                 # Reusable Terraform modules
│   └── *.tf                     # Infrastructure definitions
├── k8s/                          # Kubernetes manifests
│   ├── hello-deployment.yaml    # Hello service deployment
│   ├── world-deployment.yaml    # World service deployment
│   ├── otel-collector.yaml      # OpenTelemetry collector
│   └── ingress.yaml             # ALB ingress configuration
├── scripts/                      # Automation scripts
│   ├── build-images.sh          # Docker image building
│   ├── deploy-k8s.sh           # Kubernetes deployment
│   ├── init.sh                  # Environment initialization
│   └── *.sh                     # Other utility scripts
├── devops/                       # CI/CD configurations
│   └── gitlab/                   # GitLab CI/CD pipelines
└── requirements.md               # Detailed observability requirements
```

## Quick Start

### Prerequisites

- AWS CLI configured for target regions
- Terraform >= 1.0
- Docker for image building
- kubectl for Kubernetes management
- kubectx for EKS cluster context switching

### Deployment Steps

1. **Initialize environment**:
   ```bash
   ./scripts/init.sh dev cn-north-1
   ```

2. **Plan infrastructure**:
   ```bash
   ./scripts/plan.sh dev cn-north-1
   ```

3. **Deploy infrastructure**:
   ```bash
   ./scripts/deploy.sh dev cn-north-1
   ```

4. **Setup EKS cluster context**:
   ```bash
   aws eks update-kubeconfig --region cn-north-1 --name observability-demo-dev-eks
   kubectx observability-demo-dev-eks
   ```

5. **Build and push images**:
   ```bash
   ./scripts/build-images.sh latest push
   ```

6. **Deploy applications**:
   ```bash
   ./scripts/deploy-k8s.sh
   ```

### Multi-Region Deployment

Deploy to Singapore for compatibility testing:
```bash
./scripts/deploy.sh dev ap-southeast-1
```

## Observability Requirements

### Performance Monitoring
- P99/P95 response times (target: <150ms)
- Service availability metrics
- CPU/Memory/Disk utilization
- Error rate monitoring with 5-minute refresh

### Database & Cache Monitoring
- RDS/Aurora performance with CloudWatch Database Insights
- ElastiCache Redis hit/miss ratios

### Code-Level Metrics
- **Java**: Bytecode enhancement auto-instrumentation
- **Python**: Runtime hook auto-instrumentation
- **Log Retention**: 14 days with data lake integration

### Alerting & Integration
- CloudWatch alarms (threshold: >300ms)
- SNS → Lambda → PagerDuty integration
- Weekly on-call rotation support

### Cost Optimization
- Pay-as-you-go model
- Log ingestion cost monitoring (95% of total cost)
- Storage tiering (Standard/Infrequent Access)
- Daily billing reports

## CI/CD Integration

### Current Setup
- **Global**: Conveyor integration
- **China**: GitLab repository with Conveyor integration
- **Deployment**: Canary deployment strategy

### Automation
- Automated image building with ECR integration
- Multi-region deployment support
- Environment-specific configuration management

## Security & Compliance

- **Network Isolation**: Private subnets for workloads
- **IAM Roles**: Service account-based authentication
- **Encryption**: At rest and in transit
- **China Compliance**: Region-specific configurations

## Contributing

1. Fork the repository
2. Create environment-specific branch
3. Test in Singapore region first
4. Deploy to China regions
5. Submit pull request

## License

MIT License - see LICENSE file for details.
