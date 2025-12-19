# Azure Web Application Infrastructure Architecture

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Azure Subscription                                  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    Resource Group: rg-webapp-dev                        │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │          Virtual Network: vnet-dev (10.0.0.0/16)                  │ │ │
│  │  │                                                                    │ │ │
│  │  │  ┌────────────────────┐  ┌────────────────────┐  ┌─────────────┐ │ │ │
│  │  │  │  Main Subnet       │  │  App Subnet        │  │  DB Subnet  │ │ │ │
│  │  │  │  10.0.1.0/24       │  │  10.0.3.0/24       │  │ 10.0.2.0/24 │ │ │ │
│  │  │  │                    │  │                    │  │             │ │ │ │
│  │  │  │ ┌────────────────┐ │  │  ┌──────────────┐  │  │ ┌─────────┐ │ │ │ │
│  │  │  │ │ App Gateway    │ │  │  │              │  │  │ │ MSSQL   │ │ │ │ │
│  │  │  │ │ Standard_v2    │─┼──┼─►│  Linux Web   │  │  │ │ Server  │ │ │ │ │
│  │  │  │ │ Capacity: 2    │ │  │  │  App (Node)  │◄─┼──┼─┤ v12.0   │ │ │ │ │
│  │  │  │ │ Port: 80       │ │  │  │              │  │  │ │         │ │ │ │ │
│  │  │  │ └────────────────┘ │  │  │  Port: 3000  │  │  │ │Port:1433│ │ │ │ │
│  │  │  │                    │  │  └──────┬───────┘  │  │ └────┬────┘ │ │ │ │
│  │  │  └────────────────────┘  │         │          │  │      │      │ │ │ │
│  │  │                           │    ┌────▼──────┐   │  │  ┌───▼────┐ │ │ │ │
│  │  │                           │    │    NSG    │   │  │  │  NSG   │ │ │ │ │
│  │  │                           │    │ HTTP/HTTPS│   │  │  │Port1433│ │ │ │ │
│  │  │                           │    └───────────┘   │  │  └────────┘ │ │ │ │
│  │  │                           └────────────────────┘  └─────────────┘ │ │ │
│  │  └───────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    App Service Plan                                │ │ │
│  │  │                    (Standard S1 Tier)                              │ │ │
│  │  │                    ┌────────────────┐                              │ │ │
│  │  │                    │ Linux App Svc  │                              │ │ │
│  │  │                    │ Node.js 14 LTS │                              │ │ │
│  │  │                    └────────────────┘                              │ │ │
│  │  └───────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Database Resources                              │ │ │
│  │  │                                                                    │ │ │
│  │  │  ┌──────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │  MSSQL Server: mssql-server-dev                              │ │ │ │
│  │  │  │  ┌────────────────────────────────────────────────────────┐  │ │ │ │
│  │  │  │  │  Database: maindb                                       │  │ │ │ │
│  │  │  │  │  - SKU: S0                                              │  │ │ │ │
│  │  │  │  │  - Size: 2GB                                            │  │ │ │ │
│  │  │  │  │  - Collation: SQL_Latin1_General_CP1_CI_AS             │  │ │ │ │
│  │  │  │  └────────────────────────────────────────────────────────┘  │ │ │ │
│  │  │  └──────────────────────────────────────────────────────────────┘ │ │ │
│  │  └───────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Public IP Address                               │ │ │
│  │  │                    pip-dev (Dynamic)                               │ │ │
│  │  │                    ▲                                               │ │ │
│  │  │                    │                                               │ │ │
│  │  │            Connected to App Gateway                                │ │ │
│  │  └───────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow

```
Internet
   │
   ▼
┌─────────────────┐
│  Public IP      │ (Dynamic)
│  pip-dev        │
└────────┬────────┘
         │
         │ HTTP/HTTPS (80/443)
         ▼
┌─────────────────────────────────┐
│  Application Gateway            │
│  appg-dev                       │
│  - SKU: Standard_v2             │
│  - Capacity: 2                  │
│  - Port: 80                     │
│  - Backend Pool                 │
│  - Routing Rules                │
└────────┬────────────────────────┘
         │
         │ Routes to Main Subnet (10.0.1.0/24)
         ▼
┌─────────────────┐
│  NSG (App)      │ ◄── Allow HTTP/HTTPS from Internet
│  nsg-dev        │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  App Subnet (10.0.3.0/24)       │
│  ┌───────────────────────────┐  │
│  │  Linux Web App            │  │
│  │  - webapp-dev             │  │
│  │  - Node.js 14 LTS         │  │
│  │  - VNet Integration       │  │
│  └───────────┬───────────────┘  │
└──────────────┼──────────────────┘
               │
               │ SQL Query (Port 1433)
               ▼
┌─────────────────────────────────┐
│  NSG (Database)                 │ ◄── Allow 1433 from App Subnet only
│  sg-db-dev                      │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Database Subnet (10.0.2.0/24)  │
│  ┌───────────────────────────┐  │
│  │  MSSQL Server             │  │
│  │  - mssql-server-dev       │  │
│  │  - VNet Rule Enabled      │  │
│  │  └─────────────────────┐  │  │
│  │    Database: maindb    │  │  │
│  │    (S0, 2GB)          │  │  │
│  │    └─────────────────────┘  │  │
│  └─────────────────────────────┘  │
└───────────────────────────────────┘
```

## Module Dependency Graph

```
┌──────────────────┐
│   Root Module    │
│   (main.tf)      │
└────────┬─────────┘
         │
         │ Creates
         ▼
┌────────────────────────────────┐
│  azurerm_resource_group.main  │
└────────────────────────────────┘
         │
         │ Dependencies
         │
    ┌────┴────┬────────────┬───────────────┐
    │         │            │               │
    ▼         ▼            ▼               ▼
┌────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐
│Network │ │Database │ │ Compute │ │ Security │
│ Module │ │ Module  │ │ Module  │ │  Module  │
└───┬────┘ └────┬────┘ └────┬────┘ └────┬─────┘
    │           │           │           │
    │           │           │           │
    │  Outputs: │           │           │
    │  - app    │           │           │
    │  - database│          │           │
    │  - main   │           │           │
    │  - pip_id │           │           │
    │           │           │           │
    └───────────┼───────────┼───────────┘
                │           │
                ▼           ▼
         ┌──────────┐  ┌──────────┐
         │ server_id│  │subnet_ids│
         └──────────┘  └──────────┘
```

## Terraform Module Structure

```
web_app_with_database_infra/
│
├── env/
│   └── dev/
│       ├── main.tf ─────────────► Orchestrates all modules
│       ├── variables.tf ────────► Input variables
│       ├── outputs.tf ──────────► Root level outputs
│       ├── providers.tf ────────► Azure provider configuration
│       ├── backend.tf ──────────► State backend (optional)
│       └── terraform.tfvars ────► Environment values
│
└── modules/
    │
    ├── networking/
    │   ├── main.tf ─────────────► VNet, Subnets, Public IP
    │   ├── variables.tf ────────► Network variables
    │   └── outputs.tf ──────────► Subnet IDs, Public IP
    │
    ├── database/
    │   ├── main.tf ─────────────► MSSQL Server, Database, VNet Rule
    │   ├── variables.tf ────────► Database variables
    │   └── outputs.tf ──────────► Server ID, Database ID
    │
    ├── compute/
    │   ├── main.tf ─────────────► App Service Plan, Web App, VNet Integration
    │   ├── variables.tf ────────► Compute variables
    │   └── output.tf ───────────► App Service details
    │
    └── security/
        ├── main.tf ─────────────► NSGs, Security Rules, Associations
        ├── variables.tf ────────► Security variables
        └── outputs.tf ──────────► NSG IDs
```

## Network Security Groups (NSG) Rules

### App NSG (nsg-dev)
```
Priority │ Name          │ Direction │ Protocol │ Ports  │ Source      │ Destination │ Action
─────────┼───────────────┼───────────┼──────────┼────────┼─────────────┼─────────────┼────────
100      │ Allow-HTTP    │ Inbound   │ TCP      │ 80     │ Internet (*) │ *           │ Allow
110      │ Allow-HTTPS   │ Inbound   │ TCP      │ 443    │ Internet (*) │ *           │ Allow
## Resource Naming Convention

```
Resource Type          │ Naming Pattern                │ Example
───────────────────────┼───────────────────────────────┼──────────────────────────
Resource Group         │ rg-{app}-{env}                │ rg-webapp-dev
Virtual Network        │ vnet-{env}                    │ vnet-dev
Subnet                 │ subnet-{type}-{env}           │ subnet-db-dev
App Service Plan       │ asp-{env}                     │ asp-dev
Web App                │ webapp-{env}                  │ webapp-dev
MSSQL Server           │ mssql-server-{env}            │ mssql-server-dev
Database               │ maindb                        │ maindb
NSG                    │ nsg-{env} / sg-{type}-{env}   │ nsg-dev, sg-db-dev
Public IP              │ pip-{env}                     │ pip-dev
Application Gateway    │ appg-{env}                    │ appg-dev
```
## Data Flow Sequence

```
1. User Request
   │
   ▼
2. Public IP (pip-dev)
   │
   ▼
3. Application Gateway (appg-dev)
   │ - Frontend IP Configuration
   │ - HTTP Listener (Port 80)
   │ - Backend Pool Configuration
   │ - Routing Rules Evaluation
   ▼
7. Linux Web App (webapp-dev)
   │ - Process Request
   │ - Check for Database Query
   ▼
8. Database ConnectionS
   ▼
6. App Subnet (10.0.3.0/24)
   ▼
9. NSG Evaluation (sg-db-dev)
   │ ✓ Allow from App Subnet on Port 1433
   ▼
10. Database Subnet (10.0.2.0/24)
    │
    ▼
11. MSSQL Server (mssql-server-dev)
    │ - VNet Rule Validation
    │ - Query Execution
    ▼
12. Database (maindb)
    │ - Return Results
    ▼
13. Response to Web App
    │
    ▼
14. Response through App Gateway
    │
    ▼
## Security Architecture

```
┌─────────────────────────────────────────────┐
│         Security Layers                      │
├─────────────────────────────────────────────┤
│                                             │
│  Layer 1: Application Gateway               │
│  ├─ Single entry point for HTTP traffic    │
│  ├─ Frontend IP configuration              │
│  ├─ Backend pool management                │
│  └─ Request routing and load balancing     │
│                                             │
│  Layer 2: Network Isolation                │
│  ├─ Separate subnets for app and database  │
│  ├─ Gateway subnet for App Gateway         │
│  └─ VNet integration for private traffic   │
│                                             │
│  Layer 3: Network Security Groups          │
│  ├─ Inbound rules for web traffic          │
│  ├─ Database access limited to app subnet  │
│  └─ Deny all other traffic by default      │
│                                             │
│  Layer 4: Database Security                │
│  ├─ VNet rules for subnet-level access     │
│  ├─ SQL authentication required            │
│  └─ TLS 1.2 encryption enforced            │
│                                             │
│  Layer 5: Application Security             │
│  ├─ System-assigned managed identity       │
│  ├─ Secure connection strings              │
│  └─ Environment-based configuration        │
│                                             │
└─────────────────────────────────────────────┘
```
┌─────────────────────────────────────────────┐
│         Security Layers                      │
├─────────────────────────────────────────────┤
│                                             │
│  Layer 1: Network Isolation                │
│  ├─ Separate subnets for app and database  │
│  └─ VNet integration for private traffic   │
│                                             │
│  Layer 2: Network Security Groups          │
│  ├─ Inbound rules for web traffic          │
│  ├─ Database access limited to app subnet  │
│  └─ Deny all other traffic by default      │
│                                             │
│  Layer 3: Database Security                │
│  ├─ VNet rules for subnet-level access     │
│  ├─ SQL authentication required            │
│  └─ TLS 1.2 encryption enforced            │
│                                             │
│  Layer 4: Application Security             │
│  ├─ System-assigned managed identity       │
│  ├─ Secure connection strings              │
│  └─ Environment-based configuration        │
│                                             │
└─────────────────────────────────────────────┘
```

## Deployment Sequence

```
Step 1: Initialize
├── terraform init
└── Download provider plugins

Step 2: Plan
├── terraform plan
├── Resolve dependencies
└── Show execution plan

Step 3: Apply
└── Deploy Security Module (depends on networking)
    ├── Create NSG for App
    ├── Create NSG for Database
    ├── Associate NSGs with Subnets
    └── Create Application Gateway
        ├── Configure SKU (Standard_v2)
        ├── Set Gateway IP Configuration
        ├── Create Frontend IP (Public IP)
        ├── Create Backend Pool
        ├── Configure HTTP Listener (Port 80)
        ├── Set Backend HTTP Settings
        └── Create Routing Rules
├── Deploy Networking Module
│   ├── Create VNet
│   ├── Create Subnets (main, app, database)
│   └── Create Public IP
│
├── Deploy Database Module (depends on networking)
│   ├── Create MSSQL Server
│   ├── Create Database
│   └── Configure VNet Rule
│
├── Deploy Compute Module (depends on database)
│   ├── Create App Service Plan
│   ├── Create Linux Web App
│   ├── Configure VNet Integration
│   └── Set App Settings
│
└── Deploy Security Module (depends on networking)
    ├── Create NSG for App
    ├── Create NSG for Database
    └── Associate NSGs with Subnets
```

---

**Version**: 1.0  
**Last Updated**: December 18, 2025  
**Terraform Version**: >= 1.0  
**Azure Provider**: 4.1.0
