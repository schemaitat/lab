# ArgoCD App of Apps Pattern Setup

This guide explains how to use ArgoCD with the App of Apps pattern for automated application deployment on your Linode Kubernetes cluster.

## 🎯 What is App of Apps?

The App of Apps pattern is a GitOps approach where:
- **One root application** manages multiple child applications
- **All apps are defined in Git** and automatically deployed
- **Changes to Git** trigger automatic updates
- **Declarative management** of your entire application stack

## 🏗️ Architecture Overview

```
Root App (app-of-apps)
├── System Apps
│   ├── NGINX Ingress Controller
│   ├── Cert-Manager (SSL certificates)
│   └── Monitoring Stack (Prometheus)
└── Demo Apps
    ├── Hello World (sample application)
    └── Cost Dashboard (Linode cost monitoring)
```

## 🚀 Quick Start

### 1. Complete Setup (Recommended)
```bash
# Creates cluster + installs ArgoCD + deploys all apps
task setup-complete
```

### 2. Step-by-Step Setup
```bash
# 1. Create the cluster first
task setup

# 2. Install ArgoCD with App of Apps
task install-argocd

# 3. Access ArgoCD UI
task argocd-ui
```

## 🌐 Accessing ArgoCD

### Web UI Access
```bash
# Start port forwarding
task argocd-ui

# Open browser to: https://localhost:8080
# Username: admin
# Password: (shown in terminal)
```

### CLI Access
```bash
# Install ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd /usr/local/bin/argocd

# Login
argocd login localhost:8080 --username admin --insecure
```

## 📁 Directory Structure

```
argocd/
├── bootstrap/
│   └── root-app.yaml          # Root App of Apps application
├── apps/
│   ├── system-apps.yaml       # System applications (ingress, certs, monitoring)
│   └── demo-apps.yaml         # Demo applications
└── system/
    ├── hello-world/           # Sample web application
    ├── cost-dashboard/        # Linode cost monitoring
    └── monitoring/            # Prometheus stack
```

## 🛠️ Deployed Applications

### System Applications (Infrastructure)

#### NGINX Ingress Controller
- **Purpose:** Load balancer and ingress for external access
- **Namespace:** `ingress-nginx`
- **Resources:** Optimized for 1GB nodes
- **LoadBalancer:** Uses Linode NodeBalancer

#### Cert-Manager  
- **Purpose:** Automatic SSL certificate management
- **Namespace:** `cert-manager`
- **Features:** Let's Encrypt integration
- **Resources:** Minimal resource requests

#### Monitoring Stack
- **Purpose:** Basic cluster monitoring
- **Namespace:** `monitoring`
- **Components:** Lightweight Prometheus setup
- **Retention:** 7 days (suitable for development)

### Demo Applications

#### Hello World
- **Purpose:** Sample application showcase
- **Namespace:** `demo`
- **Features:** 
  - Shows cluster information
  - Cost optimization details
  - Nginx-based with custom content
- **Access:** Via ingress (configure domain)

#### Cost Dashboard
- **Purpose:** Linode cost monitoring
- **Namespace:** `cost-monitoring`
- **Features:**
  - Cost tracking CronJob (every 4 hours)
  - Web dashboard with cost metrics
  - Optimization recommendations
- **Access:** Via port-forward or ingress

## 🎛️ Managing Applications

### Adding New Applications

1. **Create application manifest:**
```yaml
# argocd/apps/my-new-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/iac
    targetRevision: HEAD
    path: argocd/system/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

2. **Create application resources:**
```bash
mkdir -p argocd/system/my-app
# Add your Kubernetes manifests here
```

3. **Commit and push:**
```bash
git add argocd/
git commit -m "Add my-app application"
git push
```

4. **ArgoCD automatically deploys** the new application!

### Removing Applications

1. **Delete the application manifest:**
```bash
rm argocd/apps/my-app.yaml
```

2. **Commit and push:**
```bash
git commit -am "Remove my-app"
git push
```

3. **ArgoCD automatically removes** the application and all resources!

## 🔧 Configuration

### Repository URL
Update the repository URL in all application manifests:
```yaml
# Replace in all files:
repoURL: https://github.com/yourusername/iac
```

### Domains and Ingress
Update domains in ingress manifests:
```yaml
# argocd/system/hello-world/deployment.yaml
spec:
  tls:
  - hosts:
    - hello.your-domain.com  # Replace with your domain
  rules:
  - host: hello.your-domain.com  # Replace with your domain
```

### Resource Limits
All applications are configured with minimal resources for 1GB nodes:
```yaml
resources:
  requests:
    cpu: 10m
    memory: 32Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

## 📊 Monitoring and Observability

### ArgoCD Application Status
```bash
# Check all applications
argocd app list

# Get application details
argocd app get hello-world

# View application logs
argocd app logs hello-world
```

### Kubernetes Resources
```bash
# Check all namespaces
kubectl get namespaces

# Check pods across all namespaces
kubectl get pods -A

# Check ingress status
kubectl get ingress -A
```

### Cost Monitoring
```bash
# Check cost monitoring CronJob
kubectl get cronjobs -n cost-monitoring

# View cost monitoring logs
kubectl logs -n cost-monitoring -l app=cost-monitoring
```

## 🚨 Troubleshooting

### ArgoCD Not Syncing
```bash
# Check ArgoCD controller logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force refresh
argocd app sync app-of-apps
```

### Application Stuck in Progressing
```bash
# Check application events
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp

# Check pod status
kubectl describe pods -n <namespace>
```

### Resource Constraints (1GB nodes)
```bash
# Check node resource usage
kubectl top nodes

# Check pod resource usage
kubectl top pods -A

# Check for pending pods
kubectl get pods -A | grep Pending
```

### Common Issues

#### Out of Memory
- **Symptom:** Pods being OOMKilled
- **Solution:** Reduce resource requests or scale horizontally

#### ImagePullBackOff
- **Symptom:** Cannot pull container images
- **Solution:** Check image names and registry access

#### Ingress Not Working
- **Symptom:** External access fails
- **Solution:** Check LoadBalancer service and DNS configuration

## 🎯 Best Practices

### Resource Management
- **Start small:** Use minimal resource requests
- **Monitor usage:** Watch for memory pressure
- **Scale horizontally:** Add more pods rather than bigger pods

### GitOps Workflow
- **Small commits:** Make incremental changes
- **Test locally:** Use `kubectl apply` to test before committing
- **Monitor deployments:** Watch ArgoCD for sync status

### Security
- **Namespaces:** Isolate applications in separate namespaces
- **RBAC:** Use proper role-based access control
- **Secrets:** Use external-secrets or sealed-secrets for sensitive data

## 💰 Cost Optimization

### Current Setup Costs
- **Cluster:** ~$15/month (3x g6-nanode-1)
- **LoadBalancer:** ~$10/month (for ingress)
- **Total:** ~$25/month

### Optimization Tips
- **Development:** Shut down cluster when not in use
- **Resources:** Keep resource requests minimal
- **Monitoring:** Use cost dashboard to track usage
- **Scaling:** Scale applications, not nodes

## 🔄 Updating Applications

### Automatic Updates
ArgoCD monitors your Git repository and automatically:
- **Syncs changes** within 3 minutes
- **Prunes deleted resources**
- **Self-heals** configuration drift

### Manual Sync
```bash
# Sync specific application
argocd app sync hello-world

# Sync all applications
argocd app sync app-of-apps
```

## 🎉 Next Steps

1. **Customize applications** for your needs
2. **Add your own applications** using the pattern
3. **Configure monitoring** and alerting
4. **Set up CI/CD pipelines** to update application images
5. **Implement proper secrets management**

---

*The App of Apps pattern provides a scalable, maintainable way to manage all your Kubernetes applications through GitOps. Everything is automated, versioned, and recoverable!*