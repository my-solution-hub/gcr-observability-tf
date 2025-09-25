#!/bin/bash

# Usage: ./scripts/deploy-k8s.sh [profile]
# Example: ./scripts/deploy-k8s.sh cn

PROFILE=$1

if [ -n "$PROFILE" ]; then
    export AWS_PROFILE=$PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    echo "Using AWS profile: $PROFILE"
fi

echo "Deploying Kubernetes manifests..."

# Get values from Terraform outputs
cd tf
export HELLO_ECR_URL=$(terraform output -raw hello_service_ecr_repository_url)
export WORLD_ECR_URL=$(terraform output -raw world_service_ecr_repository_url)
export TRAFFIC_ECR_URL=$(terraform output -raw traffic_generator_ecr_repository_url)
export REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint)
export RDS_ENDPOINT=$(terraform output -raw rds_cluster_endpoint)
export OTEL_COLLECTOR_ROLE_ARN=$(terraform output -raw otel_collector_role_arn)
export AWS_REGION=$(terraform output -raw hello_service_ecr_repository_url | cut -d'.' -f4)

# Set region-specific AWS endpoints and container images
if [[ "$AWS_REGION" == cn-* ]]; then
    # China regions - use China-accessible registry
    export AWS_STS_ENDPOINT="https://sts.${AWS_REGION}.amazonaws.com.cn"
    export AWS_XRAY_ENDPOINT="https://xray.${AWS_REGION}.amazonaws.com.cn"
    export AWS_CLOUDWATCH_ENDPOINT="https://monitoring.${AWS_REGION}.amazonaws.com.cn"
    export AWS_LOGS_ENDPOINT="https://logs.${AWS_REGION}.amazonaws.com.cn"
    export OTEL_COLLECTOR_IMAGE="docker.1ms.run/otel/opentelemetry-collector-contrib:0.132.0"
else
    # Standard regions - use Docker Hub
    export AWS_STS_ENDPOINT="https://sts.${AWS_REGION}.amazonaws.com"
    export AWS_XRAY_ENDPOINT="https://xray.${AWS_REGION}.amazonaws.com"
    export AWS_CLOUDWATCH_ENDPOINT="https://monitoring.${AWS_REGION}.amazonaws.com"
    export AWS_LOGS_ENDPOINT="https://logs.${AWS_REGION}.amazonaws.com"
    export OTEL_COLLECTOR_IMAGE="otel/opentelemetry-collector-contrib:0.132.0"
fi

cd ..

echo "Using values:"
echo "  Hello ECR: $HELLO_ECR_URL"
echo "  World ECR: $WORLD_ECR_URL"
echo "  Traffic ECR: $TRAFFIC_ECR_URL"
echo "  Redis: $REDIS_ENDPOINT"
echo "  RDS: $RDS_ENDPOINT"
echo "  OTEL Role: $OTEL_COLLECTOR_ROLE_ARN"
echo "  Region: $AWS_REGION"
echo "  STS Endpoint: $AWS_STS_ENDPOINT"
echo "  X-Ray Endpoint: $AWS_XRAY_ENDPOINT"
echo "  CloudWatch Endpoint: $AWS_CLOUDWATCH_ENDPOINT"
echo "  Logs Endpoint: $AWS_LOGS_ENDPOINT"

# Apply manifests using envsubst
echo "Applying OpenTelemetry Collector..."
envsubst < k8s/otel-collector.yaml | kubectl apply -f -

echo "Applying World Service..."
envsubst < k8s/world-deployment.yaml | kubectl apply -f -

echo "Applying Hello Service..."
envsubst < k8s/hello-deployment.yaml | kubectl apply -f -

echo "Applying Traffic Generator..."
envsubst < k8s/traffic-generator-deployment.yaml | kubectl apply -f -

echo "Applying Ingress..."
envsubst < k8s/ingress.yaml | kubectl apply -f -

echo "Kubernetes deployment completed!"
echo "Check status with: kubectl get pods"
echo "Check ingress with: kubectl get ingress"
