```bash
ansible-playbook main.yaml
```

```bash
nano hosts.ini
```

```bash
[masters]
master-1 ansible_user=ubuntu ansible_host=ec2-108-137-90-135.ap-southeast-3.compute.amazonaws.com

[workers]
worker-1 ansible_user=ubuntu ansible_host=ec2-16-78-150-238.ap-southeast-3.compute.amazonaws.com
worker-2 ansible_user=ubuntu ansible_host=ec2-43-218-94-70.ap-southeast-3.compute.amazonaws.com
```
