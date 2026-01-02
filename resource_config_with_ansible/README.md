# Azure VM Scale Set with Ansible Configuration

## Overview

This Terraform project deploys an Azure infrastructure that provisions a Linux Virtual Machine Scale Set (VMSS) with automated configuration management using Ansible. The infrastructure includes networking, compute resources, and auto-scaling monitoring capabilities.

## Architecture

The infrastructure consists of the following components:

### Compute Resources
- **Linux Virtual Machine Scale Set (VMSS)**: 
  - Running Ubuntu Server 18.04 LTS
  - Configurable instance count
  - Configurable VM SKU
  - Configured with both SSH key and password authentication
  - System-assigned managed identity enabled
  - Automated configuration via cloud-init
  - Integrated with Azure Load Balancer backend pool

### Networking
- **Virtual Network**: Custom VNet with configurable address space
- **Subnet**: Dedicated subnet for VMSS instances
- **Azure Load Balancer**: Standard SKU load balancer for traffic distribution
  - Public IP address for external access
  - Backend address pool connected to VMSS instances
  - Health probe monitoring on port 80
  - Load balancing rule for HTTP traffic (port 80)

### Monitoring & Auto-scaling
- **Azure Monitor Autoscale Settings**:
  - **Scale-out rule**: Increases instance count based on CPU threshold
  - **Scale-in rule**: Decreases instance count based on CPU threshold
  - Configurable capacity range
  - Email notifications to subscription administrators

### Automated Configuration
- **Cloud-init**: Executes on VM startup to:
  - Update and upgrade packages
  - Install Ansible and Git
  - Clone Ansible playbooks from a Git repository
  - Execute Ansible playbooks for automated VM configuration

## Project Structure

```
resource_config_with_ansible/
├── env/
│   ├── dev/              # Development environment
│   ├── stage/            # Staging environment
│   └── prod/             # Production environment
├── modules/
│   ├── compute/          # VM Scale Set resources
│   ├── networking/       # VNet and subnet resources
│   ├── monitoring/       # Autoscaling and monitoring
│   ├── database/         # (Module defined, not currently used)
│   └── security/         # (Module commented out)
└── Scripts/
    └── cloud-init.yaml   # VM initialization script
```

## Prerequisites

- Terraform >= 1.0
- Azure CLI installed and authenticated
- SSH key pair generated at `~/.ssh/id_rsa.pub` (or update the path in tfvars)
- Valid Azure subscription

## Configuration

### Environment Variables

Key variables defined in `env/dev/terraform.tfvars`:

| Variable | Description |
|----------|-------------|
| `project_name` | Project identifier |
| `environment` | Environment name (dev, stage, prod) |
| `location` | Azure region |
| `address_space` | VNet address space |
| `subnet_prefixes` | Subnet address prefix |
| `administrator_login` | Admin username |
| `administrator_password` | Admin password (sensitive) |
| `ssh_public_key_path` | Path to SSH public key |
| `load_balancer_backend_address_pool_id` | Load balancer backend pool ID (internal) |

## Deployment

### Deploy to Development Environment

```bash
cd env/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Other Environments

```bash
cd env/stage  # or env/prod
terraform init
terraform plan
terraform apply
```

## Outputs

After successful deployment, the following outputs are available:

- `resource_group_name`: Name of the created resource group
- `location`: Deployment location
- `virtual_machine_scale_set_id`: ID of the VM Scale Set

## Auto-scaling Behavior

The infrastructure automatically scales based on CPU utilization:

- **Scale Out**: When average CPU exceeds configured threshold, a new instance is added
- **Scale In**: When average CPU falls below configured threshold, an instance is removed
- **Cooldown**: Configurable cooldown period between scaling actions
- **Limits**: Configurable minimum and maximum instance counts

## Cloud-init Configuration

VMs are automatically configured on startup using the cloud-init script located at `Scripts/cloud-init.yaml`. The script:

1. Updates all system packages
2. Installs Ansible and Git
3. Clones Ansible playbooks from the configured repository
4. Executes the setup playbook for automated configuration

**Note**: Update the Git repository URL in `cloud-init.yaml` to point to your Ansible playbooks repository.

## Security Features

- SSH public key authentication configured
- Password authentication enabled (can be disabled by setting `disable_password_authentication = true`)
- System-assigned managed identity for Azure service authentication
- Network isolation via dedicated subnet

## Cleanup

To destroy the infrastructure:

```bash
cd env/dev  # or the environment you deployed
terraform destroy
```

## Notes

- The security module is currently commented out in the main configuration
- The database module exists but is not currently used in the deployment
- Ensure your Ansible repository URL in `cloud-init.yaml` is accessible from the VMs
- Modify autoscale thresholds in `modules/monitoring/main.tf` based on your workload requirements