#!/bin/bash

# Usage: ./scripts/deploy-k8s.sh [profile]
# Example: ./scripts/deploy-k8s.sh cn

PROFILE=$1

if [ -n "$PROFILE" ]; then
    export AWS_PROFILE=$PROFILE
    echo "Using AWS profile: $PROFILE"
fi

echo "Deploying Kubernetes manifests..."

# Get values from Terraform outputs
cd tf
HELLO_ECR_URL=$(terraform output -raw hello_service_ecr_repository_url)
WORLD_ECR_URL=$(terraform output -raw world_service_ecr_repository_url)
REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint)
RDS_ENDPOINT=$(terraform output -raw rds_cluster_endpoint)
OTEL_ROLE_ARN=$(terraform output -raw otel_collector_role_arn)
AWS_REGION=$(terraform output -raw vpc_id | cut -d':' -f4)
cd ..

echo "Using values:"
echo "  Hello ECR: $HELLO_ECR_URL"
echo "  World ECR: $WORLD_ECR_URL"
echo "  Redis: $REDIS_ENDPOINT"
echo "  RDS: $RDS_ENDPOINT"
echo "  OTEL Role: $OTEL_ROLE_ARN"
echo "  Region: $AWS_REGION"

# Create temporary directory for processed manifests
mkdir -p tmp

# Process hello deployment
sed -e "s|HELLO_ECR_URL|$HELLO_ECR_URL|g" \
    -e "s|REDIS_ENDPOINT|$REDIS_ENDPOINT|g" \
    k8s/hello-deployment.yaml > tmp/hello-deployment.yaml

# Process world deployment
sed -e "s|WORLD_ECR_URL|$WORLD_ECR_URL|g" \
    -e "s|RDS_ENDPOINT|$RDS_ENDPOINT|g" \
    k8s/world-deployment.yaml > tmp/world-deployment.yaml

# Process otel collector
sed -e "s|OTEL_COLLECTOR_ROLE_ARN|$OTEL_ROLE_ARN|g" \
    -e "s|AWS_REGION|$AWS_REGION|g" \
    k8s/otel-collector.yaml > tmp/otel-collector.yaml

# Apply manifests
echo "Applying OpenTelemetry Collector..."
kubectl apply -f tmp/otel-collector.yaml

echo "Applying World Service..."
kubectl apply -f tmp/world-deployment.yaml

echo "Applying Hello Service..."
kubectl apply -f tmp/hello-deployment.yaml

# Clean up
rm -rf tmp

echo "Kubernetes deployment completed!"
echo "Check status with: kubectl get pods"
