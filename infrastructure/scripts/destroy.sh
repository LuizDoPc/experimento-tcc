#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found. Please create it from terraform.tfvars.example"
    exit 1
fi

echo "Destroying infrastructure..."
terraform destroy -auto-approve

echo "Infrastructure destroyed successfully!"