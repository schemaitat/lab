#!/bin/bash

set -e

echo "🚀 Setting up Kubernetes cluster on Linode..."
echo "=============================================="

# Check if terraform.tfvars exists
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo "❌ Error: terraform/terraform.tfvars not found"
    echo "Please copy terraform/terraform.tfvars.example to terraform/terraform.tfvars and configure your settings"
    exit 1
fi

# Initialize OpenTofu
echo "📦 Initializing OpenTofu..."
cd terraform
tofu init

# Apply configuration
echo "🏗️  Creating infrastructure..."
tofu apply -auto-approve
cd ..

# Extract kubeconfig
echo "📋 Extracting kubeconfig..."
cd terraform
tofu output -raw kubeconfig | base64 -d > ../kubeconfig.yaml
cd ..
export KUBECONFIG=./kubeconfig.yaml

# Wait a moment for cluster to be fully ready
echo "⏳ Waiting for cluster to be fully ready..."
sleep 10

# NodeBalancer nodes will be configured manually after setup
echo "📝 Note: Configure NodeBalancer nodes manually using 'task nodebalancer-ip'"

# Check cluster status
echo ""
echo "✅ Cluster Setup Complete!"
echo "=========================="

# Display cluster information
echo "📊 Cluster Information:"
echo "----------------------"
echo "Cluster ID: $(cd terraform && tofu output -raw cluster_id)"
echo "Status: $(cd terraform && tofu output -raw cluster_status)"
echo "API Endpoints:"
cd terraform && tofu output api_endpoints | grep -o 'https://[^"]*'
cd ..

echo ""
echo "🖥️  Node Status:"
echo "---------------"
kubectl get nodes

echo ""
echo "🔧 System Pods:"
echo "---------------"
kubectl get pods -n kube-system

echo ""
echo "📝 Usage Instructions:"
echo "====================="
echo "To use this cluster, run:"
echo "  export KUBECONFIG=./kubeconfig.yaml"
echo ""
echo "Common commands:"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get services"
echo ""
echo ""
echo "🎉 Your Kubernetes cluster is ready!"