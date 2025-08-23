# AWS China Observability Demo

This project demonstrates observability best practices for AWS China regions with EKS-based microservices architecture.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                            Public Subnets                                   ││
│  │  ┌─────────────────┐                    ┌─────────────────┐                 ││
│  │  │   ALB (Hello)   │                    │   ALB (World)   │                 ││
│  │  │   Port 80       │                    │   Port 80       │                 ││
│  │  └─────────────────┘                    └─────────────────┘                 ││
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
User → ALB → EKS Service → Hello Pod → Redis Cache
                                    ↓ (cache miss)
                                    World Pod → MySQL Database
```

### Observability Flow

```text
Applications → OpenTelemetry Collector → AWS Services
             (traces/metrics/logs)      (X-Ray/CloudWatch/Logs)
```

## Infrastructure Components

### Container Platform

- **Amazon EKS**: Managed Kubernetes cluster
  - Kubernetes version 1.32
  - Managed node groups with auto-scaling
  - OIDC provider for service account authentication
  - Container Insights enabled for observability

### Application Services

- **Hello Service (Java Spring Boot)**: Frontend microservice
  - Deployed as Kubernetes pods
  - Checks Redis cache first for performance
  - Calls World service on cache miss
  - Caches responses for 5 minutes

- **World Service (Python Flask)**: Backend API microservice
  - Deployed as Kubernetes pods
  - Retrieves data from MySQL database
  - Initializes database with sample data
  - Provides REST API endpoints

### Data Tier

- **ElastiCache Redis**: High-performance caching layer
  - Multi-AZ deployment for availability
  - Encryption at rest and in transit
  - 5-minute TTL for cached data

- **RDS Aurora MySQL**: Primary data storage
  - Multi-AZ setup for high availability
  - Automated backups and point-in-time recovery
  - Performance monitoring with CloudWatch

### Load Balancing

- **Application Load Balancer**: Routes external traffic to EKS services
  - Kubernetes Ingress integration
  - Health checks and SSL termination
  - Cross-zone load balancing

### Observability Stack

- **OpenTelemetry Collector**: Centralized telemetry collection
  - Deployed as Kubernetes DaemonSet
  - OTLP receivers (gRPC: 4317, HTTP: 4318)
  - Processes traces, metrics, and logs
  - Forwards to AWS observability services
  - Service account with IAM role for AWS access

## Deployment Strategy

### Infrastructure (Terraform)

- **VPC and Networking**: Subnets, security groups, NAT gateways
- **EKS Cluster**: Control plane and managed node groups
- **Data Services**: RDS Aurora MySQL and ElastiCache Redis
- **IAM Roles**: Service accounts for AWS service integration

### Application Deployment (Flux CD)

- **GitOps Approach**: Applications deployed via Flux CD
- **Kubernetes Manifests**: Deployments, services, ingress
- **Configuration Management**: ConfigMaps and secrets
- **Continuous Deployment**: Automated updates from Git repository

## AWS Services Integration

- **Amazon CloudWatch**: Application and infrastructure metrics
- **AWS X-Ray**: Distributed tracing for request flow analysis
- **CloudWatch Logs**: Centralized logging for all services
- **IAM Roles**: Secure service-to-service authentication

## Project Structure

```text
├── app/                    # Sample application code
│   ├── hello/             # Java Spring Boot application
│   └── world/             # Python Flask application
├── tf/                    # Terraform infrastructure code
│   ├── environments/      # Environment-specific configurations
│   ├── backend-configs/   # Terraform backend configurations
│   └── *.tf              # Infrastructure definitions
├── scripts/               # Deployment and utility scripts
├── devops/               # CI/CD configurations
│   ├── ci/               # Continuous Integration
│   └── cd/               # Continuous Deployment
└── README.md             # This file
```

## Supported AWS China Regions

- **cn-north-1** (Beijing)
- **cn-northwest-1** (Ningxia)

## Quick Start

### Prerequisites

- AWS China account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured for China regions

### Deployment Steps

1. **Validate configuration**:

   ```bash
   ./scripts/validate.sh
   ```

2. **Plan deployment**:

   ```bash
   ./scripts/plan.sh dev cn-north-1 cn
   ```

3. **Deploy infrastructure**:

   ```bash
   ./scripts/deploy.sh dev cn-north-1 cn
   ```

4. **View outputs**:

   ```bash
   ./scripts/outputs.sh
   ```

5. **Access applications**:
   - Hello Service: Use ALB DNS name from outputs
   - Monitoring: Check CloudWatch dashboards

### Cleanup

```bash
./scripts/destroy.sh dev cn-north-1 cn
```

## Monitoring and Observability

### Key Metrics

- **Application Performance**: Response times, error rates
- **Infrastructure Health**: CPU, memory, disk utilization
- **Database Performance**: Connection counts, query performance
- **Cache Performance**: Hit/miss ratios, memory usage

### Dashboards

- CloudWatch dashboards for infrastructure metrics
- X-Ray service maps for distributed tracing
- Custom application metrics via OpenTelemetry

### Alerting

- CloudWatch alarms for critical thresholds
- SNS notifications for incident response
- Integration points for PagerDuty or similar services

## Security Features

- **Network Isolation**: Private subnets for application and data tiers
- **Encryption**: At rest and in transit for all data stores
- **IAM Roles**: Least privilege access for all services
- **Security Groups**: Restrictive firewall rules

## Cost Optimization

- **Right-sizing**: Appropriate instance types for workloads
- **Auto Scaling**: Planned for future implementation
- **Reserved Instances**: Recommended for production workloads
- **Monitoring**: CloudWatch billing alerts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
