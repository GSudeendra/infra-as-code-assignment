#!/bin/bash

# Export all Terraform outputs to a JSON file for dynamic test and CI/CD configuration
set -e

cd "$(dirname "$0")/../../infra"
terraform output -json > infra_outputs.json

echo "[INFO] Exported Terraform outputs to infra/infra_outputs.json" 