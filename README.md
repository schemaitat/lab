# Linode Infrastructure as Code

A comprehensive Infrastructure as Code setup for managing Linode Kubernetes Engine (LKE) clusters with ArgoCD GitOps, automated billing reporting, and complete resource lifecycle management.

## 📁 Project Structure

```
.
├── README.md                    # This file
├── Taskfile.yml                 # Task automation with Task runner
├── kubeconfig.yaml             # Kubernetes cluster configuration (generated)
├── argocd/                     # ArgoCD GitOps configuration
│   ├── bootstrap/              # App of Apps root application
│   ├── base/                   # Base application manifests
│   │   ├── cert-manager/       # SSL certificate management
│   │   ├── ingress/            # Ingress controller configuration
│   │   ├── monitoring/         # Prometheus monitoring stack
│   │   ├── hello-world/        # Demo application
│   │   └── cost-dashboard/     # Cost monitoring dashboard
│   └── environments/           # Environment-specific configurations
│       └── development/        # Development environment apps
├── docs/                       # Documentation
├── reports/                    # Generated billing reports
│   ├── bill.pdf               # Latest billing report
│   ├── cost_structure.png     # Cost visualization
│   └── resource_chart.png     # Resource distribution chart
├── scripts/                    # Automation scripts
│   ├── setup-cluster.sh       # Cluster setup automation
│   ├── teardown-cluster.sh    # Enhanced cluster destruction with cleanup
│   ├── install-argocd.sh      # ArgoCD installation script
│   └── generate_billing_report.py # PDF billing report generator
└── terraform/                 # Infrastructure configuration
    ├── main.tf                # Main Terraform configuration
    ├── variables.tf           # Variable definitions
    ├── outputs.tf             # Output definitions
    ├── terraform.tfvars       # Variable values (configure this)
    ├── terraform.tfstate      # State file (generated)
    └── .terraform/            # Terraform cache (generated)
```

## 🚀 Quick Start

### Prerequisites

- [OpenTofu](https://opentofu.org/) or Terraform installed
- [Task](https://taskfile.dev/) runner installed
- [uv](https://docs.astral.sh/uv/) Python package manager
- [kubectl](https://kubernetes.io/docs/tasks/tools/) Kubernetes CLI
- [linode-cli](https://github.com/linode/linode-cli) Linode command line interface
- Linode API token

### Setup

1. **Configure Linode credentials:**
   ```bash
   # Set up your Linode API token
   export LINODE_TOKEN="your-api-token-here"
   
   # Or configure linode-cli
   linode-cli configure
   ```

2. **Configure Terraform variables:**
   ```bash
   # Copy and edit the terraform variables
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform/terraform.tfvars with your settings
   ```

3. **Create your cluster with ArgoCD:**
   ```bash
   # Complete setup: cluster + ArgoCD + sample applications
   task setup-complete
   
   # Or step by step:
   task setup           # Create cluster only
   task install-argocd  # Install ArgoCD with GitOps
   ```

## 📋 Available Tasks

Run `task --list` to see all available tasks:

| Task | Description |
|------|-------------|
| `setup` | Setup Kubernetes cluster on Linode |
| `setup-complete` | Complete setup: cluster + ArgoCD + applications |
| `install-argocd` | Install ArgoCD with App of Apps pattern |
| `teardown` | Teardown cluster and clean up all Linode resources |
| `status` | Check cluster status and show information |
| `plan` | Show what changes would be applied to infrastructure |
| `apply` | Apply infrastructure changes |
| `fresh` | Get completely fresh state (destroy + clean + reinit) |
| `bill` | Generate comprehensive billing report as PDF |
| `argocd-ui` | Start port forwarding to ArgoCD UI |
| `argocd-password` | Get ArgoCD admin credentials |
| `monitoring-ui` | Start port forwarding to Prometheus UI |
| `demo-app` | Start port forwarding to Hello World demo |
| `cost-dashboard` | Start port forwarding to Cost Dashboard |
| `kubectl` | Run kubectl commands with cluster kubeconfig |
| `logs` | View logs from a specific pod |
| `shell` | Get a shell in a pod |
| `clean` | Clean up local terraform and kubernetes files |
| `k9s` | Start K9s terminal UI for cluster management |

### Common Workflows

**Basic cluster management:**
```bash
# Create cluster with ArgoCD and applications
task setup-complete

# Check status
task status

# Access ArgoCD UI
task argocd-password  # Get credentials
task argocd-ui        # Start port forwarding to localhost:8080

# Generate billing report
task bill

# Destroy cluster (with automatic NodeBalancer cleanup)
task teardown
```

**GitOps with ArgoCD:**
```bash
# Complete setup with GitOps
task setup-complete

# Access services
task argocd-ui          # ArgoCD UI at localhost:8080
task monitoring-ui      # Prometheus at localhost:9090
task demo-app          # Hello World at localhost:8081
task cost-dashboard    # Cost monitoring at localhost:8082

# Get LoadBalancer IP for external access
task kubectl -- get svc -n ingress-nginx

# Check ArgoCD applications
task kubectl -- get applications -n argocd
```

**Development workflow:**
```bash
# Fresh start
task fresh
task setup-complete

# Make changes to terraform files
task plan
task apply

# Check applications via ArgoCD
task argocd-ui

# Monitor with K9s
task k9s
```

## 🔄 GitOps with ArgoCD

### App of Apps Pattern

The cluster uses ArgoCD's "App of Apps" pattern for GitOps deployment:

```
argocd/
├── bootstrap/root-app.yaml          # Root application that manages all others
└── environments/development/        # Environment-specific configurations
    ├── system-apps.yaml            # Infrastructure applications
    └── demo-apps.yaml              # Demo applications
```

### Deployed Applications

**System Applications:**
- **NGINX Ingress Controller** - Traffic routing with automatic LoadBalancer
- **Cert-Manager** - Automatic SSL certificate management
- **Prometheus** - Monitoring and metrics collection
- **Cluster Issuers** - Let's Encrypt SSL certificate issuers

**Demo Applications:**
- **Hello World** - Simple demo application
- **Cost Dashboard** - Cost monitoring interface

### External Access

After deployment, applications are accessible via ingress:

```bash
# Get LoadBalancer IP
task kubectl -- get svc -n ingress-nginx

# Point lab.schemaitat.de to the LoadBalancer IP, then access:
# https://lab.schemaitat.de/prometheus   - Prometheus UI
# https://lab.schemaitat.de/hello       - Hello World demo
# https://lab.schemaitat.de/cost        - Cost Dashboard
```

### GitOps Workflow

1. **Automatic Sync** - ArgoCD monitors the Git repository
2. **Self-Healing** - Automatically corrects configuration drift
3. **Declarative** - All applications defined as code
4. **Rollback** - Easy rollback via Git history

## 💰 Billing & Cost Management

### Automated Reports

The project includes sophisticated billing analysis:

```bash
# Generate comprehensive PDF billing report
task bill
```

This creates `reports/bill.pdf` with:
- **Account Overview** - Current balance and usage
- **Resource Inventory** - All active compute instances and clusters
- **Cost Structure Diagram** - Visual breakdown of current month usage
- **Monthly Projections** - Estimated costs based on current resources
- **Optimization Recommendations** - Cost-saving suggestions

### Cost Monitoring Features

- **Dynamic Cost Structure** - Only shows services you're actually using
- **Real-time Data** - Pulls current information from Linode API
- **Visual Charts** - Cost breakdowns and resource distribution
- **Professional PDF Output** - Ready for expense reporting

## ⚙️ Configuration

### Terraform Variables

Configure `terraform/terraform.tfvars`:

```hcl
# Linode API Token
linode_token = "your-linode-api-token"

# Cluster Configuration
cluster_name = "my-lke-cluster"
region = "us-east"
kubernetes_version = "1.33"

# Node Pool Configuration
node_pools = [
  {
    type  = "g6-standard-2"
    count = 3
  }
]

# Tags
tags = ["production", "kubernetes"]
```

### Available Regions

Common Linode regions:
- `us-east` (Newark, NJ)
- `us-west` (Fremont, CA)
- `eu-west` (London, UK)
- `ap-south` (Singapore)
- `eu-central` (Frankfurt, DE)

### Instance Types & Pricing

| Type | RAM | CPU | Storage | Monthly Cost |
|------|-----|-----|---------|--------------|
| `g6-nanode-1` | 1GB | 1 | 25GB | $5 |
| `g6-standard-1` | 2GB | 1 | 50GB | $12 |
| `g6-standard-2` | 4GB | 2 | 80GB | $24 |
| `g6-standard-4` | 8GB | 4 | 160GB | $48 |
| `g6-standard-6` | 16GB | 6 | 320GB | $96 |

## 🔧 Advanced Usage

### Custom kubectl Commands

```bash
# List all pods
task kubectl -- get pods --all-namespaces

# Get cluster info
task kubectl -- cluster-info

# Apply manifests
task kubectl -- apply -f manifest.yaml
```

### Debugging

```bash
# View pod logs
task logs -- pod-name

# Get shell in pod
task shell -- pod-name

# Check cluster events
task kubectl -- get events --sort-by='.lastTimestamp'
```

### State Management

```bash
# Check what Terraform plans to do
task plan

# Apply only specific changes
task apply

# Start completely fresh
task fresh
```

## 🧹 Enhanced Resource Cleanup

### Automatic NodeBalancer Cleanup

The teardown script now includes intelligent cleanup of Linode resources:

```bash
task teardown
```

**What gets cleaned up automatically:**
- ✅ **Terraform Resources** - LKE cluster and managed infrastructure
- ✅ **NodeBalancers** - Automatically created by LoadBalancer services
- ✅ **CCM Resources** - Cloud Controller Manager created resources

**Cleanup Process:**
1. **Terraform Destroy** - Removes cluster and managed resources
2. **NodeBalancer Detection** - Identifies cluster-related NodeBalancers using CCM naming patterns
3. **Selective Cleanup** - Only removes resources associated with the destroyed cluster
4. **Resource Inventory** - Lists remaining resources that may need manual cleanup

**Requirements:**
- `linode-cli` installed and configured for automatic cleanup
- Without linode-cli, manual cleanup instructions are provided

### Manual Cleanup Check

After teardown, the script checks for:
- **Block Storage Volumes** - Persistent volumes that may remain
- **Firewalls** - Network policies that created firewall rules
- **DNS Records** - Domain records pointing to old IPs

This ensures no surprise billing from orphaned resources!

## 🛡️ Security Best Practices

1. **API Token Security:**
   - Never commit API tokens to git
   - Use environment variables or secure secret management
   - Rotate tokens regularly

2. **Cluster Security:**
   - Keep kubeconfig.yaml secure and local only
   - Regularly update Kubernetes versions
   - Use network policies and RBAC

3. **State File Security:**
   - Consider remote state storage for production
   - Encrypt state files
   - Limit access to state files

## 🐛 Troubleshooting

### Common Issues

**1. "terraform.tfvars not found"**
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit the file with your settings
```

**2. "tofu: command not found"**
```bash
# Install OpenTofu
brew install opentofu
```

**3. "kubectl: connection refused"**
```bash
# Ensure cluster is running
task status

# Check kubeconfig
export KUBECONFIG=./kubeconfig.yaml
kubectl get nodes
```

**4. "linode-cli: command not found"**
```bash
# Install linode-cli
pip install linode-cli
linode-cli configure
```

**5. "ArgoCD applications not syncing"**
```bash
# Check ArgoCD status
task kubectl -- get applications -n argocd

# Get ArgoCD server logs
task kubectl -- logs deployment/argocd-server -n argocd

# Force sync an application
task kubectl -- patch application app-name -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

**6. "LoadBalancer IP pending"**
```bash
# Check ingress controller status
task kubectl -- get svc -n ingress-nginx

# Check NodeBalancer creation in Linode
linode-cli nodebalancers list
```

**7. "Can't access external services"**
```bash
# Get LoadBalancer external IP
task kubectl -- get svc -n ingress-nginx

# Update DNS records to point to the LoadBalancer IP
# Or add to /etc/hosts for testing:
echo "LOADBALANCER_IP lab.schemaitat.de" | sudo tee -a /etc/hosts
```

### Getting Help

- Check task output for specific error messages
- Verify your Linode API token has sufficient permissions
- Ensure all prerequisites are installed
- Check Linode account limits and quotas
- Monitor ArgoCD UI for application sync status
- Use `task k9s` for interactive cluster debugging

## 📊 Monitoring & Observability

The billing reports provide insights into:
- Resource utilization trends
- Cost optimization opportunities
- Usage patterns and projections
- Service breakdown and allocation

Regular reporting helps with:
- Budget planning and forecasting
- Resource right-sizing decisions
- Cost allocation and chargeback
- Compliance and audit requirements

## 🤝 Contributing

This is a personal infrastructure project, but feel free to fork and adapt for your needs:

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is for personal use. Adapt as needed for your infrastructure requirements.

---

*Generated with ❤️ using Claude Code*