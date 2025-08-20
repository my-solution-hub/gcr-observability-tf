# AWS China Observability Demo

This project demonstrates observability best practices for AWS China regions with a multi-tier application architecture.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                            Public Subnets                                   ││
│  │  ┌─────────────────┐                    ┌─────────────────┐                ││
│  │  │   ALB (Hello)   │                    │   ALB (World)   │                ││
│  │  │   Port 80       │                    │   Port 80       │                ││
│  │  └─────────────────┘                    └─────────────────┘                ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                           Private Subnets                                   ││
│  │                                                                             ││
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        ││
│  │  │ Hello Service   │    │ Hello Service   │    │ OpenTelemetry   │        ││
│  │  │ (Java Spring)   │    │ (Java Spring)   │    │   Collector     │        ││
│  │  │   Port 8080     │    │   Port 8080     │    │ Port 4317/4318  │        ││
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        ││
│  │           │                       │                       │                ││
│  │           └───────────┬───────────┘                       │                ││
│  │                       │                                   │                ││
│  │  ┌─────────────────┐  │  ┌─────────────────┐              │                ││
│  │  │ World Service   │  │  │ World Service   │              │                ││
│  │  │ (Python Flask)  │  │  │ (Python Flask)  │              │                ││
│  │  │   Port 5000     │  │  │   Port 5000     │              │                ││
│  │  └─────────────────┘  │  └─────────────────┘              │                ││
│  │           │            │           │                       │                ││
│  │           └────────────┼───────────┘                       │                ││
│  │                        │                                   │                ││
│  │  ┌─────────────────────┼─────────────────┐                 │                ││
│  │  │    ElastiCache      │                 │                 │                ││
│  │  │      Redis          │                 │                 │                ││
│  │  │    Port 6379        │                 │                 │                ││
│  │  └─────────────────────┼─────────────────┘                 │                ││
│  │                        │                                   │                ││
│  │  ┌─────────────────────┼─────────────────┐                 │                ││
│  │  │    RDS Aurora       │                 │                 │                ││
│  │  │      MySQL          │                 │                 │                ││
│  │  │    Port 3306        │                 │                 │                ││
│  │  └─────────────────────┼─────────────────┘                 │                ││
│  └─────────────────────────┼─────────────────────────────────────────────────────┘│
└─────────────────────────────┼─────────────────────────────────────────────────────┘
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
User → ALB (Hello) → Hello Service → Redis Cache
                                  ↓ (cache miss)
                                  World Service → MySQL Database
```

### Observability Flow

```text
Applications → OpenTelemetry Collector → AWS Services
             (traces/metrics/logs)      (X-Ray/CloudWatch/Logs)
```

## Infrastructure Components

### Application Tier

- **Hello Service (Java Spring Boot)**: Frontend service with web interface
  - Checks Redis cache first for performance
  - Calls World service on cache miss
  - Caches responses for 5 minutes
  - Exposes health check endpoint

- **World Service (Python Flask)**: Backend API service
  - Retrieves data from MySQL database
  - Initializes database with sample data on startup
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

- **Application Load Balancer (Hello)**: Routes traffic to Hello services
  - Health checks on port 8080
  - Cross-zone load balancing

- **Application Load Balancer (World)**: Routes traffic to World services
  - Health checks on port 5000
  - Internal load balancer for backend services

### Observability Stack

- **OpenTelemetry Collector**: Centralized telemetry collection
  - OTLP receivers (gRPC: 4317, HTTP: 4318)
  - Processes traces, metrics, and logs
  - Forwards to AWS observability services
  - IAM role with CloudWatch, X-Ray, and Logs permissions

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
   ./scripts/plan.sh dev cn-north-1
   ```

3. **Deploy infrastructure**:

   ```bash
   ./scripts/deploy.sh dev cn-north-1
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
./scripts/destroy.sh dev cn-north-1
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
