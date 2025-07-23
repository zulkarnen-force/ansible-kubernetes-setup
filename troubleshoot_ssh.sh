#!/bin/bash
# SSH Troubleshooting Script for Ansible Kubernetes Setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SSH TROUBLESHOOTING FOR ANSIBLE SETUP${NC}"
echo -e "${BLUE}========================================${NC}"

# Configuration
INVENTORY_FILE="inventory.ini"
SSH_KEY="/home/zulkarnen/.ssh/id_rsa"
ANSIBLE_CONFIG="ansible.cfg"

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 1. Check if files exist
echo -e "\n${BLUE}1. Checking required files...${NC}"

if [ -f "$INVENTORY_FILE" ]; then
    print_status "Inventory file found: $INVENTORY_FILE"
else
    print_status "Inventory file missing: $INVENTORY_FILE"
    exit 1
fi

if [ -f "$SSH_KEY" ]; then
    print_status "SSH private key found: $SSH_KEY"
else
    print_status "SSH private key missing: $SSH_KEY"
    echo -e "${YELLOW}💡 Generate a new key with: ssh-keygen -t rsa -b 4096 -f $SSH_KEY${NC}"
fi

if [ -f "$ANSIBLE_CONFIG" ]; then
    print_status "Ansible config found: $ANSIBLE_CONFIG"
else
    print_status "Ansible config missing: $ANSIBLE_CONFIG"
fi

# 2. Check SSH key permissions
echo -e "\n${BLUE}2. Checking SSH key permissions...${NC}"
if [ -f "$SSH_KEY" ]; then
    PERMS=$(stat -c "%a" "$SSH_KEY")
    if [ "$PERMS" = "600" ]; then
        print_status "SSH key permissions correct (600)"
    else
        print_status "SSH key permissions incorrect ($PERMS)"
        print_info "Fixing permissions..."
        chmod 600 "$SSH_KEY"
        print_status "SSH key permissions fixed"
    fi
fi

# 3. Extract hosts from inventory
echo -e "\n${BLUE}3. Extracting hosts from inventory...${NC}"
HOSTS=($(grep -E "ansible_host=" "$INVENTORY_FILE" | awk '{print $3}' | cut -d'=' -f2))
USERS=($(grep -E "ansible_user=" "$INVENTORY_FILE" | awk '{print $2}' | cut -d'=' -f2))
NAMES=($(grep -E "ansible_host=" "$INVENTORY_FILE" | awk '{print $1}'))

if [ ${#HOSTS[@]} -eq 0 ]; then
    print_status "No hosts found in inventory"
    exit 1
else
    print_status "Found ${#HOSTS[@]} hosts in inventory"
fi

# 4. Test network connectivity
echo -e "\n${BLUE}4. Testing network connectivity...${NC}"
for i in "${!HOSTS[@]}"; do
    HOST="${HOSTS[$i]}"
    NAME="${NAMES[$i]}"
    echo -e "\n${YELLOW}Testing connectivity to $NAME ($HOST)...${NC}"
    
    # Ping test
    if ping -c 2 -W 2 "$HOST" > /dev/null 2>&1; then
        print_status "Ping to $HOST successful"
    else
        print_status "Ping to $HOST failed"
        continue
    fi
    
    # Port 22 test
    if nc -z -w5 "$HOST" 22 2>/dev/null; then
        print_status "SSH port (22) is open on $HOST"
    else
        print_status "SSH port (22) is closed or filtered on $HOST"
        continue
    fi
done

# 5. Test SSH connections
echo -e "\n${BLUE}5. Testing SSH connections...${NC}"
for i in "${!HOSTS[@]}"; do
    HOST="${HOSTS[$i]}"
    USER="${USERS[$i]}"
    NAME="${NAMES[$i]}"
    
    echo -e "\n${YELLOW}Testing SSH to $NAME ($USER@$HOST)...${NC}"
    
    # Test SSH connection
    if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$HOST" "echo 'SSH connection successful'" 2>/dev/null; then
        print_status "SSH connection to $USER@$HOST successful"
        
        # Test sudo
        if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$HOST" "sudo -n true" 2>/dev/null; then
            print_status "Sudo access for $USER@$HOST working"
        else
            print_status "Sudo access for $USER@$HOST failed"
            print_info "You may need to configure passwordless sudo or run with -K flag"
        fi
    else
        print_status "SSH connection to $USER@$HOST failed"
        print_info "Check if public key is installed: ssh-copy-id -i ${SSH_KEY}.pub $USER@$HOST"
    fi
done

# 6. Test Ansible connectivity
echo -e "\n${BLUE}6. Testing Ansible connectivity...${NC}"
if command -v ansible >/dev/null 2>&1; then
    print_status "Ansible command available"
    
    echo -e "\n${YELLOW}Running ansible ping test...${NC}"
    if ansible all -i "$INVENTORY_FILE" -m ping --one-line 2>/dev/null; then
        print_status "Ansible ping test successful"
    else
        print_status "Ansible ping test failed"
        echo -e "\n${YELLOW}Running with verbose output:${NC}"
        ansible all -i "$INVENTORY_FILE" -m ping -vvv
    fi
else
    print_status "Ansible command not found"
    print_info "Install Ansible: sudo apt update && sudo apt install ansible"
fi

# 7. SSH Agent check
echo -e "\n${BLUE}7. Checking SSH Agent...${NC}"
if [ -n "$SSH_AUTH_SOCK" ]; then
    print_status "SSH Agent is running"
    
    # Check if key is loaded
    if ssh-add -l | grep -q "$SSH_KEY"; then
        print_status "SSH key is loaded in agent"
    else
        print_status "SSH key not loaded in agent"
        print_info "Add key to agent: ssh-add $SSH_KEY"
    fi
else
    print_status "SSH Agent not running"
    print_info "Start SSH agent: eval \$(ssh-agent) && ssh-add $SSH_KEY"
fi

# 8. Configuration summary
echo -e "\n${BLUE}8. Configuration Summary${NC}"
echo -e "${YELLOW}Current Configuration:${NC}"
echo "- Inventory: $INVENTORY_FILE"
echo "- SSH Key: $SSH_KEY"
echo "- Ansible Config: $ANSIBLE_CONFIG"
echo ""

echo -e "${YELLOW}Hosts to manage:${NC}"
for i in "${!HOSTS[@]}"; do
    echo "- ${NAMES[$i]}: ${USERS[$i]}@${HOSTS[$i]}"
done

# 9. Recommendations
echo -e "\n${BLUE}9. Recommendations${NC}"
echo -e "${YELLOW}To fix common issues:${NC}"
echo ""
echo "1. Copy SSH keys to all hosts:"
echo "   for host in ${HOSTS[@]}; do"
echo "     ssh-copy-id -i ${SSH_KEY}.pub \$user@\$host"
echo "   done"
echo ""
echo "2. Test Ansible connectivity:"
echo "   ansible all -i $INVENTORY_FILE -m ping"
echo ""
echo "3. Run connectivity test playbook:"
echo "   ansible-playbook -i $INVENTORY_FILE test_connectivity.yaml"
echo ""
echo "4. Setup the cluster:"
echo "   ansible-playbook -i $INVENTORY_FILE setup_hostnames.yaml"
echo "   ansible-playbook -i $INVENTORY_FILE main_containerd.yaml"

echo -e "\n${GREEN}SSH troubleshooting completed!${NC}"
