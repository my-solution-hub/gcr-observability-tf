#!/bin/bash

# Usage: ./scripts/validate.sh
# Validates Terraform configuration

echo "Validating Terraform configuration..."

cd tf

terraform fmt -check
if [ $? -ne 0 ]; then
    echo "Terraform formatting issues found. Run 'terraform fmt' to fix."
    exit 1
fi

terraform validate
if [ $? -ne 0 ]; then
    echo "Terraform validation failed."
    exit 1
fi

echo "Terraform configuration is valid."
