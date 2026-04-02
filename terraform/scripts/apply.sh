#!/bin/bash

set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./apply.sh <dev|staging|prod>"
  exit 1
fi

echo "🚀 Applying Terraform for environment: $ENV"

cd "$(dirname "$0")/../envs/$ENV"

terraform init
terraform apply -auto-approve -var="env=$1"
