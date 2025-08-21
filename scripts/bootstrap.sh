#!/bin/bash

# Usage: ./scripts/bootstrap.sh <region> [profile]
# Example: ./scripts/bootstrap.sh cn-north-1
# Example: ./scripts/bootstrap.sh cn-north-1 cn

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <region> [profile]"
    echo "Example: $0 cn-north-1"
    echo "Example: $0 cn-north-1 cn"
    exit 1
fi

REGION=$1
PROFILE=$2

if [ -n "$PROFILE" ]; then
    export AWS_PROFILE=$PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    echo "Using AWS profile: $PROFILE"
fi

BUCKET_NAME="yagr-tfstate-log-cn"
TABLE_NAME="terraform-state-lock"

echo "Creating Terraform backend resources for region: $REGION"

# Create S3 bucket for state storage
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

# Enable versioning on the bucket
echo "Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "Enabling server-side encryption on S3 bucket"
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

# Wait for table to be active
echo "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION

echo "Bootstrap completed successfully!"
echo "You can now run terraform init with the backend configuration."
