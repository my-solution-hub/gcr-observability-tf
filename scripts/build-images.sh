#!/bin/bash

# Usage: ./scripts/build-images.sh [tag] [push] [profile]
# Example: ./scripts/build-images.sh latest
# Example: ./scripts/build-images.sh latest push
# Example: ./scripts/build-images.sh latest push cn

TAG=${1:-latest}
PUSH=${2}
PROFILE=${3}

echo "Building Docker images with tag: $TAG"

# Get ECR repository URLs from Terraform outputs
cd tf
if [ -n "$PROFILE" ]; then
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    export AWS_PROFILE=$PROFILE
    echo "Using AWS profile: $PROFILE"
fi
HELLO_ECR_URL=$(terraform output -raw hello_service_ecr_repository_url 2>/dev/null)
WORLD_ECR_URL=$(terraform output -raw world_service_ecr_repository_url 2>/dev/null)
TRAFFIC_ECR_URL=$(terraform output -raw traffic_generator_ecr_repository_url 2>/dev/null)
echo "Hello Service ECR URL: $HELLO_ECR_URL"
echo "World Service ECR URL: $WORLD_ECR_URL"
echo "Traffic Generator ECR URL: $TRAFFIC_ECR_URL"
cd ..

# Build Java Spring Boot hello app
echo "Building hello-service..."
cd app/hello
mvn clean package -DskipTests
docker build --platform linux/amd64 -t hello-service:$TAG .
if [ -n "$HELLO_ECR_URL" ]; then
    docker tag hello-service:$TAG $HELLO_ECR_URL:$TAG
fi
cd ../..

# Build Python Flask world app  
echo "Building world-service..."
cd app/world
docker build --platform linux/amd64 -t world-service:$TAG .
if [ -n "$WORLD_ECR_URL" ]; then
    docker tag world-service:$TAG $WORLD_ECR_URL:$TAG
fi
cd ../..

# Build traffic generator
echo "Building traffic-generator..."
cd app/traffic-generator
docker build --platform linux/amd64 -t traffic-generator:$TAG .
if [ -n "$TRAFFIC_ECR_URL" ]; then
    docker tag traffic-generator:$TAG $TRAFFIC_ECR_URL:$TAG
fi
cd ../..

echo "Docker images built successfully:"
docker images | grep -E "(hello-service|world-service|traffic-generator)"

# Push to ECR if requested
if [ "$PUSH" = "push" ]; then
    echo "Pushing images to ECR..."
    
    # Get AWS region and account ID
    REGION=$(echo $HELLO_ECR_URL | cut -d'.' -f4)
    
    # Login to ECR
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $HELLO_ECR_URL
    
    # Push images that have ECR URLs
    if [ -n "$HELLO_ECR_URL" ]; then
        docker push $HELLO_ECR_URL:$TAG
    fi
    if [ -n "$WORLD_ECR_URL" ]; then
        docker push $WORLD_ECR_URL:$TAG
    fi
    if [ -n "$TRAFFIC_ECR_URL" ]; then
        docker push $TRAFFIC_ECR_URL:$TAG
    fi
    
    echo "Images pushed to ECR successfully!"
fi
