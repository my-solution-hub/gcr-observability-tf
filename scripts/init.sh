#!/bin/bash

# Usage: ./scripts/init.sh [region] [profile]
# Example: ./scripts/init.sh cn-north-1
# Example: ./scripts/init.sh ap-southeast-1

REGION=$1
PROFILE=$2

if [ -z "$REGION" ]; then
    echo "Usage: $0 <region> [profile]"
    echo "Example: $0 cn-north-1"
    echo "Example: $0 ap-southeast-1"
    exit 1
fi

if [ -n "$PROFILE" ]; then
    export AWS_PROFILE=$PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    echo "Using AWS profile: $PROFILE"
fi

cd tf

if [[ "$REGION" == cn-* ]]; then
    echo "Initializing Terraform with China backend for region $REGION..."
    terraform init -backend-config=backend-configs/${REGION}.hcl --reconfigure
elif [[ "$REGION" == ap-southeast-1 ]]; then
    echo "Initializing Terraform with Singapore backend for region $REGION..."
    terraform init -backend-config=backend-configs/${REGION}.hcl --reconfigure
else
    echo "Region $REGION is not supported. Supported regions: cn-north-1, cn-northwest-1, ap-southeast-1"
    exit 1
fi

