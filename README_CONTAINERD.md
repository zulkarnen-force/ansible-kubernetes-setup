# Kubernetes with Containerd Setup

This Ansible playbook has been refactored to use **containerd** as the container runtime instead of Docker. The setup is now more lightweight, follows Kubernetes best practices, and provides better performance.

## 🚀 What Changed

### ✅ Replaced Docker with Containerd

- **Removed**: Docker CE, Docker CLI, and Docker daemon
- **Added**: Standalone containerd installation with proper CRI configuration
- **Benefit**: Reduced resource usage, faster startup times, better security

### ✅ Improved Architecture

- **Modular Roles**: Separated containerd and Kubernetes into dedicated roles
- **Better Organization**: Clear separation of concerns with proper task organization
- **Configurable**: Extensive configuration options via variables

### ✅ Enhanced Features

- **Verification Tasks**: Built-in verification for all components
- **Cleanup Tools**: Automated Docker removal for clean migration
- **Tags Support**: Granular control over playbook execution
- **Error Handling**: Robust error handling and retry mechanisms

## 📁 Project Structure

```
ansible-kubernetes-setup/
├── roles/
│   ├── containerd/           # Containerd container runtime
│   │   ├── tasks/
│   │   │   ├── main.yaml
│   │   │   ├── install.yaml
│   │   │   ├── configure.yaml
│   │   │   ├── kernel_modules.yaml
│   │   │   └── service.yaml
│   │   ├── defaults/main.yaml
│   │   └── handlers/main.yaml
│   ├── kubernetes/           # Kubernetes components
│   │   ├── tasks/
│   │   │   ├── main.yaml
│   │   │   ├── system_prep.yaml
│   │   │   └── install_kubernetes.yaml
│   │   └── handlers/main.yaml
│   ├── common/              # Legacy role (deprecated)
│   ├── nfs-server/          # NFS server setup
│   └── nfs-client/          # NFS client setup
├── main_containerd.yaml     # New main playbook with containerd
├── cleanup_docker.yaml      # Docker cleanup playbook
├── setup_hostnames.yaml     # Hostname configuration playbook
├── test_connectivity.yaml   # SSH connectivity testing
├── troubleshoot_ssh.sh      # SSH troubleshooting script
├── verify_setup.yaml        # Verification playbook
├── SSH_CONFIGURATION.md     # SSH setup guide
├── main.yaml               # Legacy playbook (Docker-based)
├── ansible.cfg             # Ansible configuration with SSH settings
└── inventory.ini           # Inventory file with SSH configuration
```

## 🎯 Quick Start

### 0. Verify SSH Connectivity (Important First Step)

```bash
# Test SSH connections to all hosts
./troubleshoot_ssh.sh

# Or use the connectivity test playbook
ansible-playbook -i inventory.ini test_connectivity.yaml

# Test basic Ansible connectivity
ansible all -i inventory.ini -m ping
```

### 1. Configure Hostnames (Optional but Recommended)

```bash
# Set hostnames based on inventory before cluster setup
ansible-playbook -i inventory.ini setup_hostnames.yaml
```

### 2. Cleanup Existing Docker Installation (if any)

```bash
# Remove Docker and related components
ansible-playbook -i inventory.ini cleanup_docker.yaml
```

### 3. Setup Kubernetes with Containerd

```bash
# Run the main containerd-based setup
ansible-playbook -i inventory.ini main_containerd.yaml
```

### 4. Verify the Installation

```bash
# Verify everything is working correctly
ansible-playbook -i inventory.ini verify_setup.yaml
```

## 🔐 SSH Configuration

This setup uses SSH private key authentication. Your `ansible.cfg` and `inventory.ini` are already configured with SSH settings.

### SSH Key Setup

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copy public key to all hosts
ssh-copy-id -i ~/.ssh/id_rsa.pub master-1@10.13.0.6
ssh-copy-id -i ~/.ssh/id_rsa.pub worker-1@192.168.18.135
ssh-copy-id -i ~/.ssh/id_rsa.pub worker-2@192.168.18.131

# Test SSH connectivity
./troubleshoot_ssh.sh
```

### SSH Troubleshooting

```bash
# Run comprehensive SSH troubleshooting
./troubleshoot_ssh.sh

# Test connectivity with Ansible
ansible all -i inventory.ini -m ping

# Test with verbose output for debugging
ansible all -i inventory.ini -m ping -vvv
```

For detailed SSH configuration guide, see [SSH_CONFIGURATION.md](SSH_CONFIGURATION.md)

## 🎛️ Advanced Usage

### Hostname Configuration

```bash
# Configure hostnames only
ansible-playbook -i inventory.ini setup_hostnames.yaml

# Configure hostnames for specific groups
ansible-playbook -i inventory.ini setup_hostnames.yaml --limit masters
ansible-playbook -i inventory.ini setup_hostnames.yaml --limit workers

# Verify hostname configuration
ansible-playbook -i inventory.ini setup_hostnames.yaml --tags verify
```

### Run Specific Components

```bash
# Install only containerd
ansible-playbook -i inventory.ini main_containerd.yaml --tags containerd

# Install only Kubernetes components
ansible-playbook -i inventory.ini main_containerd.yaml --tags kubernetes

# Configure only hostname and system prep
ansible-playbook -i inventory.ini main_containerd.yaml --tags system-prep

# Run kernel module configuration only
ansible-playbook -i inventory.ini main_containerd.yaml --tags kernel
```

### Target Specific Hosts

```bash
# Setup masters only
ansible-playbook -i inventory.ini main_containerd.yaml --limit masters

# Setup workers only
ansible-playbook -i inventory.ini main_containerd.yaml --limit workers
```

## ⚙️ Configuration

### Containerd Configuration

You can customize containerd behavior by setting variables in your inventory or group_vars:

```yaml
# Example group_vars/all.yaml
containerd_version: "1.7.0"
containerd_sandbox_image: "registry.k8s.io/pause:3.9"
containerd_log_level: "info"
containerd_hold_package: true

# Registry mirrors (optional)
containerd_registry_mirrors:
  - registry: "docker.io"
    endpoints: ["https://mirror.example.com"]
```

### Available Variables

| Variable                      | Default                     | Description                            |
| ----------------------------- | --------------------------- | -------------------------------------- |
| `containerd_version`          | `""` (latest)               | Specific containerd version to install |
| `containerd_sandbox_image`    | `registry.k8s.io/pause:3.9` | Kubernetes pause container image       |
| `containerd_log_level`        | `info`                      | Containerd logging level               |
| `containerd_hold_package`     | `true`                      | Prevent automatic package updates      |
| `containerd_registry_mirrors` | `[]`                        | Registry mirror configuration          |

## 🔍 Verification

The `verify_setup.yaml` playbook checks:

- ✅ Containerd installation and service status
- ✅ Kubernetes components (kubelet, kubeadm, kubectl)
- ✅ Kernel modules (overlay, br_netfilter)
- ✅ Network configuration (sysctl settings)
- ✅ Swap disabled status
- ✅ Service health and functionality

## 🐛 Troubleshooting

### Common Issues

1. **Containerd service fails to start**

   ```bash
   # Check containerd logs
   sudo journalctl -u containerd -f

   # Verify configuration
   sudo containerd config dump
   ```

2. **Kernel modules not loading**

   ```bash
   # Manually load modules
   sudo modprobe overlay br_netfilter

   # Check if loaded
   lsmod | grep -E "(overlay|br_netfilter)"
   ```

3. **Kubelet fails to start**

   ```bash
   # Check kubelet logs
   sudo journalctl -u kubelet -f

   # Verify containerd is running
   sudo systemctl status containerd
   ```

### Cleanup and Restart

```bash
# Complete cleanup and reinstall
ansible-playbook -i inventory.ini cleanup_docker.yaml
ansible-playbook -i inventory.ini main_containerd.yaml
ansible-playbook -i inventory.ini verify_setup.yaml
```

## 📋 Migration from Docker

If you're migrating from the Docker-based setup:

1. **Backup any important data**
2. **Run the cleanup playbook** to remove Docker
3. **Run the new containerd playbook**
4. **Verify the installation**

```bash
# Migration commands
ansible-playbook -i inventory.ini cleanup_docker.yaml
ansible-playbook -i inventory.ini main_containerd.yaml
ansible-playbook -i inventory.ini verify_setup.yaml
```

## 🏷️ Tags Reference

| Tag           | Description                             |
| ------------- | --------------------------------------- |
| `containerd`  | All containerd-related tasks            |
| `kubernetes`  | All Kubernetes-related tasks            |
| `hostname`    | Hostname configuration tasks            |
| `system-prep` | System preparation tasks                |
| `kernel`      | Kernel modules and sysctl configuration |
| `verify`      | Verification and testing tasks          |
| `cleanup`     | Cleanup and removal tasks               |

## 📚 Additional Resources

- [Containerd Documentation](https://containerd.io/)
- [Kubernetes CRI Documentation](https://kubernetes.io/docs/concepts/architecture/cri/)
- [Containerd Configuration Guide](https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md)

## 🤝 Contributing

When contributing to this playbook:

1. Test your changes with the verification playbook
2. Update documentation if adding new features
3. Follow Ansible best practices
4. Add appropriate tags to new tasks

## 📝 License

This project maintains the same license as the original setup.
