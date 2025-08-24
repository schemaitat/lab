# Kubernetes Logging Setup with Loki

## Overview

This document describes the centralized logging architecture using Grafana Loki and Fluent Bit deployed via ArgoCD in the Kubernetes cluster.

## Architecture

The logging stack consists of three main components:

### 1. Fluent Bit (Log Collector)
- **Deployment**: DaemonSet in `logging` namespace
- **Purpose**: Collects logs from all cluster nodes and containers
- **Configuration**: `/Users/andre/projects/iac/argocd/base/fluent-bit/`

**What it collects**:
- Container logs from `/var/log/containers/*.log`
- Kubelet service logs via systemd
- Kubernetes metadata enrichment

**Key features**:
- Parses Docker and CRI container runtime formats
- Adds Kubernetes metadata (namespace, pod name, labels)
- Forwards logs to Loki with structured labels

### 2. Loki (Log Aggregation)
- **Deployment**: Single replica in `logging` namespace
- **Purpose**: Stores and indexes log data with labels
- **Configuration**: `/Users/andre/projects/iac/argocd/base/loki/`

**Storage**:
- Uses filesystem storage (`/tmp/loki/chunks`)
- BoltDB-shipper for index storage
- Configured for single-node deployment

**Key features**:
- Label-based indexing (no full-text indexing)
- 168h (7 days) retention for old samples
- Resource limits: 1Gi memory, 500m CPU

### 3. Grafana (Log Visualization)
- **Deployment**: In `monitoring` namespace
- **Purpose**: Provides web UI for log querying and visualization
- **Configuration**: `/Users/andre/projects/iac/argocd/base/grafana/`

## Component Communication

```
[Container Logs] → [Fluent Bit DaemonSet] → [Loki Service] → [Grafana Dashboard]
     │                      │                     │               │
     │                      │                     │               │
  /var/log/           Port 3100              Port 3100      Port 3000
 containers/         loki.logging.          loki.logging.   (Grafana UI)
                  svc.cluster.local      svc.cluster.local
```

## Data Flow

1. **Log Collection**: Fluent Bit runs on every node, tailing container logs and systemd journals
2. **Enrichment**: Kubernetes metadata is added (namespace, pod, container names, labels)
3. **Forwarding**: Logs are sent to Loki with structured labels:
   - `job=fluentbit`
   - `cluster=k8s`
   - `component=kubelet` (for system logs)
4. **Storage**: Loki stores logs with label-based indexing
5. **Querying**: Grafana queries Loki using LogQL

## ArgoCD App-of-Apps Integration

The logging stack is deployed through the ArgoCD App-of-Apps pattern:

```yaml
# In system-apps.yaml
- name: loki (lines 183-204)
- name: fluent-bit (lines 206-227)
- name: grafana (lines 138-159)
```

Each component is managed as a separate ArgoCD Application with:
- Automated sync and self-healing enabled
- Namespace creation on deployment
- Git-based configuration management

## How to Access Logs

### Method 1: Grafana Dashboard
1. Port-forward to Grafana: `kubectl port-forward -n monitoring svc/grafana 3000:3000`
2. Open `http://localhost:3000` (admin/admin)
3. Navigate to "Kubernetes Logs Overview" dashboard
4. Use namespace dropdown to filter logs
5. Use search field for text filtering

### Method 2: Direct Loki API
```bash
# Port-forward to Loki
kubectl port-forward -n logging svc/loki 3100:3100

# Query logs via API
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={kubernetes_namespace_name="default"}' \
  --data-urlencode 'start=1h' | jq
```

### Method 3: LogCLI (Grafana Log CLI)
```bash
# Install logcli
go install github.com/grafana/loki/cmd/logcli@latest

# Set endpoint
export LOKI_ADDR=http://localhost:3100

# Query logs
logcli query '{kubernetes_namespace_name="default"}'
```

## Common Log Queries

### LogQL Examples:
```logql
# All logs from a specific namespace
{kubernetes_namespace_name="monitoring"}

# Error logs across all pods
{kubernetes_namespace_name="default"} |= "ERROR"

# Logs from a specific pod
{kubernetes_pod_name="hello-world-deployment-xyz"}

# Rate of log entries by namespace
sum(rate({job="fluentbit"}[5m])) by (kubernetes_namespace_name)

# Count of error logs per pod
sum by (kubernetes_pod_name) (rate({kubernetes_namespace_name="default"} |= "ERROR"[5m]))
```

## Configuration Details

### Fluent Bit Labels
- `job=fluentbit` - All container logs
- `cluster=k8s` - Cluster identifier
- `component=kubelet` - System logs

### Loki Limits
- Ingestion rate: 64MB/s
- Per-stream rate: 2MB/s
- Max streams per user: 10,000
- Max line size: 256KB
- Retention: 7 days for old samples

### Resource Allocation
- **Fluent Bit**: 100m CPU, 100Mi memory (200Mi limit)
- **Loki**: 200m CPU, 512Mi memory (500m CPU, 1Gi memory limits)
- **Grafana**: Configured with Loki datasource at `http://loki.logging.svc.cluster.local:3100`

## Troubleshooting

### Check Fluent Bit Status
```bash
kubectl get pods -n logging -l k8s-app=fluent-bit-logging
kubectl logs -n logging -l k8s-app=fluent-bit-logging
```

### Check Loki Status
```bash
kubectl get pods -n logging -l app=loki
kubectl logs -n logging -l app=loki
```

### Verify Log Flow
```bash
# Check if Loki is receiving logs
kubectl port-forward -n logging svc/loki 3100:3100
curl http://localhost:3100/loki/api/v1/label
```

## Optimizations Identified

1. **Resource Optimization**: Current setup is sized for development/small clusters
2. **Storage**: Using emptyDir - consider persistent volumes for production
3. **High Availability**: Single-replica Loki - consider clustering for production
4. **Retention**: No retention policies configured - logs grow indefinitely
5. **Security**: No authentication configured on Loki endpoint