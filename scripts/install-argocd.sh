#!/bin/bash

set -e

echo "🚀 Installing ArgoCD with App of Apps pattern..."
echo "=============================================="

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Error: kubectl is not configured or cluster is not accessible"
    echo "💡 Run 'task setup' first to create the cluster"
    exit 1
fi

# Check if kubeconfig.yaml exists
if [ ! -f "kubeconfig.yaml" ]; then
    echo "❌ Error: kubeconfig.yaml not found"
    echo "💡 Run 'task setup' first to create the cluster and generate kubeconfig"
    exit 1
fi

export KUBECONFIG=./kubeconfig.yaml

echo "📦 Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "📥 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

echo "🔐 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "📝 Creating ArgoCD configuration..."

# Create the root App of Apps application
kubectl apply -f argocd/bootstrap/root-app.yaml

echo "🎯 Setting up port forwarding to ArgoCD UI..."
echo ""
echo "✅ ArgoCD Installation Complete!"
echo "================================"
echo ""
echo "🌐 ArgoCD UI Access:"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "🚀 To access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "📱 ArgoCD CLI setup:"
echo "   # Install ArgoCD CLI"
echo "   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo ""
echo "   # Login via CLI"
echo "   argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure"
echo ""
echo "🎉 App of Apps pattern is now active!"
echo "   - Check argocd/apps/ directory to add new applications"
echo "   - All applications will be automatically synced by ArgoCD"
echo ""

# Optional: Start port forwarding in background
read -p "🔗 Start port forwarding to ArgoCD UI now? (y/n): " start_port_forward
if [[ $start_port_forward == "y" || $start_port_forward == "Y" ]]; then
    echo "🌐 Starting port forwarding..."
    echo "   Access ArgoCD at: https://localhost:8080"
    echo "   Press Ctrl+C to stop"
    kubectl port-forward svc/argocd-server -n argocd 8080:443
fi