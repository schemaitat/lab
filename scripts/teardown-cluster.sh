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
    echo "✅ Terraform Teardown Complete!"
    echo "==============================="
    echo "🗑️  Terraform-managed infrastructure has been destroyed"
    echo ""
    
    echo "🔍 Checking for leftover Linode resources..."
    echo "==========================================="
    
    # Check for NodeBalancers
    echo "📊 NodeBalancers:"
    if command -v linode-cli &> /dev/null; then
        linode-cli nodebalancers list --text 2>/dev/null || echo "   No linode-cli found - check manually at https://cloud.linode.com/nodebalancers"
    else
        echo "   Install linode-cli to check automatically, or visit: https://cloud.linode.com/nodebalancers"
    fi
    echo ""
    
    # Check for Block Storage volumes
    echo "💾 Block Storage Volumes:"
    if command -v linode-cli &> /dev/null; then
        linode-cli volumes list --text 2>/dev/null || echo "   No linode-cli found - check manually at https://cloud.linode.com/volumes"
    else
        echo "   Install linode-cli to check automatically, or visit: https://cloud.linode.com/volumes"
    fi
    echo ""
    
    # Check for Firewalls
    echo "🔥 Firewalls:"
    if command -v linode-cli &> /dev/null; then
        linode-cli firewalls list --text 2>/dev/null || echo "   No linode-cli found - check manually at https://cloud.linode.com/firewalls"
    else
        echo "   Install linode-cli to check automatically, or visit: https://cloud.linode.com/firewalls"
    fi
    echo ""
    
    # Check for Load Balancers (if any were created by k8s services)
    echo "⚖️  Load Balancers (created by K8s services):"
    echo "   Check manually at: https://cloud.linode.com/nodebalancers"
    echo "   Look for LoadBalancers with names like 'lke-*' or matching your cluster"
    echo ""
    
    echo "⚠️  IMPORTANT: Manual cleanup required!"
    echo "======================================"
    echo "The following resources are NOT managed by Terraform and may still exist:"
    echo "• NodeBalancers created by Kubernetes LoadBalancer services"
    echo "• Block Storage volumes (PVCs)"
    echo "• Firewalls created by NetworkPolicies"
    echo "• DNS records pointing to the old cluster"
    echo ""
    echo "Please check your Linode account and clean up manually:"
    echo "🌐 https://cloud.linode.com"
    echo ""
    
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