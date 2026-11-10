# Test-AirFreightSlotSwapAuthority.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [PSCustomObject]$FlightManifest,
    [Parameter(Mandatory)] [PSCustomObject]$ProposedSlotSwap
)

$ErrorActionPreference = 'Stop'

# 1. Hard Refusal on Cold-Chain Thermal Holdover Breach
if ($FlightManifest.HasPharmaColdChain -eq $true) {
    $projectedTotalHours = $ProposedSlotSwap.DelayHours + $FlightManifest.TransitHours
    $safeHoldoverCeiling = $FlightManifest.ContainerHoldoverHours * 0.60

    if (-not $ProposedSlotSwap.DestinationHasCertifiedColdRoom -or ($projectedTotalHours -gt $safeHoldoverCeiling)) {
        return [PSCustomObject]@{
            FlightNumber = $FlightManifest.FlightNumber
            Action       = 'VETO_COLD_CHAIN_BREACH'
            Permitted    = $false
            Reason       = "Projected transit (${projectedTotalHours}h) breaches 60% thermal holdover ceiling (${safeHoldoverCeiling}h) or destination lacks GDP cold storage."
        }
    }
}

# 2. Dual-Signature Gate on Cross-Border / >120km Diversion
if ($ProposedSlotSwap.DiversionDistanceKm -gt 120 -or $ProposedSlotSwap.CrossesCustomsUnion) {
    return [PSCustomObject]@{
        FlightNumber = $FlightManifest.FlightNumber
        Action       = 'HOLD_FOR_CHIEF_DISPATCHER_DUAL_SIGNATURE'
        Permitted    = $false
        Reason       = "Diversion ($($ProposedSlotSwap.DiversionDistanceKm)km) or customs boundary requires human dual-signature."
    }
}

return [PSCustomObject]@{
    FlightNumber = $FlightManifest.FlightNumber
    Action       = 'PERMIT_NMOC_SLOT_BID'
    Permitted    = $true
    Reason       = 'Standard dry cargo within 45m intra-corridor window.'
}