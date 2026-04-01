#!/bin/bash

# Exit on any error
set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./validate.sh <dev|staging|prod>"
  exit 1
fi

echo "✅ Validating Terraform for environment: $ENV"

cd "$(dirname "$0")/../envs/$ENV"

# Format check
echo "🔍 Checking Terraform formatting..."
terraform fmt -check

# Init in backend-only mode (safe)
echo "🔧 Initializing Terraform (backend-only)..."
terraform init -backend=false

# Validate
echo "🧪 Running Terraform validate..."
terraform validate

echo "✅ Validation complete for environment: $ENV"
