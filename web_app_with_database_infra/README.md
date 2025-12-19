# Azure Web Application with Database Infrastructure

A production-ready Terraform project that deploys a secure web application infrastructure on Azure with MSSQL database, networking, and security components.

## 📋 Overview

This Terraform project provisions a complete Azure infrastructure for hosting a Node.js web application with the following components:

- **Application Gateway**: Azure Application Gateway (Standard_v2) for load balancing and HTTP routing
- **Compute**: Linux App Service with Node.js 14 LTS runtime
- **Database**: Azure MSSQL Server with database and VNet integration
- **Networking**: Virtual Network with segregated subnets for app, database, and management
- **Security**: Network Security Groups with rule-based access control

## 🏗️ Architecture

```
Resource Group
├── Virtual Network (10.0.0.0/16)
│   ├── Management Subnet (10.0.1.0/24)
│   │   └── Application Gateway (Standard_v2, Capacity: 2)
│   ├── Database Subnet (10.0.2.0/24)
│   └── App Subnet (10.0.3.0/24)
│
├── Public IP Address (Dynamic)
│   └── Connected to Application Gateway
│
├── Application Gateway
│   ├── Frontend IP Configuration (Public IP)
│   ├── Backend Pool (Web App)
│   ├── HTTP Listener (Port 80)
│   └── Routing Rules
│
├── App Service Plan (Standard S1)
│   └── Linux Web App (Node.js 14 LTS)
│       └── VNet Integration with App Subnet
│
├── MSSQL Server (v12.0)
│   ├── Database (S0 tier, 2GB)
│   └── VNet Rule for Database Subnet
│
└── Network Security Groups
    ├── App NSG (HTTP/HTTPS allowed)
    └── Database NSG (Port 1433 from app subnet only)
```

## 📁 Project Structure

```
web_app_with_database_infra/
├── env/
│   ├── dev/
│   │   ├── main.tf              # Root module configuration
│   │   ├── variables.tf         # Input variables
│   │   ├── outputs.tf           # Output values
│   │   ├── providers.tf         # Azure provider configuration
│   │   ├── backend.tf           # State backend configuration
│   │   └── terraform.tfvars     # Environment-specific values
│   ├── stage/                   # Staging environment (placeholder)
│   └── prod/                    # Production environment (placeholder)
│
└── modules/
    ├── compute/                 # App Service resources
    │   ├── main.tf
    │   ├── variables.tf
    │   └── output.tf
    ├── database/                # MSSQL Server and database
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── networking/              # VNet and subnets
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── security/                # Network Security Groups & App Gateway
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.0
- Azure subscription with appropriate permissions
- Azure CLI authenticated (`az login`)

### Installation

1. **Clone the repository**
   ```bash
   cd /path/to/web_app_with_database_infra
   ```

2. **Authenticate with Azure**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Navigate to the environment**
   ```bash
   cd env/dev
   ```

4. **Configure variables**
   
   Edit `terraform.tfvars` with your values:
   ```hcl
   resource_group_name    = "rg-webapp-dev"
   location               = "East US"
   environment            = "dev"
   administrator_login    = "your-admin-username"
   administrator_password = "<use-secure-password>"
   subscription_id        = "<your-subscription-id>"
   ```

5. **Initialize Terraform**
   ```bash
   terraform init
   ```

6. **Review the execution plan**
   ```bash
   terraform plan
   ```

7. **Apply the configuration**
   ```bash
   terraform apply
   ```

## 🔧 Configuration

### Required Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `resource_group_name` | string | Name of the resource group | `rg-webapp-dev` |
| `location` | string | Azure region | `East US` |
| `environment` | string | Environment name | `dev`, `stage`, `prod` |
| `administrator_login` | string | SQL Server admin username | `your-admin-username` |
| `administrator_password` | string | SQL Server admin password | `<secure-password>` |
| `subscription_id` | string | Azure subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `mssql_server_name` | string | MSSQL Server name | `webapp-sqlserver-dev` |
| `mssql_db_name` | string | Database name | `webappdbdev` |

### Network Configuration

Default subnet configuration:
- **Main Subnet**: `10.0.1.0/24` - Management and general resources
- **Database Subnet**: `10.0.2.0/24` - MSSQL Server with VNet rule
- **App Subnet**: `10.0.3.0/24` - App Service VNet integration

## 🔐 Security Features

- **Application Gateway**: Single entry point for all HTTP/HTTPS traffic with centralized routing
- **Network Isolation**: Subnets segregated by function (management, app, database)
- **NSG Rules**: 
  - HTTP (80) and HTTPS (443) allowed to app subnet
  - Database port (1433) restricted to app subnet only
  - Deny all other inbound traffic
- **VNet Integration**: App Service connected to private subnet
- **Database VNet Rule**: MSSQL Server accessible only from database subnet
- **Load Balancing**: Application Gateway Standard_v2 with capacity of 2 instances
- **Sensitive Values**: Passwords marked as sensitive in Terraform

## 📊 Outputs

After deployment, Terraform outputs the following:

```hcl
subnet_ids          # Map of all subnet IDs
mssql_server_name   # MSSQL Server name
mssql_db_name       # Database name
```

## 🔄 Module Dependencies

The modules are deployed in the following order:

1. **Networking** - Creates VNet, subnets, and public IP (no dependencies)
2. **Database** - Depends on networking module for subnet IDs
3. **Compute** - Depends on database module for connection string
4. **Security** - Depends on networking module for subnet associations and Application Gateway configuration

## 🛠️ Maintenance

### Updating Infrastructure

1. Modify the relevant `.tf` files or `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Destroying Infrastructure

```bash
cd env/dev
terraform destroy
```

⚠️ **Warning**: This will delete all resources. Ensure you have backups if needed.

## 📝 Best Practices

1. **Secrets Management**: 
   - Never commit `terraform.tfvars` with real passwords
   - Use Azure Key Vault for production secrets
   - Consider using environment variables for sensitive values

2. **State Management**:
   - Configure remote state backend in `backend.tf`
   - Use Azure Storage Account for team collaboration
   - Enable state locking to prevent concurrent modifications

3. **Environment Management**:
   - Use separate state files for dev/stage/prod
   - Maintain consistent naming conventions
   - Tag resources with environment identifiers

4. **Resource Naming**:
   - Follow Azure naming conventions
   - Use environment suffixes (`-dev`, `-prod`)
   - Ensure globally unique names for resources that require it

## 🐛 Troubleshooting

### Common Issues

**Issue**: "Error: Incorrect attribute value type"
- **Solution**: Ensure subnet `address_prefixes` uses list format: `[var.subnet_prefixes["app"]]`

**Issue**: "Resource names must be globally unique"
- **Solution**: Update `mssql_server_name` in `terraform.tfvars` to a unique value

**Issue**: Authentication errors
- **Solution**: Run `az login` and ensure subscription is set correctly

## 📚 Additional Resources

- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

## 📄 License

This project structure is provided as-is for educational and development purposes.

## 👥 Contributing

For changes or improvements:
1. Test in dev environment first
2. Validate with `terraform validate`
3. Review changes with `terraform plan`
4. Document any new variables or outputs

---

**Version**: 1.0  
**Terraform Version**: >= 1.0  
**Azure Provider Version**: 4.1.0
