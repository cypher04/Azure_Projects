# Hub and Spoke Infrastructure for Multi-Tier Application

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure)](https://azure.microsoft.com/)

## 📋 Overview

This project implements a **Hub and Spoke network topology** on Microsoft Azure using Terraform Infrastructure as Code (IaC). The architecture is designed for deploying secure, scalable multi-tier applications with proper network segmentation, security controls, and database connectivity.

## 🏗️ Architecture

The infrastructure follows a hub-and-spoke network topology pattern:

```
                    ┌─────────────────────────────────────────┐
                    │              INTERNET                    │
                    └─────────────────┬───────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │         Application Gateway              │
                    │         (WAF v2 Enabled)                 │
                    │         + Public IP                      │
                    └─────────────────┬───────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │         Standard Load Balancer           │
                    │         + Private Link Service           │
                    └─────────────────┬───────────────────────┘
                                      │
    ┌─────────────────────────────────┼─────────────────────────────────┐
    │                                 │                                  │
    │                    ┌────────────▼────────────┐                    │
    │                    │       HUB VNET          │                    │
    │                    │  ┌──────────────────┐   │                    │
    │                    │  │ Database Subnet  │   │                    │
    │                    │  │   (Cosmos DB     │   │                    │
    │                    │  │ Private Endpoint)│   │                    │
    │                    │  │ + Private DNS    │   │                    │
    │                    │  └──────────────────┘   │                    │
    │                    │  ┌──────────────────┐   │                    │
    │                    │  │ Delegation Subnet│   │                    │
    │                    │  │(Container Groups)│   │                    │
    │                    │  │ VNet Integration │   │                    │
    │                    │  └──────────────────┘   │                    │
    │                    └────────────┬────────────┘                    │
    │                                 │                                  │
    │              ┌──────────────────┼──────────────────┐              │
    │              │                  │                  │              │
    │   ┌──────────▼──────────┐       │       ┌──────────▼──────────┐   │
    │   │    SPOKE 1 VNET     │       │       │    SPOKE 2 VNET     │   │
    │   │  ┌──────────────┐   │◄──────┴──────►│  ┌──────────────┐   │   │
    │   │  │  Web Subnet  │   │  VNet Peering │  │  App Subnet  │   │   │
    │   │  │ + Private DNS│   │               │  │  (Web App    │   │   │
    │   │  │   Zone Link  │   │               │  │   Private    │   │   │
    │   │  └──────────────┘   │               │  │   Endpoint)  │   │   │
    │   └─────────────────────┘               │  └──────────────┘   │   │
    │                                         └─────────────────────┘   │
    └───────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| **Hub VNet** | Central network containing shared services (database, delegation subnet) |
| **Spoke 1 VNet** | Web tier subnet for frontend services |
| **Spoke 2 VNet** | Application tier subnet with private endpoints |
| **VNet Peering** | Bidirectional connectivity between hub and spoke networks |
| **Application Gateway** | WAF v2 enabled gateway for secure ingress traffic |
| **Load Balancer** | Standard SKU load balancer with public IP frontend |
| **Private Link Service** | Enables private endpoint access to Load Balancer |
| **Azure Cosmos DB** | NoSQL database with private endpoint for secure access |
| **Azure App Service** | Linux-based web application with managed identity |
| **Private DNS Zones** | DNS resolution for App Service and Cosmos DB private endpoints |

## 📁 Project Structure

```
hub_and_spoke_infra_for_multi_tier_app/
├── README.md                    # This documentation file
├── ARCHITECTURE.md              # Detailed architecture documentation
├── PROJECT_STRUCTURE.txt        # Project structure overview
│
├── env/                         # Environment-specific configurations
│   ├── dev/                     # Development environment
│   │   ├── main.tf              # Main configuration & module calls
│   │   ├── variables.tf         # Variable definitions
│   │   ├── outputs.tf           # Output definitions
│   │   ├── providers.tf         # Provider configuration
│   │   ├── backend.tf           # Backend state configuration
│   │   └── terraform.tfvars     # Variable values for dev
│   │
│   ├── stage/                   # Staging environment
│   │   └── ... (same structure as dev)
│   │
│   └── prod/                    # Production environment
│       └── ... (same structure as dev)
│
└── modules/                     # Reusable Terraform modules
    ├── compute/                 # Compute resources (App Service)
    ├── database/                # Database resources (Cosmos DB)
    ├── networking/              # Network resources (VNets, Subnets, Peering)
    └── security/                # Security resources (NSGs, WAF, App Gateway)
```

## 🧩 Modules

### Networking Module (`modules/networking/`)
Manages all network-related resources:
- **Hub VNet** with database and delegation subnets
- **Spoke 1 VNet** with web subnet
- **Spoke 2 VNet** with app subnet
- **VNet Peering** (bidirectional hub-to-spoke connections)
- **Public IP** for Application Gateway

### Compute Module (`modules/compute/`)
Manages compute resources:
- **Azure App Service Plan** (Linux, P1v2 SKU)
- **Linux Web App** with:
  - System-assigned managed identity
  - Client certificate authentication
  - App Service to Cosmos DB connection via Service Connector
- **Private DNS Zone** for web app (`privatelink.azurewebsites.net`) linked to Spoke 1 VNet
- **Private DNS Zone** for Cosmos DB (`privatelink.documents.azure.com`) linked to Hub VNet

### Database Module (`modules/database/`)
Manages database resources:
- **Azure Cosmos DB Account** (GlobalDocumentDB)
  - System-assigned managed identity
  - Private network access only
  - Periodic backup enabled
- **Cosmos DB SQL Database**
- **Cosmos DB SQL Container** with indexing policies

### Security Module (`modules/security/`)
Manages security resources:
- **Network Security Groups** (NSGs) for:
  - Hub database subnet (HTTPS, SQL, deny all)
  - Web subnet (HTTPS allowed)
  - App subnet (SSH allowed from specific sources)
- **NSG-Subnet Associations**
- **Application Gateway** (WAF_v2 SKU) with:
  - Autoscaling (2-5 instances)
  - Health probes
  - Backend pool configuration
- **Web Application Firewall (WAF) Policy**:
  - OWASP 3.2 managed rules
  - Custom bot blocking rules
  - Prevention mode enabled

## 🔒 Security Features

| Feature | Implementation |
|---------|----------------|
| **Network Segmentation** | Hub-and-spoke topology with separate subnets for each tier |
| **Private Endpoints** | Cosmos DB and App Service accessible only via private network |
| **Private DNS Zones** | Automatic DNS resolution for private endpoints (App Service & Cosmos DB) |
| **Private Link Service** | Enables secure access to Load Balancer via private endpoints |
| **WAF Protection** | Application Gateway with WAF v2 and OWASP 3.2 rules |
| **NSG Rules** | Granular inbound/outbound traffic control per subnet |
| **Managed Identity** | System-assigned identities for secure service-to-service auth |
| **TLS/SSL** | HTTPS enforced throughout the infrastructure |
| **Client Certificates** | App Service requires client certificate authentication |

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.0
- Azure subscription with appropriate permissions
- Bash or compatible shell

### Authentication

```bash
# Login to Azure
az login

# Set your subscription (optional)
az account set --subscription "<subscription-id>"
```

### Deployment

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hub_and_spoke_infra_for_multi_tier_app
   ```

2. **Navigate to the desired environment**
   ```bash
   cd env/dev  # or stage, prod
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the plan**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

6. **Confirm the deployment** by typing `yes` when prompted

### Environment Variables

Each environment has its own `terraform.tfvars` file. Key variables include:

| Variable | Description | Example |
|----------|-------------|---------|
| `resource_group` | Name of the Azure resource group | `rg-hub_and_spoke-dev` |
| `location` | Azure region for deployment | `East US` |
| `project_name` | Project identifier | `hub_and_spoke_infra_for_multi_tier_app` |
| `environment` | Environment name | `dev`, `stage`, `prod` |
| `address_space` | VNet address space | `["10.0.1.0/24"]` |
| `subnet_prefixes` | Subnet CIDR blocks | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` |
| `delegation_subnet` | Delegation subnet CIDR | `["10.0.4.0/24"]` |

## 📤 Outputs

After deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `resource_group_name` | Name of the created resource group |
| `location` | Azure region of the deployment |
| `network_security_group_id` | ID of the hub NSG |
| `public_ip_id` | ID of the Application Gateway public IP |
| `sql_database_id` | ID of the Cosmos DB SQL database |
| `project_name` | Project identifier |
| `environment` | Deployed environment |

## 🔧 Customization

### Adding a New Environment

1. Copy an existing environment folder:
   ```bash
   cp -r env/dev env/newenv
   ```

2. Update `terraform.tfvars` with environment-specific values

3. Configure backend state storage in `backend.tf` (if using remote state)

### Modifying Network Configuration

Update subnet prefixes in `terraform.tfvars`:
```hcl
subnet_prefixes = [
    "10.0.1.0/24",   # Database subnet (Hub)
    "10.0.2.0/24",   # Web subnet (Spoke 1)
    "10.0.3.0/24"    # App subnet (Spoke 2)
]
```

### Scaling the Application Gateway

Modify autoscale settings in `modules/security/main.tf`:
```hcl
autoscale_configuration {
  min_capacity = 2   # Minimum instances
  max_capacity = 10  # Maximum instances
}
```

## 🧹 Cleanup

To destroy all resources:

```bash
cd env/dev  # or your environment
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources created by this configuration.

## 📊 Cost Considerations

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| Application Gateway (WAF_v2) | ~$250-500 |
| Load Balancer (Standard) | ~$20-50 |
| App Service (P1v2) | ~$80-150 |
| Cosmos DB (Standard) | ~$25-100+ (based on RUs) |
| Private Link Service | ~$10-30 |
| Private DNS Zones | Minimal (~$0.50/zone) |
| VNet/Subnets | Minimal (data transfer charges apply) |

*Costs vary by region and usage. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 References

- [Azure Hub-Spoke Network Topology](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Azure Cosmos DB Documentation](https://docs.microsoft.com/en-us/azure/cosmos-db/)
- [Azure Application Gateway with WAF](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/ag-overview)
