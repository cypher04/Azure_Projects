# Traffic Flow Documentation

## Hub and Spoke Infrastructure - Network Traffic Patterns

---

## Table of Contents

1. [Overview](#overview)
2. [Inbound Traffic Flow](#inbound-traffic-flow)
3. [Outbound Traffic Flow](#outbound-traffic-flow)
4. [DNS Resolution Flow](#dns-resolution-flow)
5. [Private Link Service Flow](#private-link-service-flow)
6. [VNet Peering Traffic](#vnet-peering-traffic)
7. [Complete Request-Response Cycle](#complete-request-response-cycle)

---

## Overview

This document details the network traffic patterns within the Hub and Spoke infrastructure. All traffic flows are based on the actual Terraform configuration.

### Infrastructure Components Involved in Traffic Flow

| Component | Terraform Resource | Network Location |
|-----------|-------------------|------------------|
| Public IP | `azurerm_public_ip.public_ip` | Internet Edge |
| Application Gateway | `azurerm_application_gateway.appgw` | Hub Database Subnet |
| Private Link Service | `azurerm_private_link_service.plservice` | Spoke 1 Web Subnet (NAT) |
| App Service Private Endpoint | `azurerm_private_endpoint.pe-appservice` | Spoke 2 App Subnet |
| Linux Web App | `azurerm_linux_web_app.web_app` | App Service (PaaS) |
| VNet Swift Connection | `azurerm_app_service_virtual_network_swift_connection` | Hub Delegation Subnet |
| Cosmos DB Private Endpoint | `azurerm_private_endpoint.pe-cosmosdb` | Hub Database Subnet |
| Cosmos DB | `azurerm_cosmosdb_account.cosmosdb` | Azure PaaS (Private) |
| VNet Peering (Spoke-to-Spoke) | `azurerm_virtual_network_peering.spoke1-to-spoke2` | Spoke 1 ↔ Spoke 2 |

---

## Inbound Traffic Flow

### User Request to Application

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              INBOUND TRAFFIC FLOW                                    │
│                           (Internet → Application → Database)                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

                                    ┌───────────────┐
                                    │   INTERNET    │
                                    │    (User)     │
                                    └───────┬───────┘
                                            │
                                            │ HTTPS Request
                                            │
                                            ▼
                    ┌───────────────────────────────────────────────┐
                    │              PUBLIC IP ADDRESS                 │
                    │         azurerm_public_ip.public_ip           │
                    │                                               │
                    │  • Allocation: Static                         │
                    │  • SKU: Standard                              │
                    │  • Attached to: Application Gateway           │
                    └───────────────────────┬───────────────────────┘
                                            │
                                            │
                                            ▼
                    ┌───────────────────────────────────────────────┐
                    │          APPLICATION GATEWAY                   │
                    │          azurerm_application_gateway.appgw    │
                    │                                               │
                    │  SECURITY INSPECTION:                         │
                    │  ┌─────────────────────────────────────────┐  │
                    │  │ 1. WAF Inspection (OWASP 3.2)           │  │
                    │  │ 2. Custom Rules (BlockBadBots)          │  │
                    │  │ 3. Request Body Check (128KB)           │  │
                    │  │ 4. File Upload Limit (100MB)            │  │
                    │  └─────────────────────────────────────────┘  │
                    │                                               │
                    │  ROUTING:                                     │
                    │  • Health Probe: /                            │
                    │  • Backend Port: 443                          │
                    │  • Protocol: HTTPS                            │
                    └───────────────────────┬───────────────────────┘
                                            │
                                            │ Backend Pool Connection
                                            │
                                            ▼
                    ┌───────────────────────────────────────────────┐
                    │          PRIVATE LINK SERVICE                  │
                    │          azurerm_private_link_service.plservice│
                    │                                               │
                    │  • NAT IP: Spoke 1 Web Subnet                 │
                    │  • Primary NAT Configuration                  │
                    │  • Enables Private Endpoint Connections       │
                    └───────────────────────┬───────────────────────┘
                                 │                                 │
                                 ▼                                 │
                    ┌─────────────────────────────┐                │
                    │  APP SERVICE PRIVATE        │                │
                    │  ENDPOINT                   │                │
                    │  azurerm_private_endpoint.  │                │
                    │  pe-appservice              │                │
                    │                             │                │
                    │  • Subnet: Spoke 2 App      │                │
                    │  • Subresource: sites       │                │
                    │  • DNS Zone Group:          │                │
                    │    app-dns-zone-group       │                │
                    └─────────────┬───────────────┘                │
                                  │                                │
                                  │ Private Network                │
                                  │ (No Public Internet)           │
                                  │                                │
                                  ▼                                │
                    ┌─────────────────────────────┐                │
                    │      LINUX WEB APP          │                │
                    │  azurerm_linux_web_app.     │                │
                    │  web_app                    │                │
                    │                             │                │
                    │  AUTHENTICATION:            │                │
                    │  ┌─────────────────────┐    │                │
                    │  │ 1. Client Cert      │    │                │
                    │  │    (Required)       │    │                │
                    │  │                     │    │                │
                    │  │ 2. Auth Settings    │    │                │
                    │  │    (Redirect        │    │                │
                    │  │     Unauthenticated)│    │                │
                    │  │                     │    │                │
                    │  │ 3. Managed Identity │    │                │
                    │  │    (SystemAssigned) │    │                │
                    │  └─────────────────────┘    │                │
                    │                             │                │
                    │  APPLICATION LOGIC          │                │
                    │  • Process Request          │                │
                    │  • Query Database           │                │
                    └─────────────┬───────────────┘                │
                                  │                                │
                                  │ Database Query                 │
                                  │ (via Service Connector)        │
                                  │                                │
                                  ▼                                │
                    ┌─────────────────────────────┐                │
                    │  VNET SWIFT CONNECTION      │                │
                    │  azurerm_app_service_       │                │
                    │  virtual_network_swift_     │                │
                    │  connection                 │                │
                    │                             │                │
                    │  Outbound traffic routed    │                │
                    │  through Hub VNet           │                │
                    └─────────────┬───────────────┘                │
                                  │                                │
                                  ▼                                │
                    ┌─────────────────────────────┐                │
                    │  DELEGATION SUBNET          │                │
                    │  azurerm_subnet.del-subnet  │                │
                    │  (10.0.4.0/24 - Hub VNet)   │                │
                    │                             │                │
                    │  Delegation:                │                │
                    │  Microsoft.ContainerInstance│                │
                    │  /containerGroups           │                │
                    └─────────────┬───────────────┘                │
                                  │                                │
                                  │ Internal Hub VNet Routing      │
                                  │                                │
                                  ▼                                │
                    ┌─────────────────────────────┐                │
                    │  COSMOS DB PRIVATE          │                │
                    │  ENDPOINT                   │                │
                    │  azurerm_private_endpoint.  │                │
                    │  pe-cosmosdb                │                │
                    │                             │                │
                    │  • Subnet: Hub Database     │                │
                    │  • Subresource: Sql         │                │
                    │  • DNS Zone Group:          │                │
                    │    cosmos-dns-zone-group    │                │
                    └─────────────┬───────────────┘                │
                                  │                                │
                                  │ Private Endpoint Connection    │
                                  │                                │
                                  ▼                                │
                    ┌─────────────────────────────┐                │
                    │     AZURE COSMOS DB         │                │
                    │  azurerm_cosmosdb_account.  │                │
                    │  cosmosdb                   │                │
                    │                             │                │
                    │  • Kind: GlobalDocumentDB   │                │
                    │  • Consistency: Session     │                │
                    │  • public_network_access:   │                │
                    │    DISABLED                 │                │
                    │  • Throughput: 400 RU/s     │                │
                    │  • Backup: Periodic (300hr) │                │
                    └─────────────────────────────┘                │
                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Inbound Traffic Summary

| Step | Source | Destination | Protocol | Port | Security Control |
|------|--------|-------------|----------|------|------------------|
| 1 | Internet | Public IP | HTTPS | 443 | - |
| 2 | Public IP | App Gateway | HTTP/HTTPS | 80/443 | WAF (OWASP 3.2) |
| 3 | App Gateway | Private Link Service | Internal | NAT | Private Link |
| 4 | Private Link | App Service PE | Private | 443 | Private Endpoint |
| 5 | App Service PE | Linux Web App | Internal | 443 | Client Cert + Auth |
| 6 | Web App | VNet Swift | Internal | - | VNet Integration |
| 7 | Delegation Subnet | Cosmos DB PE | Private | 443 | Private Endpoint |
| 8 | Cosmos DB PE | Cosmos DB | Internal | 443 | Private Network Only |

---

## Outbound Traffic Flow

### Application to Database (Private Network)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      OUTBOUND TRAFFIC FLOW - DATABASE                                │
│                        (Application → Cosmos DB)                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│            LINUX WEB APP                │
│                                         │
│  Application generates database query:  │
│  ┌─────────────────────────────────┐    │
│  │ cosmosClient.container          │    │
│  │   .items.query(...)             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Authentication:                        │
│  • System Assigned Managed Identity     │
│  • Service Connector (azurerm_app_      │
│    service_connection)                  │
└───────────────────┬─────────────────────┘
                    │
                    │ Outbound Request
                    │
                    ▼
┌─────────────────────────────────────────┐
│        VNET SWIFT CONNECTION            │
│                                         │
│  Routes outbound traffic through VNet   │
│  instead of public internet             │
│                                         │
│  Connection: App Service ──► Hub VNet   │
│              Delegation Subnet          │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          DELEGATION SUBNET              │
│          (Hub VNet - 10.0.4.0/24)       │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Delegation Configuration:       │    │
│  │                                 │    │
│  │ Microsoft.ContainerInstance     │    │
│  │ /containerGroups                │    │
│  │                                 │    │
│  │ Actions:                        │    │
│  │ • join/action                   │    │
│  │ • prepareNetworkPolicies/action │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Outbound IP: From subnet range         │
└───────────────────┬─────────────────────┘
                    │
                    │ Private DNS Resolution
                    │ (privatelink.documents.azure.com)
                    │
                    ▼
┌─────────────────────────────────────────┐
│     PRIVATE DNS ZONE (COSMOS DB)        │
│     azurerm_private_dns_zone.           │
│     pdz-cosmosdb                        │
│                                         │
│  Zone: privatelink.documents.azure.com  │
│  Linked VNet: Hub VNet                  │
│                                         │
│  DNS Resolution:                        │
│  ┌─────────────────────────────────┐    │
│  │ Query: myaccount.documents.     │    │
│  │        azure.com                │    │
│  │                                 │    │
│  │ Response: 10.0.1.x              │    │
│  │ (Private Endpoint IP)           │    │
│  └─────────────────────────────────┘    │
└───────────────────┬─────────────────────┘
                    │
                    │ Routed to Private IP
                    │
                    ▼
┌─────────────────────────────────────────┐
│      COSMOS DB PRIVATE ENDPOINT         │
│      (Hub Database Subnet)              │
│                                         │
│  Private IP: 10.0.1.x                   │
│  Subresource: Sql                       │
│                                         │
│  DNS Zone Group: cosmos-dns-zone-group  │
│  (Auto-creates A record in DNS zone)    │
└───────────────────┬─────────────────────┘
                    │
                    │ Private Connection
                    │
                    ▼
┌─────────────────────────────────────────┐
│           AZURE COSMOS DB               │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Query Execution                 │    │
│  │                                 │    │
│  │ Database: sqldb                 │    │
│  │ Container: sqlcontainer         │    │
│  │ Partition Key: /partitionKey    │    │
│  │                                 │    │
│  │ Indexing: Consistent            │    │
│  │ Throughput: 400 RU/s            │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Response returned via same path        │
└─────────────────────────────────────────┘
```

### Application to Internet (External Services)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      OUTBOUND TRAFFIC FLOW - INTERNET                                │
│                        (Application → External APIs)                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│            LINUX WEB APP                │
│                                         │
│  External API call:                     │
│  ┌─────────────────────────────────┐    │
│  │ httpClient.get(                 │    │
│  │   "https://api.external.com"    │    │
│  │ )                               │    │
│  └─────────────────────────────────┘    │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│        VNET SWIFT CONNECTION            │
│                                         │
│  Routes through VNet for outbound       │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          DELEGATION SUBNET              │
│          (Hub VNet - 10.0.4.0/24)       │
│                                         │
│  Source IP: From delegation subnet      │
│  range (10.0.4.x)                       │
└───────────────────┬─────────────────────┘
                    │
                    │ No matching Private Endpoint
                    │ (external destination)
                    │
                    ▼
┌─────────────────────────────────────────┐
│         AZURE PLATFORM SNAT             │
│                                         │
│  Default Azure behavior:                │
│  ┌─────────────────────────────────┐    │
│  │ • Source NAT applied            │    │
│  │ • Dynamic outbound IP           │    │
│  │ • No NAT Gateway configured     │    │
│  │ • Uses Azure's shared SNAT pool │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ⚠️ Note: No predictable outbound IP   │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│              INTERNET                   │
│                                         │
│  External API / Service                 │
│  (api.external.com)                     │
└─────────────────────────────────────────┘
```

---

## DNS Resolution Flow

### Private DNS Zone Resolution

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              DNS RESOLUTION FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════════
                              APP SERVICE DNS RESOLUTION
═══════════════════════════════════════════════════════════════════════════════════════

┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│      DNS Query       │     │   Private DNS Zone   │     │    Resolution        │
│                      │     │                      │     │                      │
│  webapp.azurewebsites│────►│ privatelink.azure    │────►│  Private Endpoint    │
│  .net                │     │ websites.net         │     │  IP: 10.0.3.x        │
│                      │     │                      │     │  (Spoke 2 App Subnet)│
└──────────────────────┘     │ Linked to: Spoke 1   │     └──────────────────────┘
                             │ VNet                 │
                             │                      │
                             │ Zone Group:          │
                             │ app-dns-zone-group   │
                             └──────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════════
                              COSMOS DB DNS RESOLUTION
═══════════════════════════════════════════════════════════════════════════════════════

┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│      DNS Query       │     │   Private DNS Zone   │     │    Resolution        │
│                      │     │                      │     │                      │
│  myaccount.documents │────►│ privatelink.documents│────►│  Private Endpoint    │
│  .azure.com          │     │ .azure.com           │     │  IP: 10.0.1.x        │
│                      │     │                      │     │  (Hub Database       │
└──────────────────────┘     │ Linked to: Hub VNet  │     │   Subnet)            │
                             │                      │     └──────────────────────┘
                             │ Zone Group:          │
                             │ cosmos-dns-zone-     │
                             │ group                │
                             └──────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════════
                              DNS FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════════════════════════

                        ┌─────────────────────────────────┐
                        │         Application             │
                        │  (Linux Web App)                │
                        └───────────────┬─────────────────┘
                                        │
                                        │ DNS Query:
                                        │ cosmosdb.documents.azure.com
                                        │
                                        ▼
                        ┌─────────────────────────────────┐
                        │       Azure DNS Resolver        │
                        │                                 │
                        │  1. Check Private DNS Zones     │
                        │     linked to VNet              │
                        │                                 │
                        │  2. Found: privatelink.         │
                        │     documents.azure.com         │
                        │                                 │
                        │  3. Query redirected to         │
                        │     Private DNS Zone            │
                        └───────────────┬─────────────────┘
                                        │
                                        ▼
                        ┌─────────────────────────────────┐
                        │      Private DNS Zone           │
                        │  privatelink.documents.azure.com│
                        │                                 │
                        │  A Record (auto-created by      │
                        │  DNS Zone Group):               │
                        │                                 │
                        │  cosmosdb ──► 10.0.1.x          │
                        │              (Private EP IP)    │
                        └───────────────┬─────────────────┘
                                        │
                                        │ Returns: 10.0.1.x
                                        │
                                        ▼
                        ┌─────────────────────────────────┐
                        │       Application               │
                        │                                 │
                        │  Connects to: 10.0.1.x:443      │
                        │  (Private Endpoint)             │
                        │                                 │
                        │  ✓ No public internet traversal │
                        │  ✓ Traffic stays in Azure VNet  │
                        └─────────────────────────────────┘
```

### DNS Zone Configuration

| DNS Zone | Terraform Resource | Linked VNet | Purpose |
|----------|-------------------|-------------|---------|
| `privatelink.azurewebsites.net` | `azurerm_private_dns_zone.pdz-webapp` | Spoke 1 VNet | App Service resolution |
| `privatelink.documents.azure.com` | `azurerm_private_dns_zone.pdz-cosmosdb` | Hub VNet | Cosmos DB resolution |

---

## Private Link Service Flow

### Application Gateway to Private Endpoints via Private Link Service

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          PRIVATE LINK SERVICE FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│           EXTERNAL CLIENT               │
│                                         │
│  Request to access service privately    │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│         APPLICATION GATEWAY             │
│         azurerm_application_gateway.    │
│         appgw                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Configuration:                  │    │
│  │                                 │    │
│  │ SKU: WAF_v2                     │    │
│  │ Frontend IP: Public IP          │    │
│  │ Backend Pool: Private Endpoints │    │
│  └─────────────────────────────────┘    │
│                                         │
│  WAF Policy: OWASP 3.2, Prevention     │
│  Autoscale: 2-5 instances              │
└───────────────────┬─────────────────────┘
                    │
                    │ Backend Pool Connection
                    │
                    ▼
┌─────────────────────────────────────────┐
│        PRIVATE LINK SERVICE             │
│        azurerm_private_link_service.    │
│        plservice                        │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ NAT IP Configuration:           │    │
│  │                                 │    │
│  │ Name: public_ip_id              │    │
│  │ Primary: true                   │    │
│  │ Subnet: Spoke 1 Web Subnet      │    │
│  │ (subnet-spoke-1-web)            │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Load Balancer Frontend IPs: []         │
│  (No Load Balancer - Direct NAT)        │
│                                         │
│  Enables:                               │
│  • NAT for private connections          │
│  • Consumer private endpoints           │
│  • Direct private access                │
└───────────────────┬─────────────────────┘
                    │
                    │ Private Link Connection
                    │
                    ▼
┌─────────────────────────────────────────┐
│         PRIVATE ENDPOINTS               │
│         (Consumers)                     │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ App Service Private Endpoint    │    │
│  │                                 │    │
│  │ Connected to: plservice.id      │    │
│  │ Subresource: sites              │    │
│  │ DNS Zone: app-dns-zone-group    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Cosmos DB Private Endpoint      │    │
│  │                                 │    │
│  │ Connected to: plservice.id      │    │
│  │ Subresource: Sql                │    │
│  │ DNS Zone: cosmos-dns-zone-group │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

## VNet Peering Traffic

### Hub to Spoke Communication

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              VNET PEERING TRAFFIC                                    │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              ┌───────────────────────┐
                              │      HUB VNET         │
                              │    (10.0.1.0/24)      │
                              │                       │
                              │  ┌─────────────────┐  │
                              │  │ Database Subnet │  │
                              │  │  10.0.1.0/24    │  │
                              │  │                 │  │
                              │  │ Cosmos DB PE    │  │
                              │  │ App Gateway     │  │
                              │  └─────────────────┘  │
                              │                       │
                              │  ┌─────────────────┐  │
                              │  │ Delegation      │  │
                              │  │ Subnet          │  │
                              │  │  10.0.4.0/24    │  │
                              │  │                 │  │
                              │  │ VNet Swift      │  │
                              │  │ Connection      │  │
                              │  └─────────────────┘  │
                              └───────────┬───────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
                    │    Peering          │         Peering     │
                    │                     │                     │
                    ▼                     │                     ▼
        ┌───────────────────────┐         │         ┌───────────────────────┐
        │     SPOKE 1 VNET      │         │         │     SPOKE 2 VNET      │
        │    (10.0.2.0/24)      │         │         │    (10.0.3.0/24)      │
        │                       │         │         │                       │
        │  ┌─────────────────┐  │         │         │  ┌─────────────────┐  │
        │  │   Web Subnet    │  │         │         │  │   App Subnet    │  │
        │  │  10.0.2.0/24    │  │         │         │  │  10.0.3.0/24    │  │
        │  │                 │  │         │         │  │                 │  │
        │  │ Private Link    │  │         │         │  │ App Service PE  │  │
        │  │ Service NAT     │  │◄────────┬────────►│  │                 │  │
        │  │                 │  │   DIRECT          │  │                 │  │
        │  │ Private DNS     │  │   SPOKE-TO-SPOKE  │  │                 │  │
        │  │ Zone Link       │  │   PEERING ✓       │  │                 │  │
        │  └─────────────────┘  │                   │  └─────────────────┘  │
        │                       │                   │                       │
        └───────────────────────┘                   └───────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════════
                              PEERING CONFIGURATION
═══════════════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  PEERING                        │  DIRECTION         │  TERRAFORM RESOURCE          │
├─────────────────────────────────┼────────────────────┼──────────────────────────────┤
│  Hub ──► Spoke 1                │  Hub to Spoke      │  hub-to-spoke1-peering       │
│  Spoke 1 ──► Hub                │  Spoke to Hub      │  spoke1-to-hub-peering       │
│  Hub ──► Spoke 2                │  Hub to Spoke      │  hub-to-spoke2-peering       │
│  Spoke 2 ──► Hub                │  Spoke to Hub      │  spoke2-to-hub-peering       │
│  Spoke 1 ──► Spoke 2            │  Spoke to Spoke    │  spoke1-to-spoke2-peering    │
│  Spoke 2 ──► Spoke 1            │  Spoke to Spoke    │  spoke2-to-spoke1-peering    │
└─────────────────────────────────┴────────────────────┴──────────────────────────────┘

✓ Spoke 1 and Spoke 2 have DIRECT bidirectional peering.
  Traffic can flow directly between spokes without routing through Hub.
```

---

## Complete Request-Response Cycle

### End-to-End Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        COMPLETE REQUEST-RESPONSE CYCLE                               │
└─────────────────────────────────────────────────────────────────────────────────────┘

    ┌─────────┐
    │  USER   │
    │(Browser)│
    └────┬────┘
         │
         │ ① HTTPS Request
         │
         ▼
    ┌─────────────────┐
    │   PUBLIC IP     │
    │ (Static/Std)    │
    └────────┬────────┘
             │
             │
             ▼
    ┌─────────────────┐
    │ APPLICATION     │
    │ GATEWAY (WAF)   │
    └────────┬────────┘
             │
             │ ② WAF Check + Routing
             │
             ▼
    ┌─────────────────┐
    │ PRIVATE LINK    │
    │ SERVICE         │
    │ (Spoke 1 NAT)   │
    └────────┬────────┘
             │
             │ ③ Private Link Connection
             │
             ▼
    ┌─────────────────┐
    │ APP SERVICE     │
    │ PRIVATE         │
    │ ENDPOINT        │
    │ (Spoke 2)       │
    └────────┬────────┘
             │
             │ ⑤ Private Network
             │
             ▼
    ┌─────────────────┐
    │  LINUX WEB APP  │
    │                 │
    │ • Client Cert   │
    │ • Auth Check    │
    │ • Process       │
    └────────┬────────┘
             │
             │ ⑥ Database Query
             │
             ▼
    ┌─────────────────┐
    │ VNET SWIFT      │
    │ CONNECTION      │
    │ (Hub Delegation │
    │  Subnet)        │
    └────────┬────────┘
             │
             │ ⑦ DNS Resolution
             │    (privatelink.documents.azure.com)
             │
             ▼
    ┌─────────────────┐
    │ COSMOS DB       │
    │ PRIVATE         │
    │ ENDPOINT        │
    │ (Hub DB Subnet) │
    └────────┬────────┘
             │
             │ ⑧ Private DB Connection
             │
             ▼
    ┌─────────────────┐
    │  COSMOS DB      │
    │                 │
    │ • Query Execute │
    │ • Return Data   │
    └────────┬────────┘
             │
             │ ⑨ Response (Reverse Path)
             │
             ▼
    ┌─────────────────┐
    │  LINUX WEB APP  │
    │                 │
    │ • Build Response│
    └────────┬────────┘
             │
             │ ⑩ HTTP Response
             │
             ▼
    ┌─────────────────┐
    │ APP GATEWAY     │
    │ (Response)      │
    └────────┬────────┘
             │
             │ ⑪ Response to User
             │
             ▼
    ┌─────────────────┐
    │   PUBLIC IP     │
    └────────┬────────┘
             │
             ▼
    ┌─────────┐
    │  USER   │
    │(Browser)│
    └─────────┘

═══════════════════════════════════════════════════════════════════════════════════════
                              STEP-BY-STEP BREAKDOWN
═══════════════════════════════════════════════════════════════════════════════════════

│ Step │ Component                    │ Action                                        │
├──────┼──────────────────────────────┼───────────────────────────────────────────────┤
│  ①   │ User → Public IP             │ HTTPS request to static public IP            │
│  ②   │ App Gateway                  │ WAF inspection (OWASP 3.2, custom rules)     │
│  ③   │ Private Link Service         │ NAT connection to private endpoints           │
│  ④   │ App Service Private EP       │ Route to Linux Web App (private network)     │
│  ⑤   │ Linux Web App                │ Process request, initiate DB query            │
│  ⑥   │ VNet Swift + DNS             │ Resolve Cosmos DB via private DNS zone       │
│  ⑦   │ Cosmos DB Private EP         │ Connect to Cosmos DB (private network)       │
│  ⑧   │ Cosmos DB → Web App          │ Return query results                          │
│  ⑨   │ Web App → App Gateway        │ Build and send HTTP response                  │
│  ⑩   │ Public IP → User             │ Deliver response to user                      │
└──────┴──────────────────────────────┴───────────────────────────────────────────────┘
```

---

## Traffic Flow Summary

### Security Controls at Each Layer

| Layer | Traffic Type | Security Control | Terraform Resource |
|-------|-------------|------------------|-------------------|
| Edge | Inbound | WAF (OWASP 3.2) | `azurerm_web_application_firewall_policy.webafw` |
| Network | All | NSG Rules | `azurerm_network_security_group.*` |
| Private Link | Inbound | Private Link Service | `azurerm_private_link_service.plservice` |
| Application | Inbound | Client Certificates | `client_certificate_mode = "Required"` |
| Application | Inbound | Auth Settings | `auth_settings.enabled = true` |
| Database | Outbound | Private Endpoint | `azurerm_private_endpoint.pe-cosmosdb` |
| Database | Outbound | Managed Identity | `azurerm_app_service_connection` |
| DNS | All | Private DNS Zones | `azurerm_private_dns_zone.*` |
| Spoke-to-Spoke | Internal | VNet Peering | `azurerm_virtual_network_peering.spoke1-to-spoke2` |

### Network Isolation Summary

| Component | Public Access | Private Access | Access Method |
|-----------|--------------|----------------|---------------|
| Application Gateway | ✅ Yes | - | Public IP |
| Linux Web App | ❌ No | ✅ Yes | Private Endpoint |
| Cosmos DB | ❌ No | ✅ Yes | Private Endpoint |
| Private Link Service | - | ✅ Yes | NAT via Spoke 1 |
| Spoke 1 ↔ Spoke 2 | - | ✅ Yes | Direct VNet Peering |

---

## References

- [Azure Private Link Documentation](https://docs.microsoft.com/en-us/azure/private-link/)
- [Azure Private DNS Zones](https://docs.microsoft.com/en-us/azure/dns/private-dns-privatednszone)
- [Azure VNet Peering](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [App Service VNet Integration](https://docs.microsoft.com/en-us/azure/app-service/overview-vnet-integration)
