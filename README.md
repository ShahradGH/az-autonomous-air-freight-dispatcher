# Autonomous Air Freight Dispatcher: Multi-Agent Slot Allocation & Cold-Chain Governance

[![Pester Verification](https://img.shields.io/badge/pester-16%2F16%20passing-brightgreen)](tests/ColdChainSlotSwap.Tests.ps1)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Architecture Deep-Dive](https://img.shields.io/badge/blog-alerasoul.net-0a1128)](https://alerasoul.net/autonomous-air-freight-slot-dispatcher/)

> **Primary Governance Artefact:** Pharma Cold-Chain Disruption & Reallocation Matrix  
> **Accountable Service Owner:** Air Cargo Operations Director & Chief Duty Dispatcher  
> **Full Architectural Deep-Dive:** [https://alerasoul.net/autonomous-air-freight-slot-dispatcher/](https://alerasoul.net/autonomous-air-freight-slot-dispatcher/)

---

## Repository Layout (15 Files)

```text
├── .github/workflows/ci.yml
├── .gitignore
├── LICENSE
├── README.md
├── diagnostics/ColdChain-Telemetry.kql
├── docs/ADR-001-cold-chain-contract.md
├── docs/DISPATCHER-RUNBOOK.md
├── infra/container-app-dispatcher.bicep
├── sample-data/aerodrome-gdp-registry.json
├── sample-data/flight-manifests.json
├── schemas/iata-ulds-manifest.schema.json
├── schemas/teams-dispatcher-card.json
├── src/Invoke-ColdChainExcursionHold.ps1
├── src/Test-AirFreightSlotSwapAuthority.ps1
└── tests/ColdChainSlotSwap.Tests.ps1
```

## Quickstart & Offline Verification

```powershell
# 1. Execute the primary PowerShell 7 evaluator
pwsh -NoProfile -File ./src/Test-AirFreightSlotSwapAuthority.ps1

# 2. Run the 16-test Pester verification contract
Invoke-Pester -Path ./tests/ColdChainSlotSwap.Tests.ps1 -Output Detailed
```

## License

Released under the [MIT License](LICENSE). Authored by **Shahrad Alerasoul** ([alerasoul.net](https://alerasoul.net)).
