#!/bin/bash

set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./plan.sh <dev|staging|prod>"
  exit 1
fi

echo "📘 Running Terraform PLAN for environment: $ENV"

cd "$(dirname "$0")/../envs/$ENV"

terraform init
terraform plan -var="env=$1"
