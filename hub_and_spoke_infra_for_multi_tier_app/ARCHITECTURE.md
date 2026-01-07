# Architecture Documentation

## Hub and Spoke Infrastructure for Multi-Tier Application

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Network Topology](#network-topology)
4. [Component Details](#component-details)
5. [Security Architecture](#security-architecture)
6. [Data Flow](#data-flow)
7. [High Availability & Scalability](#high-availability--scalability)
8. [Design Decisions](#design-decisions)

---

## Overview

This architecture implements a **Hub and Spoke network topology** on Microsoft Azure, designed for deploying secure, scalable multi-tier applications. The pattern provides centralized connectivity management while allowing workload isolation through spoke networks.

### Key Architectural Principles

| Principle | Implementation |
|-----------|----------------|
| **Defense in Depth** | Multiple security layers: WAF, NSGs, Private Endpoints, Managed Identity |
| **Least Privilege** | System-assigned managed identities with minimal required permissions |
| **Network Segmentation** | Separate subnets for each application tier |
| **Zero Trust** | Private endpoints eliminate public internet exposure for data tier |
| **Infrastructure as Code** | Terraform modules for repeatable, version-controlled deployments |

---

## Architecture Diagram

### High-Level Overview

```
                                    ┌────────────────────────────────┐
                                    │           INTERNET             │
                                    └───────────────┬────────────────┘
                                                    │
                                    ┌───────────────▼────────────────┐
                                    │      Azure Public IP           │
                                    │    (Static, Standard SKU)      │
                                    └───────────────┬────────────────┘
                                                    │
                    ┌───────────────────────────────▼───────────────────────────────┐
                    │                    APPLICATION GATEWAY                         │
                    │                      (WAF_v2 SKU)                              │
                    │  ┌─────────────────────────────────────────────────────────┐  │
                    │  │  • OWASP 3.2 Managed Rules                              │  │
                    │  │  • Custom Bot Protection Rules                          │  │
                    │  │  • Prevention Mode Enabled                              │  │
                    │  │  • Autoscaling: 2-5 instances                           │  │
                    │  │  • Health Probes for Backend                            │  │
                    │  └─────────────────────────────────────────────────────────┘  │
                    └───────────────────────────────┬───────────────────────────────┘
                                                    │
    ════════════════════════════════════════════════╪════════════════════════════════════
                                      AZURE VIRTUAL NETWORK
    ════════════════════════════════════════════════╪════════════════════════════════════
                                                    │
            ┌───────────────────────────────────────┼───────────────────────────────────┐
            │                                       │                                    │
            │                    ┌──────────────────▼──────────────────┐                │
            │                    │            HUB VNET                  │                │
            │                    │         (10.0.1.0/24)               │                │
            │                    │                                      │                │
            │                    │  ┌──────────────────────────────┐   │                │
            │                    │  │     DATABASE SUBNET          │   │                │
            │                    │  │      (10.0.1.0/24)           │   │                │
            │                    │  │                              │   │                │
            │                    │  │  ┌────────────────────────┐  │   │                │
            │                    │  │  │   COSMOS DB PRIVATE    │  │   │                │
            │                    │  │  │      ENDPOINT          │  │   │                │
            │                    │  │  │  • GlobalDocumentDB    │  │   │                │
            │                    │  │  │  • Session Consistency │  │   │                │
            │                    │  │  │  • Private Access Only │  │   │                │
            │                    │  │  └────────────────────────┘  │   │                │
            │                    │  │                              │   │                │
            │                    │  │  [NSG: Hub-Database]         │   │                │
            │                    │  │  • Allow HTTPS from Web      │   │                │
            │                    │  │  • Allow SQL (1433)          │   │                │
            │                    │  │  • Deny All Inbound          │   │                │
            │                    │  └──────────────────────────────┘   │                │
            │                    │                                      │                │
            │                    │  ┌──────────────────────────────┐   │                │
            │                    │  │    DELEGATION SUBNET         │   │                │
            │                    │  │      (10.0.4.0/24)           │   │                │
            │                    │  │                              │   │                │
            │                    │  │  Delegated to:               │   │                │
            │                    │  │  Microsoft.ContainerInstance │   │                │
            │                    │  │  /containerGroups            │   │                │
            │                    │  │                              │   │                │
            │                    │  │  [App Service VNet Swift     │   │                │
            │                    │  │   Connection - Outbound]     │   │                │
            │                    │  └──────────────────────────────┘   │                │
            │                    │                                      │                │
            │                    └──────────────────┬──────────────────┘                │
            │                                       │                                    │
            │                          VNet Peering │ (Bidirectional)                   │
            │                    ┌──────────────────┼──────────────────┐                │
            │                    │                  │                  │                │
            │     ┌──────────────▼──────────────┐   │   ┌──────────────▼──────────────┐ │
            │     │        SPOKE 1 VNET         │   │   │        SPOKE 2 VNET         │ │
            │     │       (10.0.2.0/24)         │   │   │       (10.0.3.0/24)         │ │
            │     │                             │   │   │                             │ │
            │     │  ┌───────────────────────┐  │   │   │  ┌───────────────────────┐  │ │
            │     │  │      WEB SUBNET       │  │   │   │  │      APP SUBNET       │  │ │
            │     │  │     (10.0.2.0/24)     │  │◄──┴──►│  │     (10.0.3.0/24)     │  │ │
            │     │  │                       │  │       │  │                       │  │ │
            │     │  │  [NSG: Web]           │  │       │  │  ┌─────────────────┐  │  │ │
            │     │  │  • Allow HTTPS (443)  │  │       │  │  │  APP SERVICE    │  │  │ │
            │     │  │    from Internet      │  │       │  │  │  PRIVATE        │  │  │ │
            │     │  │                       │  │       │  │  │  ENDPOINT       │  │  │ │
            │     │  │  Private DNS Zone     │  │       │  │  │                 │  │  │ │
            │     │  │  Link for Web Apps    │  │       │  │  │  • Linux P1v2   │  │  │ │
            │     │  │                       │  │       │  │  │  • Managed ID   │  │  │ │
            │     │  └───────────────────────┘  │       │  │  │  • Client Cert  │  │  │ │
            │     │                             │       │  │  └─────────────────┘  │  │ │
            │     └─────────────────────────────┘       │  │                       │  │ │
            │                                           │  │  [NSG: App]           │  │ │
            │                                           │  │  • Allow SSH (22)     │  │ │
            │                                           │  │    from Web Subnet    │  │ │
            │                                           │  └───────────────────────┘  │ │
            │                                           │                             │ │
            │                                           └─────────────────────────────┘ │
            │                                                                            │
            └────────────────────────────────────────────────────────────────────────────┘
```

### Detailed Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              AZURE RESOURCE GROUP                                        │
│                     rg-hub_and_spoke_infra_for_multi_tier_app-{env}                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                           NETWORKING MODULE                                      │    │
│  │                                                                                  │    │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                  │    │
│  │  │    Hub VNet     │  │   Spoke 1 VNet  │  │   Spoke 2 VNet  │                  │    │
│  │  │                 │  │                 │  │                 │                  │    │
│  │  │ • DB Subnet     │  │ • Web Subnet    │  │ • App Subnet    │                  │    │
│  │  │ • Del Subnet    │  │                 │  │                 │                  │    │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘                  │    │
│  │           │                    │                    │                           │    │
│  │           └────────────────────┼────────────────────┘                           │    │
│  │                                │                                                │    │
│  │                    ┌───────────▼───────────┐                                    │    │
│  │                    │    VNet Peerings      │                                    │    │
│  │                    │  • Hub ⟷ Spoke1       │                                    │    │
│  │                    │  • Hub ⟷ Spoke2       │                                    │    │
│  │                    └───────────────────────┘                                    │    │
│  │                                                                                  │    │
│  │  ┌─────────────────────────────────────────┐                                    │    │
│  │  │            Public IP (Static)           │                                    │    │
│  │  │          Standard SKU for App GW        │                                    │    │
│  │  └─────────────────────────────────────────┘                                    │    │
│  │                                                                                  │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                            COMPUTE MODULE                                        │    │
│  │                                                                                  │    │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐    │    │
│  │  │                    App Service Plan (Linux P1v2)                        │    │    │
│  │  │                                                                          │    │    │
│  │  │  ┌────────────────────────────────────────────────────────────────┐     │    │    │
│  │  │  │                    Linux Web App                                │     │    │    │
│  │  │  │                                                                 │     │    │    │
│  │  │  │  • System-Assigned Managed Identity                            │     │    │    │
│  │  │  │  • Client Certificate Authentication (Required)                │     │    │    │
│  │  │  │  • Auth Settings Enabled                                       │     │    │    │
│  │  │  │  • Connected to Cosmos DB via Service Connector                │     │    │    │
│  │  │  │                                                                 │     │    │    │
│  │  │  └────────────────────────────────────────────────────────────────┘     │    │    │
│  │  │                                                                          │    │    │
│  │  └─────────────────────────────────────────────────────────────────────────┘    │    │
│  │                                                                                  │    │
│  │  ┌───────────────────────────────────────┐                                      │    │
│  │  │     Private DNS Zone                  │                                      │    │
│  │  │  privatelink.azurewebsites.net        │                                      │    │
│  │  │  (Linked to Spoke 1 VNet)             │                                      │    │
│  │  └───────────────────────────────────────┘                                      │    │
│  │                                                                                  │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                            DATABASE MODULE                                       │    │
│  │                                                                                  │    │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐    │    │
│  │  │                    Cosmos DB Account                                     │    │    │
│  │  │                                                                          │    │    │
│  │  │  • Kind: GlobalDocumentDB                                               │    │    │
│  │  │  • Offer: Standard                                                       │    │    │
│  │  │  • Consistency: Session                                                  │    │    │
│  │  │  • Public Network Access: DISABLED                                       │    │    │
│  │  │  • System-Assigned Managed Identity                                      │    │    │
│  │  │  • Periodic Backup (300 hours retention)                                │    │    │
│  │  │                                                                          │    │    │
│  │  │  ┌────────────────────────┐  ┌────────────────────────┐                 │    │    │
│  │  │  │    SQL Database        │  │    SQL Container       │                 │    │    │
│  │  │  │                        │  │                        │                 │    │    │
│  │  │  │                        │  │  • Partition: /partKey │                 │    │    │
│  │  │  │                        │  │  • Throughput: 400 RUs │                 │    │    │
│  │  │  │                        │  │  • Consistent Indexing │                 │    │    │
│  │  │  └────────────────────────┘  └────────────────────────┘                 │    │    │
│  │  │                                                                          │    │    │
│  │  └─────────────────────────────────────────────────────────────────────────┘    │    │
│  │                                                                                  │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                            SECURITY MODULE                                       │    │
│  │                                                                                  │    │
│  │  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐              │    │
│  │  │   NSG: Hub-DB     │ │   NSG: Web        │ │   NSG: App        │              │    │
│  │  │                   │ │                   │ │                   │              │    │
│  │  │ • Allow HTTPS     │ │ • Allow HTTPS     │ │ • Allow SSH       │              │    │
│  │  │ • Allow SQL 1433  │ │   from *          │ │   from Web subnet │              │    │
│  │  │ • Deny All        │ │                   │ │                   │              │    │
│  │  └───────────────────┘ └───────────────────┘ └───────────────────┘              │    │
│  │                                                                                  │    │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐    │    │
│  │  │                    Application Gateway (WAF_v2)                          │    │    │
│  │  │                                                                          │    │    │
│  │  │  • Autoscale: Min 2, Max 5 instances                                    │    │    │
│  │  │  • Frontend: Public IP, Port 80                                         │    │    │
│  │  │  • Backend: HTTPS 443 with Health Probes                                │    │    │
│  │  │  • System-Assigned Managed Identity                                      │    │    │
│  │  │                                                                          │    │    │
│  │  └─────────────────────────────────────────────────────────────────────────┘    │    │
│  │                                                                                  │    │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐    │    │
│  │  │                    WAF Policy                                            │    │    │
│  │  │                                                                          │    │    │
│  │  │  • Mode: Prevention                                                      │    │    │
│  │  │  • Managed Rules: OWASP 3.2                                             │    │    │
│  │  │  • Custom Rule: Block Bad Bots                                          │    │    │
│  │  │  • Request Body Check: Enabled                                          │    │    │
│  │  │  • File Upload Limit: 100 MB                                            │    │    │
│  │  │  • Max Request Body: 128 KB                                             │    │    │
│  │  │                                                                          │    │    │
│  │  └─────────────────────────────────────────────────────────────────────────┘    │    │
│  │                                                                                  │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                         PRIVATE ENDPOINTS (Root Module)                          │    │
│  │                                                                                  │    │
│  │  ┌───────────────────────────────────┐  ┌───────────────────────────────────┐   │    │
│  │  │  App Service Private Endpoint     │  │  Cosmos DB Private Endpoint       │   │    │
│  │  │  (Spoke 2 - App Subnet)           │  │  (Hub - Database Subnet)          │   │    │
│  │  │  Subresource: sites               │  │  Subresource: Sql                 │   │    │
│  │  └───────────────────────────────────┘  └───────────────────────────────────┘   │    │
│  │                                                                                  │    │
│  │  ┌───────────────────────────────────────────────────────────────────────────┐  │    │
│  │  │            VNet Swift Connection (App Service Outbound)                    │  │    │
│  │  │                    Connected to Delegation Subnet                          │  │    │
│  │  └───────────────────────────────────────────────────────────────────────────┘  │    │
│  │                                                                                  │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Network Topology

### Hub and Spoke Pattern

The hub-and-spoke topology provides:

1. **Centralized Services**: Shared resources (database, security appliances) in the hub
2. **Workload Isolation**: Each spoke contains separate workloads
3. **Controlled Communication**: All traffic flows through the hub
4. **Simplified Management**: Centralized networking policies

### IP Address Allocation

| Network | CIDR Block | Purpose |
|---------|------------|---------|
| Hub VNet | 10.0.1.0/24 | Central hub network |
| Database Subnet | 10.0.1.0/24 | Cosmos DB private endpoint |
| Delegation Subnet | 10.0.4.0/24 | Container Groups / VNet Integration |
| Spoke 1 VNet | 10.0.2.0/24 | Web tier network |
| Web Subnet | 10.0.2.0/24 | Frontend services |
| Spoke 2 VNet | 10.0.3.0/24 | Application tier network |
| App Subnet | 10.0.3.0/24 | App Service private endpoint |

### VNet Peering Configuration

```
Hub VNet ◄────────────────► Spoke 1 VNet
    │                           │
    │   hub-to-spoke1-peering   │
    │   spoke1-to-hub-peering   │
    │                           │
    ▼                           ▼
Hub VNet ◄────────────────► Spoke 2 VNet
    │                           │
    │   hub-to-spoke2-peering   │
    │   spoke2-to-hub-peering   │
    │                           │
```

---

## Component Details

### 1. Networking Components

| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| Hub VNet | Central network | Hosts database and delegation subnets |
| Spoke 1 VNet | Web tier | Contains web subnet with DNS zone link |
| Spoke 2 VNet | App tier | Contains app subnet with private endpoint |
| VNet Peering | Connectivity | Bidirectional peering for traffic flow |
| Public IP | Ingress | Static IP for Application Gateway |

### 2. Compute Components

| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| App Service Plan | Hosting | Linux OS, P1v2 SKU |
| Linux Web App | Application | Managed Identity, Client Certs |
| Service Connector | Integration | Connects App to Cosmos DB |
| Private DNS Zone | Name Resolution | privatelink.azurewebsites.net |

### 3. Database Components

| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| Cosmos DB Account | Data Storage | GlobalDocumentDB, Session Consistency |
| SQL Database | Data Container | Cosmos SQL API database |
| SQL Container | Data Collection | 400 RU/s, Partition Key indexing |

### 4. Security Components

| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| Application Gateway | Load Balancer | WAF_v2, Autoscale 2-5 |
| WAF Policy | Web Protection | OWASP 3.2, Prevention Mode |
| NSG (Hub) | Database Security | HTTPS + SQL allowed, deny all |
| NSG (Web) | Frontend Security | HTTPS from anywhere |
| NSG (App) | Backend Security | SSH from web subnet only |

---

## Security Architecture

### Defense in Depth Layers

```
Layer 1: Internet Edge
├── Azure DDoS Protection (implicit)
├── Application Gateway with WAF
│   ├── OWASP 3.2 Rule Set
│   ├── Custom Bot Protection
│   └── Rate Limiting
│
Layer 2: Network Segmentation
├── Hub-and-Spoke VNet Topology
├── Subnet Isolation
├── VNet Peering Controls
│
Layer 3: Network Security Groups
├── Hub NSG (Database Protection)
├── Web NSG (Frontend Rules)
├── App NSG (Backend Rules)
│
Layer 4: Private Connectivity
├── Private Endpoints (No Public IPs)
├── VNet Integration (Outbound)
├── Service Endpoints
│
Layer 5: Application Security
├── Client Certificate Authentication
├── Managed Identity (No Secrets)
├── Auth Settings (Redirect Unauthenticated)
│
Layer 6: Data Protection
├── Cosmos DB Encryption at Rest
├── Private Network Access Only
├── Periodic Backup (300 hours)
```

### Network Security Rules Summary

#### Hub Database NSG

| Priority | Name | Direction | Protocol | Port | Source | Destination | Action |
|----------|------|-----------|----------|------|--------|-------------|--------|
| 100 | Allow-HTTPS | Inbound | TCP | 443 | Web Subnet | Database Subnet | Allow |
| 101 | Deny-All-Inbound | Inbound | TCP | 443 | * | * | Deny |
| 120 | Allow-SQL | Inbound | TCP | 1433 | * | * | Allow |

#### Web NSG

| Priority | Name | Direction | Protocol | Port | Source | Destination | Action |
|----------|------|-----------|----------|------|--------|-------------|--------|
| 100 | Allow-HTTPS | Inbound | TCP | 443 | * | * | Allow |

#### App NSG

| Priority | Name | Direction | Protocol | Port | Source | Destination | Action |
|----------|------|-----------|----------|------|--------|-------------|--------|
| 110 | Allow-SSH | Inbound | TCP | 22 | App Subnet | * | Allow |

---

## Data Flow

**Resources defined in Terraform for data flow:**
- `azurerm_application_gateway.appgw` - WAF_v2 with autoscale 2-5 instances
- `azurerm_public_ip.public_ip` - Static Standard SKU
- `azurerm_private_endpoint.pe-appservice` - App Service private endpoint in Spoke 2
- `azurerm_private_endpoint.pe-cosmosdb` - Cosmos DB private endpoint in Hub
- `azurerm_app_service_virtual_network_swift_connection` - VNet integration for outbound
- `azurerm_private_dns_zone.pdz` - `privatelink.azurewebsites.net` linked to Spoke 1

### Inbound Traffic Flow (User Request)

```
User Request
    │
    ▼
┌─────────────────────────────────┐
│         Public IP               │
│  (azurerm_public_ip.public_ip)  │
│    Standard SKU, Static         │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│     Application Gateway         │
│  (azurerm_application_gateway.  │
│   appgw) - WAF_v2               │
│                                 │
│  1. WAF Inspection              │
│     (azurerm_web_application_   │
│      firewall_policy.webafw)    │
│  2. OWASP 3.2 Rule Check        │
│  3. Custom Rule: BlockBadBots   │
│  4. Health Probe Validation     │
│  5. Route to Backend Pool       │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│   Private DNS Zone              │
│  (azurerm_private_dns_zone.pdz) │
│                                 │
│  privatelink.azurewebsites.net  │
│  Linked to: Spoke 1 VNet        │
│  (azurerm_private_dns_zone_     │
│   virtual_network_link)         │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│   App Service Private Endpoint  │
│  (azurerm_private_endpoint.     │
│   pe-appservice)                │
│                                 │
│  Subnet: Spoke 2 - App Subnet   │
│  Subresource: sites             │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│        Linux Web App            │
│  (azurerm_linux_web_app.        │
│   web_app)                      │
│                                 │
│  1. client_certificate_mode =   │
│     "Required"                  │
│  2. auth_settings.enabled =     │
│     true                        │
│  3. Application Logic           │
│  4. Database Query via          │
│     Service Connector           │
└─────────────────┬───────────────┘
                  │
                  ▼ (via azurerm_app_service_virtual_network_swift_connection)
┌─────────────────────────────────┐
│      Delegation Subnet          │
│  (azurerm_subnet.del-subnet)    │
│       (Hub VNet)                │
│                                 │
│  Microsoft.ContainerInstance    │
│  /containerGroups delegation    │
└─────────────────┬───────────────┘
                  │
                  ▼ (Internal Hub VNet routing)
┌─────────────────────────────────┐
│  Cosmos DB Private Endpoint     │
│  (azurerm_private_endpoint.     │
│   pe-cosmosdb)                  │
│                                 │
│  Subnet: Hub - Database Subnet  │
│  Subresource: Sql               │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│       Azure Cosmos DB           │
│  (azurerm_cosmosdb_account.     │
│   cosmosdb)                     │
│                                 │
│  public_network_access_enabled  │
│  = false                        │
└─────────────────────────────────┘
```

### Outbound Traffic Flow (Application to Database & External)

The infrastructure uses VNet Swift Connection to route App Service outbound traffic through the delegation subnet in the Hub VNet.

**Resources defined in Terraform:**
- `azurerm_app_service_virtual_network_swift_connection` - Connects App Service to delegation subnet
- `azurerm_private_endpoint.pe-cosmosdb` - Private endpoint for Cosmos DB in Hub database subnet
- `azurerm_private_endpoint.pe-appservice` - Private endpoint for App Service in Spoke 2 app subnet
- `azurerm_private_dns_zone.pdz` - Private DNS Zone `privatelink.azurewebsites.net` (linked to Spoke 1 VNet)
- `azurerm_app_service_connection` - Service Connector using System Assigned Managed Identity

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           OUTBOUND DATA FLOW PATHS                               │
│                        (Based on Terraform Configuration)                        │
└─────────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════
PATH 1: Application to Cosmos DB (Internal - Private Network)
═══════════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────┐
│        Linux Web App            │
│                                 │
│  1. App generates DB query      │
│  2. Uses System Assigned        │
│     Managed Identity            │
│  3. Connects via Service        │
│     Connector (azurerm_app_     │
│     service_connection)         │
└─────────────────┬───────────────┘
                  │
                  ▼ VNet Swift Connection
                    (azurerm_app_service_virtual_network_swift_connection)
┌─────────────────────────────────┐
│      Delegation Subnet          │
│       (10.0.4.0/24)             │
│       (Hub VNet)                │
│                                 │
│  Microsoft.ContainerInstance    │
│  /containerGroups delegation    │
│                                 │
│  • Outbound IP assigned from    │
│    delegation subnet range      │
└─────────────────┬───────────────┘
                  │
                  ▼ Internal Hub VNet Routing
┌─────────────────────────────────┐
│  Cosmos DB Private Endpoint     │
│    (Hub - Database Subnet)      │
│    (azurerm_private_endpoint.   │
│     pe-cosmosdb)                │
│                                 │
│  Subresource: Sql               │
│  Subnet: hub-subnet-database    │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│       Azure Cosmos DB           │
│  (azurerm_cosmosdb_account)     │
│                                 │
│  • Session Consistency          │
│  • GlobalDocumentDB             │
│  • public_network_access_       │
│    enabled = false              │
│  • 400 RU/s throughput          │
└─────────────────────────────────┘

⚠️  NOTE: No Private DNS Zone exists for Cosmos DB (privatelink.documents.azure.com).
    DNS resolution for the Cosmos DB private endpoint may require manual configuration
    or rely on Azure-provided DNS.

═══════════════════════════════════════════════════════════════════════════════════
PATH 2: Response Flow (Database to User)
═══════════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────┐
│       Azure Cosmos DB           │
│   (Query Response)              │
└─────────────────┬───────────────┘
                  │
                  ▼ Private Endpoint (Reverse Path)
┌─────────────────────────────────┐
│  Cosmos DB Private Endpoint     │
│    (Hub - Database Subnet)      │
└─────────────────┬───────────────┘
                  │
                  ▼ VNet Swift Connection (Return)
┌─────────────────────────────────┐
│      Delegation Subnet          │
│       (Hub VNet)                │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│        Linux Web App            │
│                                 │
│  1. Process DB response         │
│  2. Build HTTP response         │
│  3. Return to client            │
└─────────────────┬───────────────┘
                  │
                  ▼ App Service Private Endpoint
                    (azurerm_private_endpoint.pe-appservice)
┌─────────────────────────────────┐
│   App Service Private Endpoint  │
│   (Spoke 2 - App Subnet)        │
│                                 │
│   Subresource: sites            │
└─────────────────┬───────────────┘
                  │
                  ▼ Backend Pool Connection
┌─────────────────────────────────┐
│     Application Gateway         │
│  (azurerm_application_gateway)  │
│         (WAF_v2)                │
│                                 │
│  1. Receive backend response    │
│  2. Apply response headers      │
│  3. Route to frontend           │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│         Public IP               │
│  (azurerm_public_ip.public_ip)  │
│    Standard SKU, Static         │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│           INTERNET              │
│      (Response to User)         │
└─────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════
PATH 3: Application to External Services (Internet Egress)
═══════════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────┐
│        Linux Web App            │
│                                 │
│  External API/service calls     │
└─────────────────┬───────────────┘
                  │
                  ▼ VNet Swift Connection
┌─────────────────────────────────┐
│      Delegation Subnet          │
│       (10.0.4.0/24)             │
│       (Hub VNet)                │
│                                 │
│  Outbound traffic uses          │
│  delegation subnet's IP range   │
└─────────────────┬───────────────┘
                  │
                  ▼ Default Azure SNAT (No NAT Gateway configured)
┌─────────────────────────────────┐
│      Azure Platform SNAT        │
│                                 │
│  • Dynamic outbound IP          │
│  • Default Azure behavior       │
│  • No NAT Gateway in Terraform  │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│           INTERNET              │
│    (External Services/APIs)     │
└─────────────────────────────────┘
```

### Private DNS Configuration (As Defined in Terraform)

| Resource | Zone Name | Linked VNet | Purpose |
|----------|-----------|-------------|---------|
| `azurerm_private_dns_zone.pdz` | `privatelink.azurewebsites.net` | Spoke 1 VNet | App Service name resolution |

**⚠️ Gap Identified:** No `privatelink.documents.azure.com` Private DNS Zone is defined for Cosmos DB private endpoint resolution.

### Outbound Traffic Security Controls (Implemented)

| Layer | Control | Terraform Resource |
|-------|---------|-------------------|
| **VNet Integration** | Delegation Subnet | `azurerm_app_service_virtual_network_swift_connection` |
| **Private Endpoints** | Cosmos DB, App Service | `azurerm_private_endpoint.pe-cosmosdb`, `azurerm_private_endpoint.pe-appservice` |
| **Managed Identity** | SystemAssigned | `identity { type = "SystemAssigned" }` on Web App |
| **Service Connector** | DB Authentication | `azurerm_app_service_connection` |
| **NSG (Default)** | Outbound Allow | No explicit outbound deny rules defined |

### Outbound Connection Summary

| Destination | Connection Method | Terraform Resource |
|-------------|-------------------|-------------------|
| Cosmos DB | Private Endpoint (Hub VNet) | `azurerm_private_endpoint.pe-cosmosdb` |
| Internet | Default Azure SNAT | VNet Swift Connection → Azure SNAT |

### Infrastructure Gaps (Not in Terraform)

The following are **NOT** currently defined in the Terraform configuration:

1. **Private DNS Zone for Cosmos DB** (`privatelink.documents.azure.com`)
2. **NAT Gateway** - No predictable outbound IP for internet egress
3. **Azure Firewall** - No central egress filtering
4. **Service Endpoints** - Not configured for any Azure services
5. **User Defined Routes (UDR)** - No custom routing tables

---

## High Availability & Scalability

### Current Implementation

| Component | HA/Scaling Feature |
|-----------|-------------------|
| Application Gateway | Autoscale 2-5 instances |
| App Service | P1v2 SKU (scale up available) |
| Cosmos DB | Single region, Session consistency |
| VNet | Zone-redundant by design |

### Recommended Enhancements for Production

1. **Multi-Region Cosmos DB**: Add geo-replication for disaster recovery
2. **App Service Slots**: Implement deployment slots for zero-downtime deployments
3. **Azure Front Door**: Add global load balancing and CDN
4. **Availability Zones**: Deploy App Gateway across zones
5. **Autoscaling Rules**: Add horizontal scaling for App Service

---

## Design Decisions

### Why Hub-and-Spoke?

| Consideration | Decision |
|---------------|----------|
| **Centralized Security** | Shared security resources in hub reduce costs |
| **Workload Isolation** | Spokes provide network boundary for each tier |
| **Simplified Management** | Central hub for routing and policy management |
| **Scalability** | Easy to add new spokes for additional workloads |

### Why Private Endpoints?

| Consideration | Decision |
|---------------|----------|
| **Zero Public Exposure** | Database never exposed to internet |
| **VNet Integration** | Traffic stays within Azure backbone |
| **Compliance** | Meets data residency requirements |
| **Performance** | Lower latency without internet routing |

### Why WAF v2?

| Consideration | Decision |
|---------------|----------|
| **Managed Rules** | OWASP 3.2 provides comprehensive protection |
| **Autoscaling** | Handles traffic spikes automatically |
| **Logging** | Full request/response logging available |
| **Custom Rules** | Flexibility for application-specific rules |

### Why Managed Identity?

| Consideration | Decision |
|---------------|----------|
| **No Secrets** | Eliminates credential management |
| **Automatic Rotation** | Azure handles token lifecycle |
| **Auditing** | Clear identity in logs |
| **Least Privilege** | Scoped permissions per resource |

---

## Future Enhancements

1. **Monitoring**: Add Azure Monitor, Application Insights, Log Analytics
2. **Backup**: Configure Azure Backup for App Service
3. **CI/CD**: Integrate with Azure DevOps or GitHub Actions
4. **Key Vault**: Centralized secrets management
5. **Azure Policy**: Enforce compliance and governance
6. **Cost Management**: Implement tagging and budgets

---

## References

- [Azure Hub-Spoke Reference Architecture](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Application Gateway Documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Azure Private Link Documentation](https://docs.microsoft.com/en-us/azure/private-link/)
- [Azure Cosmos DB Security](https://docs.microsoft.com/en-us/azure/cosmos-db/database-security)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
