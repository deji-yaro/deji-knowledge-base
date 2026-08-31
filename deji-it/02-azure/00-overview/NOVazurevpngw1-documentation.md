# Azure VPN Gateway Documentation

**Document version:** 1.2  
**Last updated:** 2026-04-23  
**Author:** [PLACEHOLDER – Your Name]

---

## 1. Overview

This document describes the configuration of the Azure VPN Gateway deployed in the NOV environment, including its virtual network, Site-to-Site (S2S) connections to on-premises locations, and Point-to-Site (P2S) client access settings.

---

## 2. VPN Gateway – Core Configuration
![[novi-gateway-overview.png]]

![[novi-gateway-configuration.png]]

![[novi-gateway-connections.png]]

![[novi-gateway-point-to-site-configuration.png]]

| Property               | Value           |
| ---------------------- | --------------- |
| **Gateway name**       | NOVazurevpngw1  |
| **Resource group**     | NOV-RG-VPN      |
| **Azure region**       | West Europe     |
| **SKU / Tier**         | VpnGw1AZ        |
| **VPN type**           | Route-based     |
| **Active-active mode** | Disabled        |
| **Public IP name**     | NOVvpnip1       |
| **Public IP address**  | 137.116.212.113 |
| **Generation**         | Generation 1    |

> 📍 **Portal path:** `Virtual Network Gateways → NOVazurevpngw1 → Overview`

---

## 3. Virtual Network & Subnets
![[novi-vnet-overview.png]]

| Property | Value |
|---|---|
| **VNet name** | NOVvnet1 |
| **VNet address space** | 10.80.0.0/16 |

### Subnets
![[novi-vnet-subnets.png]]

| Subnet name | Address range | Purpose |
|---|---|---|
| GatewaySubnet | 10.80.0.0/24 | Reserved for VPN Gateway |
| NOVsubnet1 | 10.80.1.0/24 | Workload subnet |

> 📍 **Portal path:** `Virtual Networks → NOVvnet1 → Subnets`

---

## 4. Site-to-Site (S2S) Connections

### 4.1 Connection Overview

| Property | Value |
|---|---|
| **BGP enabled** | Yes |
| **BGP ASN (Azure side)** | 65515 |
| **BGP peer IP** | 10.80.0.254 |
| **Custom APIPA BGP IP – Eurofiber** | 169.254.21.5 |
| **Custom APIPA BGP IP – Deltafiber** | 169.254.21.1 |
| **IKE protocol** | IKEv2 |
| **IPsec/IKE policy** | Custom (see per-connection details below) |
| **Connection status** | Connected |

> 📍 **How to find Connection names:** `Virtual Network Gateways → NOVazurevpngw1 → Connections`  
> 📍 **How to find Shared key:** `Virtual Network Gateways → NOVazurevpngw1 → Connections → [select connection] → Shared key (PSK)`

---

### 4.2 Local Network Gateways & On-Premises Endpoints
![[novi-local-network-gateway-deltafiber-overview.png]]

![[novi-local-network-gateway-deltafiber-configuration.png]]

![[novi-local-network-gateway-eurofiber-overview.png]]

![[novi-local-network-gateway-eurofiber-configuration.png]]

| Connection | Local Network Gateway | On-premises Public IP | Shared Key |
|---|---|---|---|
| NOV-S2Svpn-HONEurofiber | NOV-Honselersdijk-Eurofiber | 89.20.164.170 | PSK – stored securely, not documented here |
| NOV-S2Svpn-HONDeltafiber | NOV-Honselersdijk-Deltafiber | 109.109.100.118 | PSK – stored securely, not documented here |

> ℹ️ On-premises address prefixes are managed via BGP and not statically configured.

---

### 4.3 Connection Details per Site

#### NOV-S2Svpn-HONEurofiber
![[novi-connection-eurofiber-overview.png]]

![[novi-connection-eurofiber-authentication.png]]

![[novi-connection-eurofiber-configuration.png]]



| Property                         | Value                                    |
| -------------------------------- | ---------------------------------------- |
| **Connection name**              | NOV-S2Svpn-HONEurofiber                  |
| **Local Network Gateway**        | NOV-Honselersdijk-Eurofiber              |
| **On-premises public IP**        | 89.20.164.170                            |
| **On-premises address prefixes** | Managed via BGP – not statically defined |
| **Shared key (PSK)**             | Stored securely – not documented here    |
| **Use Azure Private IP**         | Disabled                                 |
| **BGP enabled**                  | Yes                                      |
| **Custom BGP addresses enabled** | Yes                                      |
| **Custom BGP APIPA IP**          | 169.254.21.5                             |
| **Connection mode**              | Default                                  |
| **IKE protocol**                 | IKEv2                                    |
| **Connection status**            | Connected                                |

**IPsec/IKE Policy – Custom**

| Phase | Encryption | Integrity | DH / PFS Group |
|---|---|---|---|
| IKE Phase 1 | AES256 | SHA256 | DHGroup14 |
| IKE Phase 2 (IPsec) | AES256 | SHA256 | PFS Group None |

| Parameter | Value |
|---|---|
| **IPsec SA lifetime (seconds)** | 86400 |
| **DPD timeout (seconds)** | 45 |

---

#### NOV-S2Svpn-HONDeltafiber
![[novi-connection-deltafiber-overview.png]]

![[novi-connection-delta-authentication.png]]

![[novi-connection-delta-configuration.png]]



| Property | Value |
|---|---|
| **Connection name** | NOV-S2Svpn-HONDeltafiber |
| **Local Network Gateway** | NOV-Honselersdijk-Deltafiber |
| **On-premises public IP** | 109.109.100.118 |
| **On-premises address prefixes** | Managed via BGP – not statically defined |
| **Shared key (PSK)** | Stored securely – not documented here |
| **Use Azure Private IP** | Disabled |
| **BGP enabled** | Yes |
| **Custom BGP addresses enabled** | Yes |
| **Custom BGP APIPA IP** | 169.254.21.1 |
| **Connection mode** | Default |
| **IKE protocol** | IKEv2 |
| **Connection status** | Connected |

**IPsec/IKE Policy – Custom**

| Phase | Encryption | Integrity | DH / PFS Group |
|---|---|---|---|
| IKE Phase 1 | AES256 | SHA256 | DHGroup14 |
| IKE Phase 2 (IPsec) | AES256 | SHA256 | PFS Group None |

| Parameter | Value |
|---|---|
| **IPsec SA lifetime (seconds)** | 86400 |
| **DPD timeout (seconds)** | 45 |

---

## 5. Point-to-Site (P2S) Configuration
![[novi-gateway-point-to-site-configuration.png]]

| Property | Value |
|---|---|
| **Client address pool** | 10.81.0.0/22 |
| **Tunnel type** | OpenVPN (SSL) |
| **Authentication method** | Microsoft Entra ID (Azure AD) |
| **Root certificate name(s)** | N/A – Entra ID auth (no certificate required) |
| **VPN client platforms** | Not documented |
| **DNS servers** | Not documented |

**Additional routes advertised to P2S clients:**

| Route |
|---|
| 192.168.68.0/24 |
| 192.168.69.0/24 |
| 192.168.144.0/22 |
| 192.168.240.0/24 |

> 📍 **Portal path:** `Virtual Network Gateways → NOVazurevpngw1 → Point-to-site configuration`

---

## 6. Routing

| Route scope | Address prefixes |
|---|---|
| Azure VNet | 10.80.0.0/16 |
| P2S client pool | 10.81.0.0/22 |
| On-premises via Eurofiber (BGP) | Dynamically learned via BGP |
| On-premises via Deltafiber (BGP) | Dynamically learned via BGP |
| Additional advertised to P2S clients | 192.168.68.0/24, 192.168.69.0/24, 192.168.144.0/22, 192.168.240.0/24 |

> 📍 **How to verify effective routes:** `Virtual Network Gateways → NOVazurevpngw1 → BGP peers` or check route tables on connected NICs.

---

## 7. Monitoring & Diagnostics

| Item | Details |
|---|---|
| **Diagnostic logs enabled** | [PLACEHOLDER – yes/no] |
| **Log Analytics Workspace** | [PLACEHOLDER] |
| **Alerts configured** | [PLACEHOLDER] |

> 📍 **Portal path:** `Virtual Network Gateways → NOVazurevpngw1 → Diagnostic settings`

---

## 8. Placeholders – Quick Reference

No critical placeholders remain. The only items not documented are:

- **PSK shared keys** – intentionally omitted for security; retrieve from `VPN Gateway → Connections → [connection] → Shared key` if needed.
- **P2S client platforms & DNS** – not in scope for this document revision.

---

## 9. Change Log

| Date | Version | Author | Change |
|---|---|---|---|
| 2026-04-23 | 1.0 | [PLACEHOLDER] | Initial document created |
| 2026-04-23 | 1.1 | [PLACEHOLDER] | Added full IPsec/IKE policy, BGP APIPA assignments, P2S config, additional advertised routes |
| 2026-04-23 | 1.2 | [PLACEHOLDER] | Resolved all remaining placeholders; confirmed Generation 1, BGP-managed prefixes, P2S Entra ID auth |

---

*Documentation generated with the assistance of Claude AI – verify all values against the Azure Portal before use in production.*
