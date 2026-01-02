# Architecture Documentation

## System Architecture Overview

This document describes the technical architecture of the Azure VM Scale Set infrastructure with Ansible-based automated configuration management.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Resource Group                        │
│  (rg-resource_config_with_ansible-{environment})                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │           Azure Load Balancer (Standard SKU)           │    │
│  │  ┌─────────────────┐    ┌──────────────────────┐      │    │
│  │  │   Public IP     │───▶│  Frontend IP Config  │      │    │
│  │  │   (Static)      │    │                      │      │    │
│  │  └─────────────────┘    └──────────┬───────────┘      │    │
│  │                                    │                   │    │
│  │                         ┌──────────▼───────────┐       │    │
│  │                         │  LB Rule (Port 80)   │       │    │
│  │                         └──────────┬───────────┘       │    │
│  │                         ┌──────────▼───────────┐       │    │
│  │                         │  Health Probe (80)   │       │    │
│  │                         └──────────┬───────────┘       │    │
│  │                         ┌──────────▼───────────┐       │    │
│  │                         │  Backend Pool        │       │    │
│  │                         └──────────┬───────────┘       │    │
│  └────────────────────────────────────┼────────────────────┘    │
│                                       │                          │
│  ┌────────────────────────────────────▼───────────────────┐    │
│  │              Virtual Network                           │    │
│  │                                                         │    │
│  │  ┌───────────────────────────────────────────────┐    │    │
│  │  │   Subnet                                       │    │    │
│  │  │                                                │    │    │
│  │  │   ┌──────────────────────────────────────┐   │    │    │
│  │  │   │  Linux VM Scale Set (VMSS)           │   │    │    │
│  │  │   │  ┌────────┐ ┌────────┐ ┌────────┐   │   │    │    │
│  │  │   │  │  VM 1  │ │  VM 2  │ │  VM 3  │   │   │    │    │
│  │  │   │  │Ubuntu  │ │Ubuntu  │ │Ubuntu  │   │   │    │    │
│  │  │   │  │18.04   │ │18.04   │ │18.04   │   │   │    │    │
│  │  │   │  └────────┘ └────────┘ └────────┘   │   │    │    │
│  │  │   │       │          │          │        │   │    │    │
│  │  │   │       └──────────┴──────────┘        │   │    │    │
│  │  │   │              │                        │   │    │    │
│  │  │   │         NIC (Primary)                 │   │    │    │
│  │  │   │     (Connected to LB Backend Pool)    │   │    │    │
│  │  │   └──────────────────────────────────────┘   │    │    │
│  │  │                                               │    │    │
│  │  └───────────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │          Azure Monitor Autoscale Settings              │    │
│  │  ┌──────────────────────────────────────────────┐     │    │
│  │  │  Scale-Out Rule: CPU > 75% → +1 instance    │     │    │
│  │  │  Scale-In Rule:  CPU < 25% → -1 instance    │     │    │
│  │  │  Capacity: Min=1, Default=1, Max=5          │     │    │
│  │  └──────────────────────────────────────────────┘     │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │          SSH Public Key Resource                       │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

           ┌─────────────────────────────────┐
           │   Cloud-init on VM Startup      │
           │  1. Update/Upgrade packages     │
           │  2. Install Ansible & Git       │
           │  3. Clone Ansible playbooks     │
           │  4. Execute setup playbook      │
           └─────────────────────────────────┘
```

## Component Architecture

### 1. Resource Organization

#### Resource Group
- **Naming Convention**: `rg-{project_name}-{environment}`
- **Purpose**: Logical container for all infrastructure resources
- **Lifecycle**: Environment-specific (dev, stage, prod)

### 2. Networking Layer

#### Virtual Network (VNet)
- **Address Space**: Configurable via `address_space` variable
- **Purpose**: Network isolation and IP address management
- **Resource**: `azurerm_virtual_network.vnet`

#### Subnet
- **Name Pattern**: `{project_name}-subnet-vmss-{environment}`
- **Address Prefix**: Configurable via `subnet_prefixes` variable
- **Purpose**: Dedicated network segment for VM Scale Set instances
- **Resource**: `azurerm_subnet.subnet`

#### Azure Load Balancer
- **Resource**: `azurerm_lb.lb`
- **SKU**: Standard
- **Name Pattern**: `{project_name}-lb-{environment}`
- **Components**:
  - **Frontend IP Configuration**: Named "PublicIPAddress", connected to public IP
  - **Backend Address Pool**: `azurerm_lb_backend_address_pool.lbap`
    - Name Pattern: `{project_name}-lb-backend-pool-{environment}`
    - Connected to VMSS instances
  - **Health Probe**: `azurerm_lb_probe.lbprobe`
    - Protocol: TCP
    - Port: 80
    - Interval: 15 seconds
    - Number of probes: 2
  - **Load Balancing Rule**: `azurerm_lb_rule.lbr`
    - Protocol: TCP
    - Frontend Port: 80
    - Backend Port: 80

#### Public IP Address
- **Resource**: `azurerm_public_ip.public_ip`
- **SKU**: Standard (required for Standard Load Balancer)
- **Allocation Method**: Static
- **Name Pattern**: `{project_name}-public-ip-{environment}`
- **Purpose**: Provides external access point for the load balancer

### 3. Compute Layer

#### Linux Virtual Machine Scale Set
- **Resource**: `azurerm_linux_virtual_machine_scale_set.lvmss`
- **Configuration**:
  - **VM SKU**: Configurable (default in dev environment)
  - **OS**: Ubuntu Server 18.04 LTS (Canonical)
  - **Instance Count**: Configurable initial count, auto-scales based on load
  - **Storage**: Standard LRS (Locally Redundant Storage)
  - **Caching**: ReadWrite on OS disk

#### Identity & Authentication
- **Managed Identity**: System-assigned
  - Allows VMs to authenticate to Azure services without credentials
- **Authentication Methods**:
  - SSH public key authentication (primary)
  - Password authentication (enabled, can be disabled)
- **Admin User**: Configurable via `administrator_login` variable

#### Network Interface
- **Name Pattern**: `{project_name}-{environment}-nic`
- **Type**: Primary NIC
- **IP Configuration**: 
  - Name: `{project_name}-{environment}-ipconfig`
  - Subnet: First subnet from networking module
  - IP Version: IPv4
  - Load Balancer Integration: Connected to backend address pool

### 4. Configuration Management Layer

#### Cloud-init Integration
- **Method**: Base64-encoded cloud-init YAML passed as `custom_data`
- **File Location**: `Scripts/cloud-init.yaml`
- **Execution**: Runs once on first VM boot

#### Bootstrap Process
```
VM Provisioning
    ↓
Cloud-init Execution
    ↓
Package Update/Upgrade
    ↓
Install Ansible + Git
    ↓
Clone Ansible Repository
    ↓
Execute Ansible Playbook
    ↓
VM Ready
```

### 5. Monitoring & Auto-scaling Layer

#### Azure Monitor Autoscale Settings
- **Resource**: `azurerm_monitor_autoscale_setting.asmonitoring`
- **Target**: VM Scale Set
- **Profile**: Single default profile

#### Scaling Rules

##### Scale-Out Rule
- **Trigger Metric**: Percentage CPU
- **Condition**: Configurable threshold (when CPU exceeds defined limit)
- **Time Window**: Configurable
- **Time Grain**: Configurable
- **Action**: Increase instance count by 1
- **Cooldown**: Configurable
- **Metric Namespace**: Microsoft.Compute/virtualMachineScaleSets

##### Scale-In Rule
- **Trigger Metric**: Percentage CPU
- **Condition**: Configurable threshold (when CPU falls below defined limit)
- **Time Window**: Configurable
- **Time Grain**: Configurable
- **Action**: Decrease instance count by 1
- **Cooldown**: Configurable

#### Capacity Configuration
- **Minimum Instances**: Configurable
- **Default Instances**: Configurable
- **Maximum Instances**: Configurable

#### Notifications
- Email alerts sent to:
  - Subscription Administrator
  - Subscription Co-Administrator

## Module Architecture

### Module Dependency Graph

```
azurerm_resource_group
    ↓
    ├─→ module.networking
    │       ↓
    │   (Creates VNet, Subnet, Load Balancer, Public IP)
    │       ↓
    │   (Outputs: subnet_ids, lb_backend_pool_id)
    │       ↓
    ├─→ module.compute ─────────────────┐
    │   (depends_on: networking)        │
    │   (receives: lb_backend_pool_id)  │
    │       ↓                            │
    │   (Creates VMSS with LB integration)│
    │       ↓                            │
    └─→ module.monitoring ───────────────┘
        (depends_on: compute)
        ↓
    (Creates Autoscale Settings)
```

### Module Descriptions

#### Networking Module (`modules/networking`)
- **Inputs**: 
  - `project_name`, `environment`, `location`
  - `address_space`, `subnet_prefixes`
  - `resource_group`
  - `subnet_ids`: Self-reference for load balancer configuration
  - `load_balancer_backend_address_pool_id`: Self-reference output
- **Outputs**:
  - `subnet_ids`: List of created subnet IDs
  - `virtual_network_id`: Virtual network ID
  - `load_balancer_id`: Load balancer resource ID
  - `public_ip_id`: Public IP address ID
  - `load_balancer_backend_address_pool_id`: Backend pool ID for VMSS integration
- **Resources**: VNet, Subnet, Load Balancer, Public IP, Backend Pool, Health Probe, LB Rule

#### Compute Module (`modules/compute`)
- **Inputs**:
  - `project_name`, `environment`, `location`
  - `resource_group_name`, `subnet_ids`
  - `administrator_login`, `administrator_password`
  - `ssh_public_key_path`
  - `load_balancer_backend_address_pool_id`: For LB integration
- **Outputs**:
  - `virtual_machine_scale_set_id`: VMSS resource ID
  - `subnet_ids`: Pass-through from input
- **Resources**: 
  - Linux VM Scale Set (with LB backend pool association)
  - SSH Public Key resource

#### Monitoring Module (`modules/monitoring`)
- **Inputs**:
  - `project_name`, `environment`, `location`
  - `resource_group_name`
  - `virtual_machine_scale_set_id`: List of VMSS IDs
  - `subnet_ids`
- **Outputs**: None explicitly defined
- **Resources**: Monitor Autoscale Settings

#### Database Module (`modules/database`)
- **Status**: Defined but not currently deployed
- **Purpose**: Reserved for future database integration

#### Security Module (`modules/security`)
- **Status**: Commented out in main configuration
- **Purpose**: Reserved for NSG, firewall, or WAF configuration

## Environment Architecture

### Multi-Environment Strategy

The infrastructure supports three environments with identical architecture:

```
env/
├── dev/      # Development environment
├── stage/    # Staging environment
└── prod/     # Production environment
```

Each environment contains:
- `backend.tf`: Terraform state backend configuration
- `main.tf`: Environment-specific resource instantiation
- `variables.tf`: Variable declarations
- `terraform.tfvars`: Environment-specific values
- `providers.tf`: Azure provider configuration
- `outputs.tf`: Output definitions

### Environment Isolation
- Separate resource groups per environment
- Independent Terraform state per environment
- Environment-specific variable values
- Isolated networking (no VNet peering configured)

## Data Flow

### 1. Provisioning Flow
```
Terraform Apply
    ↓
Create Resource Group
    ↓
Deploy Networking Resources
    ├─→ Create VNet & Subnet
    ├─→ Create Public IP (Static)
    ├─→ Create Load Balancer (Standard)
    ├─→ Configure Frontend IP
    ├─→ Create Backend Address Pool
    ├─→ Configure Health Probe (TCP:80)
    └─→ Create Load Balancing Rule (80→80)
        ↓
Deploy VM Scale Set
    ├─→ Read SSH public key from local file
    ├─→ Encode cloud-init script
    ├─→ Associate NIC with LB Backend Pool
    └─→ Create VMs with custom_data
        ↓
    Cloud-init executes on each VM
        ↓
    Install Ansible
        ↓
    Clone playbooks from Git
        ↓
    Execute Ansible setup playbook
        ↓
Deploy Autoscale Settings
```

### 2. Runtime Auto-scaling Flow
```
VM Workload Increases
    ↓
CPU Metrics → Azure Monitor
    ↓
Average CPU > 75% for 5 min?
    ↓ Yes
Scale-Out Action
    ↓
+1 VM Instance Provisioned
    ↓
Cloud-init & Ansible Config Applied
    ↓
New VM Joins Scale Set
    ↓
5-minute Cooldown Period
```

## Security Architecture

### Authentication Mechanisms
1. **SSH Key Authentication**: Primary method using user-provided public key
2. **Password Authentication**: Enabled as fallback
3. **Managed Identity**: System-assigned for Azure resource access

### Network Security
- Private IP addressing within VNet for VMs
- Subnet-level isolation
- Public IP address on Load Balancer (not on individual VMs)
- Traffic routing through Load Balancer frontend
- Health probe monitoring ensures only healthy instances receive traffic

### Access Control
- Admin credentials managed via Terraform variables
- SSH keys stored locally, content read at deployment time
- Sensitive values marked in Terraform state

## Scalability Considerations

### Current Limits
- **Horizontal**: Configurable instance count range
- **Vertical**: Configurable VM SKU (upgradable)
- **Network**: Configurable VNet address space

### Scaling Triggers
- **CPU-based**: Primary metric for auto-scaling
- **Threshold Gap**: Configurable gap between scale-out and scale-in prevents flapping
- **Cooldown**: Configurable period prevents rapid scaling oscillation

## High Availability

### Availability Features
- **VM Scale Set**: Distributes VMs across fault domains
- **Instance Count**: Configurable minimum ensures service continuity
- **Auto-healing**: Scale set can replace unhealthy instances
- **Update Mode**: Configurable upgrade mode
- **Load Balancer**: Distributes traffic across healthy instances
- **Health Probes**: Continuous health monitoring on port 80
- **Automatic Failover**: Traffic redirected away from unhealthy instances

### Limitations
- Single subnet deployment
- No availability zones configured
- Single region deployment

## Configuration Management

### Ansible Integration
- **Method**: Cloud-init executes Ansible playbooks on VM startup
- **Repository**: Cloned from Git during provisioning
- **Playbook**: `setup.yml` executed automatically
- **Idempotency**: VMs are configured identically

### Update Strategy
- **VM Updates**: Manual upgrade mode - requires explicit update trigger
- **Configuration Updates**: Requires VM reimaging or manual SSH intervention
- **Code Updates**: Update Ansible repository, reimage VMs or run playbooks manually

## Design Decisions

### Why VM Scale Set?
- Automatic scaling based on demand
- Built-in load distribution
- Simplified instance management
- Cost optimization through scale-in

### Why Cloud-init + Ansible?
- **Cloud-init**: Native to cloud VMs, handles initial bootstrap
- **Ansible**: Declarative, idempotent configuration management
- **Separation of Concerns**: Infrastructure (Terraform) vs Configuration (Ansible)

### Why Ubuntu 18.04 LTS?
- Long-term support (LTS)
- Wide Ansible compatibility
- Familiar to most DevOps teams
- Note: Consider upgrading to 20.04 or 22.04 LTS for extended support

## Future Enhancements

### Potential Additions
1. **Application Gateway**: For HTTP/HTTPS traffic with WAF capabilities
2. **Database Integration**: Deploy accompanying database resources
3. **Security Hardening**: Enable NSG rules, disable password auth
4. **Monitoring Enhancement**: Add Log Analytics workspace, Application Insights
5. **Backup**: Configure Azure Backup for VM protection
6. **Availability Zones**: Distribute VMs across zones for better HA
7. **Private Endpoints**: For enhanced security
8. **Key Vault Integration**: For secrets management
9. **CI/CD Pipeline**: Automate Terraform deployments
10. **SSL/TLS Termination**: Configure HTTPS on load balancer
11. **Multiple Backend Pools**: For different application tiers

## Maintenance Considerations

### Regular Tasks
- Monitor auto-scaling behavior and adjust thresholds
- Update Ansible playbooks in Git repository
- Review and update OS images (Ubuntu version)
- Patch management for running VMs
- Review and rotate SSH keys
- Monitor costs and optimize instance sizing

### State Management
- Terraform state stored per environment
- Backend configuration in `backend.tf`
- State locking recommended for team environments