#!/bin/bash

set -e

echo "🔗 Configuring NodeBalancer nodes for ingress traffic..."
echo "======================================================"

# Check if terraform is initialized  
if [ ! -d "terraform/.terraform" ]; then
    echo "❌ Error: Terraform not initialized. Run 'task setup' first."
    exit 1
fi

# Get NodeBalancer information
cd terraform
NB_ID=$(tofu output -raw nodebalancer_id 2>/dev/null || echo "")
NB_IP=$(tofu output -raw nodebalancer_ipv4 2>/dev/null || echo "")

if [ -z "$NB_ID" ] || [ -z "$NB_IP" ]; then
    echo "❌ Error: NodeBalancer not found. Run 'task setup' first."
    exit 1
fi

echo "NodeBalancer ID: $NB_ID"
echo "NodeBalancer IP: $NB_IP"
echo ""

# Get cluster node IPs using kubectl
cd ..
export KUBECONFIG=./kubeconfig.yaml

if [ ! -f "./kubeconfig.yaml" ]; then
    echo "❌ Error: kubeconfig.yaml not found. Run 'task setup' first."
    exit 1
fi

echo "📋 Getting cluster node IPs..."
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')

if [ -z "$NODE_IPS" ]; then
    echo "❌ Error: Could not get node IPs. Cluster may not be ready yet."
    exit 1
fi

echo "Node IPs: $NODE_IPS"
echo ""

echo "⚠️  Manual NodeBalancer configuration required:"
echo "=============================================="
echo ""
echo "Go to Linode Cloud Manager > NodeBalancers > $NB_ID"
echo ""
echo "For port 80 configuration:"
for ip in $NODE_IPS; do
    echo "  Add node: $ip:30080 (weight: 100)"
done
echo ""
echo "For port 443 configuration:"
for ip in $NODE_IPS; do
    echo "  Add node: $ip:30443 (weight: 100)"
done
echo ""
echo "🌐 DNS Configuration:"
echo "Point lab.schemaitat.de to $NB_IP"
echo ""
echo "Or temporarily add to /etc/hosts:"
echo "echo '$NB_IP lab.schemaitat.de' | sudo tee -a /etc/hosts"