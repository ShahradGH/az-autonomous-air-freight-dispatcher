# Autonomous Air Freight Dispatcher: Multi-Agent Slot Allocation & Cold-Chain Governance

[![Pester Verification](https://img.shields.io/badge/Pester%20Verification-20%2F20%20Passing-brightgreen.svg)](tests/ColdChainSlotSwap.Tests.ps1)
[![PowerShell 7.4+](https://img.shields.io/badge/PowerShell-7.4%2B-0078D4.svg)](src/Test-AirFreightSlotSwapAuthority.ps1)
[![Microsoft Graph v2.x](https://img.shields.io/badge/Microsoft%20Graph-v2.x-5C2D91.svg)](graph/Send-DispatcherDualSignOff.ps1)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Enterprise-grade **PowerShell 7.4+**, **Azure AI Foundry**, and **Microsoft Graph v2.x** air-freight dispatch co-worker that arbitrates Eurocontrol NMOC slot swaps while enforcing hard IATA CEIV Pharma cold-chain excursion vetoes.

---

## 1. Executive & C-Suite Brief

### Business Risk: £3.4M Pharmaceutical Spoilage in 20 Minutes
When Eurocontrol issues an Air Traffic Flow Management (ATFM) slot delay, cargo dispatchers have minutes to swap departure slots or divert freighters. If an unconstrained automation script diverts an Airbus A321P2F carrying **£3.4M of temperature-sensitive IATA `PIL` pharmaceuticals** (+2°C to +8°C) to a regional aerodrome lacking certified GDP cold-storage vaults—or exceeds 60% of active Envirotainer battery holdover—the entire payload spoils, triggering catastrophic write-offs and regulatory sanctions.

### ROI & Compliance Impact
- **Hard Cold-Chain Veto:** Automatically blocks (`VETO_COLD_CHAIN_BREACH`) any diversion lacking certified GDP cold storage or exceeding the 60% thermal holdover ceiling.
- **Cross-Border Sovereign Gate:** Enforces `HOLD_FOR_CHIEF_DISPATCHER_DUAL_SIGNATURE` via Microsoft Graph v2.x Teams Adaptive Cards for any diversion `> 120 km` or crossing customs unions.
- **Zero Declarative IaC Drift:** All policy evaluation, Foundry AI risk scoring, and Graph v2.x dual-signature dispatch execute in modular PowerShell 7.4+.

---

## 2. Chief Architect & Engineer Blueprint

| Control Plane | Component | Epistemic & Operational Boundary |
| :--- | :--- | :--- |
| **Deterministic Slot Gate** | `src/Test-AirFreightSlotSwapAuthority.ps1` | Enforces 60% thermal holdover ceiling, GDP cold-room presence, and 120 km customs boundary |
| **Foundry AI Sentinel** | `ai/Invoke-ColdChainDiversionAgent.ps1` | Evaluates NMOC slot swaps via Azure AI Foundry (`-UseLiveFoundry`) or deterministic offline fallback; abstains below `0.80` confidence |
| **Human Sovereign Gate** | `graph/Send-DispatcherDualSignOff.ps1` | Posts Chief Dispatcher + GDP Compliance Lead Adaptive Card via Graph v2.x (`Invoke-MgGraphRequest`) |
| **KQL Telemetry** | `diagnostics/ColdChain-Telemetry.kql` | Correlates ULD thermal excursion alerts and NMOC slot-bid latency in Azure Monitor |

![Air Freight Topology](diagrams/005-azure-stencil-air-freight-topology.png)

![Cold Chain Veto Flow](diagrams/005-azure-stencil-cold-chain-veto-flow.png)

---

## 3. AI Subcomponent & Pilot Grafting Guide

```powershell
# 1. Run the full 20-test Pester 6.x verification matrix
Import-Module Pester -MinimumVersion 6.0
Invoke-Pester -Path ./tests/ColdChainSlotSwap.Tests.ps1 -Output Detailed

# 2. Evaluate a pharmaceutical diversion with the Foundry AI Cold-Chain Agent (offline mode)
. ./ai/Invoke-ColdChainDiversionAgent.ps1
Invoke-ColdChainDiversionAgent `
    -FlightNumber 'BA-592' `
    -CargoCode 'PIL' `
    -HasPharmaColdChain $true `
    -ProjectedTransitHours 8.0 `
    -ContainerHoldoverHours 24.0 `
    -DestinationHasCertifiedColdRoom $false `
    -DispatcherNotes 'EGBB standby ramp lacks certified +2C to +8C GDP vault.'

# 3. Execute live against Azure AI Foundry (set AZURE_AI_FOUNDRY_ENDPOINT & AZURE_AI_FOUNDRY_API_KEY)
Invoke-ColdChainDiversionAgent -FlightNumber 'BA-592' -CargoCode 'PIL' -HasPharmaColdChain $true -ProjectedTransitHours 8.0 -ContainerHoldoverHours 24.0 -DestinationHasCertifiedColdRoom $false -UseLiveFoundry
```

---

## 4. Microsoft Learn Primary References

1. [Azure AI Foundry Agents Overview](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/overview) — Bounded autonomous agent orchestration and tool-calling guardrails.
2. [Azure Container Apps Overview](https://learn.microsoft.com/en-us/azure/container-apps/overview) — Event-driven serverless compute for real-time dispatchers.
3. [Send Channel Messages in Microsoft Teams (Microsoft Graph)](https://learn.microsoft.com/en-us/graph/api/channel-post-messages) — Streaming Chief Dispatcher dual-signature Adaptive Cards via Graph v2.x.
4. [Kusto Query Language (KQL) Overview](https://learn.microsoft.com/en-us/kusto/query/) — Correlating ULD thermal telemetry and slot-swap decisions.

---
- **Author:** Shahrad Alerasoul — *Principal Azure Infrastructure & Platform Architect*
- **License:** MIT License
