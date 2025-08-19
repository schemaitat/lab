#!/bin/bash

set -e

echo "🌐 Getting NodeBalancer IP for DNS configuration..."
echo "================================================="

# Check if we're in terraform directory
if [ ! -f "terraform/main.tf" ]; then
    echo "❌ Error: Run this script from the project root directory"
    exit 1
fi

cd terraform

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Error: Terraform not initialized. Run 'task setup' first."
    exit 1
fi

# Get the NodeBalancer IP
NB_IP=$(tofu output -raw nodebalancer_ipv4 2>/dev/null || echo "")

if [ -z "$NB_IP" ]; then
    echo "❌ Error: NodeBalancer not found. Run 'task apply' first."
    exit 1
fi

echo "✅ NodeBalancer Configuration:"
echo "=============================="
echo "IPv4 Address: $NB_IP"
echo ""
echo "📋 DNS Configuration needed:"
echo "* Point lab.schemaitat.de to $NB_IP"
echo "* Or update your /etc/hosts file:"
echo "  echo '$NB_IP lab.schemaitat.de' | sudo tee -a /etc/hosts"
echo ""
echo "🔗 After DNS propagation, your services will be available at:"
echo "* https://lab.schemaitat.de/prometheus"
echo "* https://lab.schemaitat.de/hello"
echo "* https://lab.schemaitat.de/cost"