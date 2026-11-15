# Autonomous Air Freight Dispatcher — L2/L3 Cold-Chain & NMOC Runbook

**Service:** Eurocontrol NMOC Slot Dispatcher + IATA CEIV Pharma Guard + Microsoft Graph v2.x  
**Severity:** P1 / Cold-Chain Excursion & Slot Preservation  
**Standard:** PowerShell 7.4+ | Microsoft Graph v2.x | Zero Declarative IaC

---

## 1. Cold-Chain Veto & Dual-Signature Gates

Every autonomous Eurocontrol NMOC slot-swap bid is governed by three deterministic safety boundaries:

| Gate Condition | Threshold / Invariant | Automated Action | Escalation Target |
| :--- | :--- | :--- | :--- |
| **PIL Thermal Holdover Breach** | `ProjectedTransitHours > 60%` of container holdover | `VETO_COLD_CHAIN_BREACH` | Cargo OCC + GDP Quality Lead |
| **Missing Certified Cold Room** | Destination `DestinationHasCertifiedColdRoom = $false` | `VETO_COLD_CHAIN_BREACH` | Aerodrome Ground Handling |
| **Cross-Border / >120km Diversion** | `DiversionDistanceKm > 120` or `CrossesCustomsUnion` | `HOLD_FOR_CHIEF_DISPATCHER_DUAL_SIGNATURE` | Chief Dispatcher + Customs Lead |
| **AI Confidence Abstention** | Holdover `50%–60%` (`Confidence < 0.80`) | `AbstainToHuman = $true` | Chief Dispatcher |
| **Prompt-Injection Override** | Override string in dispatcher notes | `VETO_COLD_CHAIN_BREACH` | Aviation Security (AvSec) |

---

## 2. L2 / L3 Operational Triage Procedure

### Step 1: Validate Slot-Swap Authority Deterministically
```powershell
$manifest = [PSCustomObject]@{ FlightNumber = 'BA-592'; HasPharmaColdChain = $true; TransitHours = 6.0; ContainerHoldoverHours = 24.0 }
$swap     = [PSCustomObject]@{ DelayHours = 2.0; DestinationHasCertifiedColdRoom = $false; DiversionDistanceKm = 95; CrossesCustomsUnion = $false }
./src/Test-AirFreightSlotSwapAuthority.ps1 -FlightManifest $manifest -ProposedSlotSwap $swap
```

### Step 2: Run Foundry AI Cold-Chain Diversion Risk Evaluation
```powershell
. ./ai/Invoke-ColdChainDiversionAgent.ps1
$eval = Invoke-ColdChainDiversionAgent `
    -FlightNumber 'BA-592' `
    -CargoCode 'PIL' `
    -HasPharmaColdChain $true `
    -ProjectedTransitHours 8.0 `
    -ContainerHoldoverHours 24.0 `
    -DestinationHasCertifiedColdRoom $false `
    -DispatcherNotes 'EGBB standby ramp lacks certified +2C to +8C GDP vault.'
```

### Step 3: Dispatch Chief Dispatcher Dual-Signature Card via Microsoft Graph v2.x
```powershell
. ./graph/Send-DispatcherDualSignOff.ps1
Send-DispatcherDualSignOff `
    -TeamId '<team-id>' `
    -ChannelId '<channel-id>' `
    -FlightNumber 'BA-592' `
    -CargoCode 'PIL' `
    -Verdict $eval.Verdict `
    -HoldoverRatio $eval.HoldoverRatio `
    -Rationale $eval.Rationale
```

---

## 3. Post-Incident Audit & CI Gate

1. Archive the `PSCustomObject` verdict and Teams Adaptive Card `MessageId` against the IATA Air Waybill (AWB) audit trail.
2. Run `Invoke-Pester ./tests/ColdChainSlotSwap.Tests.ps1` to verify 100% pass rate before deploying any dispatcher rule updates.
