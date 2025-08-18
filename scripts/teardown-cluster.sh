#!/bin/bash

echo "🧹 Tearing down Kubernetes cluster..."
echo "===================================="

# Confirm destruction
read -p "⚠️  Are you sure you want to destroy the cluster? This action cannot be undone. (yes/no): " confirmation

if [[ $confirmation != "yes" ]]; then
    echo "❌ Teardown cancelled."
    exit 0
fi

echo "🗑️  Destroying infrastructure..."

# Run terraform destroy
cd terraform
tofu destroy -auto-approve
cd ..

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Teardown Complete!"
    echo "==================="
    echo "🗑️  All infrastructure has been destroyed"
    echo "💾 Terraform state files have been preserved for reference"
    echo ""
    echo "🧽 Clean up local files (optional):"
    echo "  rm kubeconfig.yaml"
    echo "  rm terraform/terraform.tfstate*"
    echo "  rm -rf terraform/.terraform/"
    echo ""
else
    echo "❌ Teardown failed. Please check the errors above."
    exit 1
fi