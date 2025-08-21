#!/bin/bash

# Usage: ./scripts/build-images.sh [tag] [push]
# Example: ./scripts/build-images.sh v1.0.0
# Example: ./scripts/build-images.sh v1.0.0 push

TAG=${1:-latest}
PUSH=${2}

echo "Building Docker images with tag: $TAG"

# Get ECR repository URLs from Terraform outputs
cd tf
HELLO_ECR_URL=$(terraform output -raw hello_service_ecr_repository_url 2>/dev/null)
WORLD_ECR_URL=$(terraform output -raw world_service_ecr_repository_url 2>/dev/null)
cd ..

# Build Java Spring Boot hello app
echo "Building hello-service..."
cd app/hello
mvn clean package -DskipTests
docker build -t hello-service:$TAG .
if [ -n "$HELLO_ECR_URL" ]; then
    docker tag hello-service:$TAG $HELLO_ECR_URL:$TAG
fi
cd ../..

# Build Python Flask world app  
echo "Building world-service..."
cd app/world
docker build -t world-service:$TAG .
if [ -n "$WORLD_ECR_URL" ]; then
    docker tag world-service:$TAG $WORLD_ECR_URL:$TAG
fi
cd ../..

echo "Docker images built successfully:"
docker images | grep -E "(hello-service|world-service)"

# Push to ECR if requested
if [ "$PUSH" = "push" ] && [ -n "$HELLO_ECR_URL" ] && [ -n "$WORLD_ECR_URL" ]; then
    echo "Pushing images to ECR..."
    
    # Get AWS region and account ID
    REGION=$(echo $HELLO_ECR_URL | cut -d'.' -f4)
    
    # Login to ECR
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $HELLO_ECR_URL
    
    # Push images
    docker push $HELLO_ECR_URL:$TAG
    docker push $WORLD_ECR_URL:$TAG
    
    echo "Images pushed to ECR successfully!"
fi
