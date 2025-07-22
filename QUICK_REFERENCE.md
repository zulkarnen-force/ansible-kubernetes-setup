# Containerd Quick Reference

## 🚀 Quick Commands

### Playbook Execution

```bash
# Clean install (recommended)
ansible-playbook -i inventory.ini cleanup_docker.yaml
ansible-playbook -i inventory.ini main_containerd.yaml

# Verify installation
ansible-playbook -i inventory.ini verify_setup.yaml

# Install specific components
ansible-playbook -i inventory.ini main_containerd.yaml --tags containerd
ansible-playbook -i inventory.ini main_containerd.yaml --tags kubernetes
```

### Containerd Management

```bash
# Service management
sudo systemctl status containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Configuration
sudo containerd config default > /etc/containerd/config.toml
sudo containerd config dump

# Version and info
ctr version
sudo ctr info
```

### Image Management

```bash
# List images
sudo ctr image list
sudo ctr image list -q

# Pull images
sudo ctr image pull docker.io/library/nginx:latest
sudo ctr image pull k8s.gcr.io/pause:3.9

# Remove images
sudo ctr image remove docker.io/library/nginx:latest
sudo ctr image prune
```

### Container Management

```bash
# List containers
sudo ctr container list
sudo ctr task list

# Run container
sudo ctr run --rm -t docker.io/library/ubuntu:latest test bash

# Stop/kill containers
sudo ctr task kill <container-id>
sudo ctr container delete <container-id>
```

### Namespaces

```bash
# List namespaces
sudo ctr namespace list

# Use specific namespace
sudo ctr -n k8s.io image list
sudo ctr -n k8s.io container list
```

### Debugging

```bash
# Logs
sudo journalctl -u containerd -f
sudo journalctl -u kubelet -f

# Process information
ps aux | grep containerd
sudo ss -tlnp | grep containerd

# Check sockets
ls -la /var/run/containerd/
sudo ctr info | grep -i socket
```

## 🔧 Configuration Snippets

### Enable Debug Logging

```toml
# /etc/containerd/config.toml
[debug]
  level = "debug"
```

### Registry Configuration

```toml
# /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://registry-1.docker.io"]
```

### Systemd Cgroup (Required for K8s)

```toml
# /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```

## 🚨 Troubleshooting

### Common Issues

```bash
# Containerd not starting
sudo containerd config default > /etc/containerd/config.toml
sudo systemctl restart containerd

# Permission issues
sudo usermod -aG docker $USER  # NOT needed for containerd
# Use sudo for containerd commands instead

# Socket not found
ls -la /var/run/containerd/containerd.sock
sudo systemctl restart containerd

# kubelet issues
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager
```

### Reset Everything

```bash
# Complete reset
sudo systemctl stop kubelet containerd
sudo rm -rf /etc/containerd/config.toml
sudo systemctl start containerd
sudo containerd config default > /etc/containerd/config.toml
# Edit config.toml for SystemdCgroup = true
sudo systemctl restart containerd kubelet
```

## 📋 Health Checks

### System Status

```bash
# Services
sudo systemctl is-active containerd kubelet

# Processes
pgrep -f containerd
pgrep -f kubelet

# Sockets
sudo ss -lx | grep containerd

# Modules
lsmod | grep -E "(overlay|br_netfilter)"

# Sysctl
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
```

### Kubernetes Integration

```bash
# Node status
kubectl get nodes -o wide

# Container runtime info
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'

# CRI status
sudo crictl info
sudo crictl version
```

## 🎯 Performance Commands

### Resource Usage

```bash
# Containerd process
ps aux | grep containerd
top -p $(pgrep containerd)

# Memory usage
sudo ctr metrics list
sudo ctr info | grep -A 10 memory

# Disk usage
sudo du -sh /var/lib/containerd
sudo df -h /var/lib/containerd
```

### Optimization

```bash
# Clean up unused images
sudo ctr image prune

# Clean up stopped containers
sudo ctr container list | grep -v Running | awk '{print $1}' | xargs sudo ctr container delete

# Check plugin status
sudo ctr plugin list
```

This quick reference should help you manage your containerd-based Kubernetes setup efficiently! 🚀
