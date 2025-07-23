# SSH Configuration Guide for Ansible

This guide explains how to configure SSH private key authentication for your Ansible Kubernetes setup.

## 🔐 SSH Authentication Methods

### Method 1: Using ansible.cfg (Recommended)

Your `ansible.cfg` is already configured with SSH private key:

```ini
[defaults]
inventory = inventory.ini
private_key_file = /home/zulkarnen/.ssh/id_rsa
host_key_checking = False
timeout = 30
ansible_ssh_common_args = '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[ssh_connection]
ssh_args = -o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### Method 2: Per-Host SSH Keys in Inventory

You can specify different SSH keys for different hosts in your inventory:

```ini
[masters]
master-1 ansible_user=master-1 ansible_host=10.13.0.6 ansible_ssh_private_key_file=/path/to/master-key.pem

[workers]
worker-1 ansible_user=worker-1 ansible_host=192.168.18.135 ansible_ssh_private_key_file=/path/to/worker-key.pem
worker-2 ansible_user=worker-2 ansible_host=192.168.18.131 ansible_ssh_private_key_file=/path/to/worker-key.pem
```

### Method 3: Group Variables

Create group variable files for different SSH configurations:

```bash
# Create group_vars directory
mkdir -p group_vars

# Masters SSH config
cat > group_vars/masters.yaml <<EOF
ansible_ssh_private_key_file: /home/zulkarnen/.ssh/masters_key
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF

# Workers SSH config
cat > group_vars/workers.yaml <<EOF
ansible_ssh_private_key_file: /home/zulkarnen/.ssh/workers_key
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
```

### Method 4: Command Line Override

You can override SSH keys at runtime:

```bash
# Use specific private key
ansible-playbook -i inventory.ini main_containerd.yaml --private-key /path/to/your/key.pem

# Use SSH agent
ansible-playbook -i inventory.ini main_containerd.yaml --ssh-extra-args="-o ForwardAgent=yes"
```

## 🔧 SSH Key Setup

### 1. Generate SSH Key Pair (if needed)

```bash
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/kubernetes_cluster_key

# Set proper permissions
chmod 600 ~/.ssh/kubernetes_cluster_key
chmod 644 ~/.ssh/kubernetes_cluster_key.pub
```

### 2. Copy Public Key to Target Hosts

```bash
# Copy public key to each host
ssh-copy-id -i ~/.ssh/kubernetes_cluster_key.pub master-1@10.13.0.6
ssh-copy-id -i ~/.ssh/kubernetes_cluster_key.pub worker-1@192.168.18.135
ssh-copy-id -i ~/.ssh/kubernetes_cluster_key.pub worker-2@192.168.18.131

# Or manually copy the public key
cat ~/.ssh/kubernetes_cluster_key.pub | ssh user@host 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

### 3. Test SSH Connection

```bash
# Test SSH connection with private key
ssh -i ~/.ssh/kubernetes_cluster_key master-1@10.13.0.6

# Test Ansible connectivity
ansible all -i inventory.ini -m ping
```

## 🔍 Troubleshooting SSH Issues

### Common Issues and Solutions

#### 1. Permission Denied (publickey)

```bash
# Check key permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Verify public key is on target host
ssh user@host 'cat ~/.ssh/authorized_keys'
```

#### 2. Host Key Verification Failed

```bash
# Remove old host keys
ssh-keygen -R hostname_or_ip

# Or disable host key checking (already in ansible.cfg)
export ANSIBLE_HOST_KEY_CHECKING=False
```

#### 3. SSH Agent Issues

```bash
# Start SSH agent
eval $(ssh-agent)

# Add your key to SSH agent
ssh-add ~/.ssh/id_rsa

# List loaded keys
ssh-add -l
```

#### 4. Connection Timeout

```bash
# Test basic connectivity
ping 10.13.0.6

# Check if SSH port is open
telnet 10.13.0.6 22
nmap -p 22 10.13.0.6
```

#### 5. Wrong User or Key

```bash
# Test with verbose SSH
ssh -vvv -i ~/.ssh/id_rsa user@host

# Check Ansible with verbose output
ansible all -i inventory.ini -m ping -vvv
```

## 🎯 Recommended Configuration

For your current setup, here's the recommended configuration:

### 1. Update your inventory with SSH specifics:

```ini
[masters]
master-1 ansible_user=master-1 ansible_host=10.13.0.6 ansible_ssh_private_key_file=/home/zulkarnen/.ssh/id_rsa

[workers]
worker-1 ansible_user=worker-1 ansible_host=192.168.18.135 ansible_ssh_private_key_file=/home/zulkarnen/.ssh/id_rsa
worker-2 ansible_user=worker-2 ansible_host=192.168.18.131 ansible_ssh_private_key_file=/home/zulkarnen/.ssh/id_rsa

[nfs-server]
nfs-server-master-1 ansible_user=nfs-server-master ansible_host=192.168.18.130 ansible_ssh_private_key_file=/home/zulkarnen/.ssh/id_rsa

[kubernetes:children]
masters

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
```

### 2. Verify SSH connectivity:

```bash
# Test connectivity to all hosts
ansible all -i inventory.ini -m ping

# Test specific groups
ansible masters -i inventory.ini -m ping
ansible workers -i inventory.ini -m ping
```

### 3. Run your playbooks:

```bash
# Setup hostnames
ansible-playbook -i inventory.ini setup_hostnames.yaml

# Full containerd setup
ansible-playbook -i inventory.ini main_containerd.yaml

# Verify installation
ansible-playbook -i inventory.ini verify_setup.yaml
```

## 🔒 Security Best Practices

### 1. Key Management

```bash
# Use separate keys for different environments
~/.ssh/
├── production_cluster_key      # Production environment
├── staging_cluster_key         # Staging environment
└── development_cluster_key     # Development environment
```

### 2. SSH Configuration

```bash
# Create SSH config file
cat > ~/.ssh/config <<EOF
Host master-1
    HostName 10.13.0.6
    User master-1
    IdentityFile ~/.ssh/kubernetes_cluster_key
    StrictHostKeyChecking no

Host worker-*
    User worker-%h
    IdentityFile ~/.ssh/kubernetes_cluster_key
    StrictHostKeyChecking no
EOF
```

### 3. Key Rotation

```bash
# Regular key rotation script
#!/bin/bash
# Generate new key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/kubernetes_cluster_key_new

# Deploy new key
ansible all -i inventory.ini -m authorized_key -a "user={{ ansible_user }} key='{{ lookup('file', '~/.ssh/kubernetes_cluster_key_new.pub') }}'"

# Update ansible.cfg
# Remove old key after verification
```

## 🚀 Quick Commands

```bash
# Test SSH connectivity
ansible all -i inventory.ini -m ping

# Run with specific SSH key
ansible-playbook -i inventory.ini main_containerd.yaml --private-key ~/.ssh/custom_key

# Debug SSH connection
ansible all -i inventory.ini -m ping -vvv

# Run setup with SSH key verification
ansible-playbook -i inventory.ini setup_hostnames.yaml --check
```
