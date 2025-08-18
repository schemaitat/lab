# Linode Infrastructure as Code

A comprehensive Infrastructure as Code setup for managing Linode Kubernetes Engine (LKE) clusters with automated billing reporting.

## 📁 Project Structure

```
.
├── README.md                    # This file
├── Taskfile.yml                 # Task automation with Task runner
├── kubeconfig.yaml             # Kubernetes cluster configuration (generated)
├── docs/                       # Documentation
├── reports/                    # Generated billing reports
│   ├── bill.pdf               # Latest billing report
│   ├── cost_structure.png     # Cost visualization
│   └── resource_chart.png     # Resource distribution chart
├── scripts/                    # Automation scripts
│   ├── setup-cluster.sh       # Cluster setup automation
│   ├── teardown-cluster.sh    # Cluster destruction
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

3. **Create your cluster:**
   ```bash
   task setup
   ```

## 📋 Available Tasks

Run `task --list` to see all available tasks:

| Task | Description |
|------|-------------|
| `setup` | Setup Kubernetes cluster on Linode |
| `teardown` | Teardown cluster and destroy all resources |
| `status` | Check cluster status and show information |
| `plan` | Show what changes would be applied to infrastructure |
| `apply` | Apply infrastructure changes |
| `fresh` | Get completely fresh state (destroy + clean + reinit) |
| `bill` | Generate comprehensive billing report as PDF |
| `kubectl` | Run kubectl commands with cluster kubeconfig |
| `logs` | View logs from a specific pod |
| `shell` | Get a shell in a pod |
| `clean` | Clean up local terraform and kubernetes files |

### Common Workflows

**Basic cluster management:**
```bash
# Create cluster
task setup

# Check status
task status

# Generate billing report
task bill

# Destroy cluster
task teardown
```

**Development workflow:**
```bash
# Fresh start
task fresh
task setup

# Make changes to terraform files
task plan
task apply

# Check what's running
task kubectl -- get pods --all-namespaces
```

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

### Getting Help

- Check task output for specific error messages
- Verify your Linode API token has sufficient permissions
- Ensure all prerequisites are installed
- Check Linode account limits and quotas

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