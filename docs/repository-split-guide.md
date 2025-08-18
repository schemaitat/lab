# Repository Split Guide

This guide explains how to split your IaC and ArgoCD code into separate repositories for better organization and team workflows.

## 🎯 Current vs Recommended Structure

### Current: Monolithic Repository
```
iac/ (single repo)
├── terraform/          # Infrastructure as Code
├── scripts/            # Automation scripts
├── argocd/             # Application definitions
├── reports/            # Billing reports
└── docs/               # Documentation
```

### Recommended: Split Repositories

#### Infrastructure Repository (`iac`)
```
iac/
├── terraform/                    # Cluster infrastructure
├── scripts/                      # Setup automation  
├── bootstrap/                    # ArgoCD installation
│   ├── argocd-install.yaml      # ArgoCD core installation
│   └── bootstrap-app.yaml       # Points to apps repo
├── reports/                      # Cost reports
└── docs/                        # Infrastructure docs
```

#### Applications Repository (`k8s-apps`)
```
k8s-apps/
├── apps/                        # App of Apps definitions
│   ├── production/              # Production applications
│   ├── staging/                 # Staging applications
│   └── development/             # Development applications
├── base/                        # Base application manifests
│   ├── nginx-ingress/
│   ├── cert-manager/
│   ├── monitoring/
│   └── cost-dashboard/
├── overlays/                    # Environment-specific overlays
│   ├── production/
│   ├── staging/
│   └── development/
└── charts/                      # Custom Helm charts
```

## 🔧 Implementation Steps

### Step 1: Create New Applications Repository

```bash
# Create new repository for applications
mkdir k8s-apps
cd k8s-apps
git init
git remote add origin https://github.com/yourusername/k8s-apps.git

# Set up directory structure
mkdir -p {apps/{production,staging,development},base,overlays/{production,staging,development},charts}
```

### Step 2: Move Application Code

```bash
# Move ArgoCD application definitions
mv ../iac/argocd/apps/* apps/production/
mv ../iac/argocd/system/* base/

# Create environment-specific overlays
# (We'll show examples below)
```

### Step 3: Update Infrastructure Repository

Keep only infrastructure-related code:
- Terraform configurations
- Setup/teardown scripts  
- ArgoCD installation (bootstrap only)
- Cost monitoring and reports

### Step 4: Create Bootstrap Application

The infrastructure repo installs ArgoCD and creates a bootstrap app that points to the applications repository.

## 📁 Detailed Structure Examples

### Infrastructure Repository (iac)

#### `bootstrap/argocd-install.yaml`
```yaml
# ArgoCD installation via Helm or manifests
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
---
# ArgoCD installation manifests...
```

#### `bootstrap/bootstrap-app.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/k8s-apps
    targetRevision: HEAD
    path: apps/production  # or staging/development
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Applications Repository (k8s-apps)

#### `apps/production/system-apps.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-ingress
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/k8s-apps
    targetRevision: HEAD
    path: overlays/production/nginx-ingress
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### `base/nginx-ingress/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: nginx-ingress
  managed-by: argocd
```

#### `overlays/production/nginx-ingress/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../base/nginx-ingress

patchesStrategicMerge:
  - replica-count.yaml
  - resource-limits.yaml

namespace: ingress-nginx
```

## 🚀 Migration Steps

### Phase 1: Set Up New Repository
1. Create `k8s-apps` repository
2. Move application manifests
3. Create base and overlay structure
4. Test applications in isolation

### Phase 2: Update Infrastructure
1. Remove application code from `iac` repo
2. Create bootstrap application
3. Update installation scripts
4. Test bootstrap process

### Phase 3: Environment Configuration
1. Create environment-specific overlays
2. Set up promotion workflows
3. Configure access controls
4. Test multi-environment deployments

## 🎛️ Environment Management

### Development Environment
```yaml
# overlays/development/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - resource-limits-dev.yaml

# Smaller resource limits for development
patches:
  - target:
      kind: Deployment
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
```

### Production Environment
```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - resource-limits-prod.yaml
  - monitoring-config.yaml

# Production-specific configurations
```

## 🔐 Access Control Strategy

### Infrastructure Repository
- **Limited access:** Infrastructure/Platform team only
- **Sensitive:** Contains cluster credentials, infrastructure secrets
- **Change frequency:** Low (cluster changes are infrequent)

### Applications Repository  
- **Broader access:** Development teams, DevOps engineers
- **Application focus:** Application manifests, configurations
- **Change frequency:** High (frequent application deployments)

### Branch Protection
```yaml
# .github/branch-protection.yml (both repos)
main:
  required_status_checks:
    contexts: ["ci/tests", "security/scan"]
  required_pull_request_reviews:
    required_approving_review_count: 1
  restrictions:
    teams: ["platform-team"]  # For infrastructure
    teams: ["dev-team", "platform-team"]  # For applications
```

## 🔄 Workflow Examples

### Infrastructure Changes
```bash
# iac repository
git checkout -b add-new-cluster
# Modify terraform configurations
git commit -m "Add staging cluster configuration"
# Create PR, get approval, merge
# Deploy: task setup-staging
```

### Application Changes
```bash
# k8s-apps repository  
git checkout -b update-nginx-config
# Modify base/nginx-ingress/configmap.yaml
git commit -m "Update nginx configuration"
# Create PR, get approval, merge
# ArgoCD automatically deploys changes
```

### Environment Promotion
```bash
# k8s-apps repository
git checkout -b promote-to-production
# Update overlays/production/ with tested configurations
git commit -m "Promote feature X to production"
# Create PR, get approval, merge
# ArgoCD syncs production environment
```

## 📊 Benefits Summary

| Aspect | Monolithic | Split Repositories |
|--------|------------|-------------------|
| **Team Access** | Everyone has full access | Granular permissions |
| **Change Blast Radius** | Large (infra + apps) | Small (focused changes) |
| **Release Cycles** | Coupled | Independent |
| **Git History** | Mixed concerns | Clean separation |
| **CI/CD Complexity** | Simple | More complex setup |
| **Onboarding** | Single repo to learn | Clear boundaries |

## 🎯 Recommendations

### For Small Teams (1-3 people)
**Keep monolithic structure** - The overhead of split repos isn't worth it yet.

### For Growing Teams (4-10 people)
**Start planning the split** - Set up structure but don't enforce strict boundaries yet.

### For Larger Teams (10+ people)
**Implement split repositories** - Essential for team productivity and security.

### For Your Current Setup
Given you're optimizing for cost and likely in early stages, I'd recommend:

1. **Keep current structure** for now
2. **Organize within the monolithic repo** using clear directory boundaries
3. **Plan for future split** when team grows
4. **Use branch protection** and proper review processes

## 🛠️ Current Repository Optimization

Instead of splitting immediately, let's optimize your current structure:

```
iac/
├── terraform/              # Infrastructure (rarely changes)
├── scripts/               # Automation (rarely changes)
├── argocd/                # Applications (frequently changes)
│   ├── bootstrap/         # ArgoCD installation
│   ├── environments/      # Environment-specific configs
│   │   ├── development/
│   │   ├── staging/
│   │   └── production/
│   └── base/              # Base application manifests
├── reports/               # Generated reports
└── docs/                  # Documentation
```

This gives you the benefits of organization while maintaining simplicity for a small team or personal project.