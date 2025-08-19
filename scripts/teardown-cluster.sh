#!/bin/bash
#
# Enhanced teardown script for Linode LKE clusters
# - Destroys Terraform-managed infrastructure (cluster)
# - Automatically cleans up NodeBalancers created by LoadBalancer services
# - Lists remaining resources (volumes, firewalls) that need manual cleanup
# - Requires linode-cli for automatic NodeBalancer cleanup
#

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
    
    # Get cluster ID before cleaning up
    CLUSTER_ID=""
    if [ -f "terraform/terraform.tfstate.backup" ]; then
        CLUSTER_ID=$(grep -o '"id":"[0-9]*"' terraform/terraform.tfstate.backup | head -1 | cut -d'"' -f4)
    fi
    
    echo "🧹 Cleaning up Kubernetes-created resources..."
    echo "============================================="
    
    # Clean up NodeBalancers created by LoadBalancer services
    echo "📊 Cleaning up NodeBalancers..."
    if command -v linode-cli &> /dev/null; then
        # Get all NodeBalancers and check for cluster-related ones
        echo "   Searching for cluster NodeBalancers..."
        
        # List all NodeBalancers to find cluster-related ones
        NB_LIST=$(linode-cli nodebalancers list --text 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$NB_LIST" ]; then
            echo "   Found NodeBalancers:"
            echo "$NB_LIST" | head -1  # Header
            
            # Look for NodeBalancers with cluster-related labels or CCM naming
            CLUSTER_NBS=$(echo "$NB_LIST" | grep -E "(ccm-|lke-|$CLUSTER_ID)" || true)
            if [ -n "$CLUSTER_NBS" ]; then
                echo "$CLUSTER_NBS"
                echo ""
                echo "   🗑️  Deleting cluster NodeBalancers..."
                
                # Extract NodeBalancer IDs and delete them
                echo "$CLUSTER_NBS" | tail -n +2 | while read -r line; do
                    if [ -n "$line" ]; then
                        NB_ID=$(echo "$line" | awk '{print $1}')
                        NB_LABEL=$(echo "$line" | awk '{print $2}')
                        echo "     Deleting NodeBalancer: $NB_ID ($NB_LABEL)"
                        linode-cli nodebalancers delete $NB_ID 2>/dev/null || echo "     Failed to delete NodeBalancer $NB_ID"
                    fi
                done
                echo "   ✅ NodeBalancer cleanup completed"
            else
                echo "   No cluster-related NodeBalancers found"
            fi
        else
            echo "   Could not list NodeBalancers - check manually"
        fi
    else
        echo "   linode-cli not found - install it for automatic cleanup"
        echo "   Manual cleanup: https://cloud.linode.com/nodebalancers"
    fi
    echo ""
    
    echo "🔍 Checking for remaining leftover resources..."
    echo "============================================="
    
    # Check for remaining NodeBalancers
    echo "📊 Remaining NodeBalancers:"
    if command -v linode-cli &> /dev/null; then
        linode-cli nodebalancers list --text 2>/dev/null || echo "   Could not list NodeBalancers"
    else
        echo "   Install linode-cli to check automatically, or visit: https://cloud.linode.com/nodebalancers"
    fi
    echo ""
    
    # Check for Block Storage volumes
    echo "💾 Block Storage Volumes:"
    if command -v linode-cli &> /dev/null; then
        linode-cli volumes list --text 2>/dev/null || echo "   Could not list volumes"
    else
        echo "   Install linode-cli to check automatically, or visit: https://cloud.linode.com/volumes"
    fi
    echo ""
    
    # Check for Firewalls
    echo "🔥 Firewalls:"
    if command -v linode-cli &> /dev/null; then
        linode-cli firewalls list --text 2>/dev/null || echo "   Could not list firewalls"
    else
        echo "   Install linode-cli to check automatically, or visit: https://cloud.linode.com/firewalls"
    fi
    echo ""
    
    echo "⚠️  Manual cleanup may still be required for:"
    echo "==========================================="
    echo "• Block Storage volumes (PVCs) if any were created"
    echo "• Firewalls created by NetworkPolicies"
    echo "• DNS records pointing to the old cluster"
    echo ""
    echo "Check your Linode account: 🌐 https://cloud.linode.com"
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