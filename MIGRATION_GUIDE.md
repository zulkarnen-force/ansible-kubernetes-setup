# Migration Guide: Docker to Containerd

This guide will help you migrate your existing Kubernetes setup from Docker to containerd.

## 🎯 Why Migrate to Containerd?

### Benefits of Containerd over Docker

| Aspect                     | Docker                           | Containerd                     |
| -------------------------- | -------------------------------- | ------------------------------ |
| **Resource Usage**         | Higher memory/CPU overhead       | Lower resource consumption     |
| **Startup Time**           | Slower due to Docker daemon      | Faster startup times           |
| **Security**               | Additional attack surface        | Reduced attack surface         |
| **Kubernetes Integration** | Requires dockershim (deprecated) | Native CRI support             |
| **Maintenance**            | More complex architecture        | Simpler, focused on containers |

## 📋 Pre-Migration Checklist

Before starting the migration:

- [ ] **Backup important data** (container volumes, configs)
- [ ] **Note running containers** and their configurations
- [ ] **Document custom Docker configurations**
- [ ] **Ensure downtime window** for the migration
- [ ] **Test migration in development** environment first

## 🚀 Migration Steps

### Step 1: Information Gathering

```bash
# List running containers (for reference)
docker ps -a

# Check Docker volumes
docker volume ls

# Note any custom Docker daemon configurations
cat /etc/docker/daemon.json
```

### Step 2: Stop Kubernetes Services

```bash
# Stop kubelet to prevent pod disruption
sudo systemctl stop kubelet

# Stop containerd (if running via Docker)
sudo systemctl stop containerd
```

### Step 3: Run Cleanup Playbook

This will remove Docker and all related components:

```bash
ansible-playbook -i inventory.ini cleanup_docker.yaml
```

**What the cleanup does:**

- Stops Docker services
- Removes Docker packages
- Cleans up Docker directories
- Removes Docker GPG keys
- Removes Docker group and user associations

### Step 4: Install Containerd

```bash
ansible-playbook -i inventory.ini main_containerd.yaml
```

**What this installs:**

- Containerd runtime with proper CRI configuration
- Required kernel modules (overlay, br_netfilter)
- Kubernetes components configured for containerd
- Proper systemd cgroup driver configuration

### Step 5: Verify Installation

```bash
ansible-playbook -i inventory.ini verify_setup.yaml
```

### Step 6: Restart Kubernetes Cluster

After successful verification:

```bash
# On master nodes, reinitialize if needed
sudo kubeadm reset
sudo kubeadm init --cri-socket unix:///var/run/containerd/containerd.sock

# On worker nodes, rejoin the cluster
sudo kubeadm reset
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash> --cri-socket unix:///var/run/containerd/containerd.sock
```

## 🔍 Post-Migration Verification

### 1. Check Container Runtime

```bash
# Verify containerd is running
sudo systemctl status containerd

# Check containerd version
ctr version

# List containerd namespaces
sudo ctr namespace list
```

### 2. Verify Kubernetes Integration

```bash
# Check kubelet logs
sudo journalctl -u kubelet -f

# Verify node ready status
kubectl get nodes

# Check running pods
kubectl get pods -A
```

### 3. Test Container Operations

```bash
# Pull an image using containerd
sudo ctr image pull docker.io/library/hello-world:latest

# List images
sudo ctr image list

# Run a test container
sudo ctr run --rm -t docker.io/library/hello-world:latest test-container
```

## 🐛 Troubleshooting Migration Issues

### Issue: Kubelet fails to start after migration

**Symptoms:**

- Kubelet service failing
- Error about container runtime

**Solution:**

```bash
# Check kubelet configuration
sudo cat /var/lib/kubelet/config.yaml

# Ensure CRI socket is set correctly
sudo systemctl edit kubelet
# Add:
# [Service]
# Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### Issue: Pods stuck in ContainerCreating

**Symptoms:**

- Pods not starting
- Events showing container runtime errors

**Solution:**

```bash
# Check containerd logs
sudo journalctl -u containerd -f

# Restart containerd
sudo systemctl restart containerd

# Delete stuck pods
kubectl delete pod <pod-name> --force --grace-period=0
```

### Issue: Image pull failures

**Symptoms:**

- ImagePullBackOff errors
- Registry authentication issues

**Solution:**

```bash
# Configure registry authentication in containerd
sudo mkdir -p /etc/containerd/
sudo containerd config default > /etc/containerd/config.toml

# Edit config.toml to add registry auth
# Then restart containerd
sudo systemctl restart containerd
```

## 📊 Performance Comparison

After migration, you should observe:

### Resource Usage Improvements

- **Memory**: 20-30% reduction in overall memory usage
- **CPU**: 10-15% reduction in CPU overhead
- **Disk I/O**: Improved due to fewer layers

### Performance Metrics

- **Pod startup time**: 2-5 seconds faster
- **Image pulls**: More efficient due to direct containerd integration
- **Network performance**: Slight improvement due to reduced overhead

## 🔄 Rollback Plan

If you need to rollback to Docker:

### Emergency Rollback

```bash
# Stop services
sudo systemctl stop kubelet containerd

# Remove containerd
sudo apt purge containerd.io

# Reinstall Docker (use your previous setup)
ansible-playbook -i inventory.ini main.yaml  # Original Docker playbook

# Reconfigure Kubernetes for Docker
sudo kubeadm reset
# Reinitialize cluster with Docker runtime
```

### Planned Rollback

1. **Document current containerd configuration**
2. **Stop Kubernetes workloads gracefully**
3. **Run Docker installation playbook**
4. **Reconfigure cluster**
5. **Restore workloads**

## 📝 Migration Checklist

### Pre-Migration

- [ ] Backup cluster state (`kubectl get all -A -o yaml > backup.yaml`)
- [ ] Document custom configurations
- [ ] Test in development environment
- [ ] Plan maintenance window

### During Migration

- [ ] Run cleanup playbook
- [ ] Install containerd setup
- [ ] Verify installation
- [ ] Test basic functionality

### Post-Migration

- [ ] Verify all nodes are ready
- [ ] Check all pods are running
- [ ] Test application functionality
- [ ] Monitor performance metrics
- [ ] Update documentation

## 🚨 Important Notes

1. **Downtime Required**: This migration requires cluster downtime
2. **Container State Lost**: Running containers will be lost during migration
3. **Image Re-download**: Container images may need to be pulled again
4. **Persistent Volumes**: Should remain intact if using external storage
5. **Network Policies**: May need reconfiguration depending on CNI

## 📞 Support

If you encounter issues during migration:

1. **Check logs**: `sudo journalctl -u containerd -u kubelet`
2. **Run verification**: `ansible-playbook verify_setup.yaml`
3. **Review configuration**: Ensure all variables are set correctly
4. **Test connectivity**: Verify network and storage connectivity

## 🎉 Migration Complete!

Once migration is successful, you'll have:

- ✅ Lighter, faster container runtime
- ✅ Better Kubernetes integration
- ✅ Improved security posture
- ✅ Future-proof setup (no more dockershim deprecation warnings)

Welcome to the containerd world! 🚀
