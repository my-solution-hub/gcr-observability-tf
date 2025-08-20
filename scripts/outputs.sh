#!/bin/bash

# Usage: ./scripts/outputs.sh [profile]
# Example: ./scripts/outputs.sh
# Example: ./scripts/outputs.sh cn

PROFILE=$1

if [ -n "$PROFILE" ]; then
    export AWS_PROFILE=$PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    echo "Using AWS profile: $PROFILE"
fi

cd tf

echo "Terraform Outputs:"
echo "=================="
terraform output
