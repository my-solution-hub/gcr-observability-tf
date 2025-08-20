#!/bin/bash

# Usage: ./scripts/destroy.sh <environment> <region> [profile]
# Example: ./scripts/destroy.sh dev cn-north-1
# Example: ./scripts/destroy.sh dev cn-northwest-1 cn

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <environment> <region> [profile]"
    echo "Example: $0 dev cn-north-1"
    echo "Example: $0 dev cn-northwest-1 cn"
    exit 1
fi

ENVIRONMENT=$1
REGION=$2
PROFILE=$3

export TF_VAR_environment=$ENVIRONMENT
export TF_VAR_aws_region=$REGION

if [ -n "$PROFILE" ]; then
    export AWS_PROFILE=$PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    echo "Destroying $ENVIRONMENT environment in $REGION region using profile $PROFILE..."
else
    echo "Destroying $ENVIRONMENT environment in $REGION region..."
fi

echo "This will delete all resources in $ENVIRONMENT environment in $REGION region."
echo "Are you sure? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # Initialize with correct backend
    ./scripts/init.sh $REGION $PROFILE
    
    cd tf
    
    terraform destroy \
        -var-file=environments/${ENVIRONMENT}/${REGION}.tfvars \
        -auto-approve
else
    echo "Destroy cancelled."
fi
