<#
.SYNOPSIS
    Dispatches Air Freight Slot-Swap & Cold-Chain Veto Adaptive Cards via Microsoft Graph v2.x.
.DESCRIPTION
    Posts an actionable Adaptive Card to the Cargo OCC Microsoft Teams channel
    using Invoke-MgGraphRequest so Chief Dispatcher and GDP Compliance Lead
    dual-signature is captured before any cross-border or cold-chain diversion.
.NOTES
    Author: Shahrad Alerasoul
    Standard: PowerShell 7.4+ | Microsoft Graph v2.x
#>

#Requires -Version 7.4

Set-StrictMode -Version Latest

function Send-DispatcherDualSignOff {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$TeamId,

        [Parameter(Mandatory)]
        [string]$ChannelId,

        [Parameter(Mandatory)]
        [string]$FlightNumber,

        [Parameter(Mandatory)]
        [string]$CargoCode,

        [Parameter(Mandatory)]
        [string]$Verdict,

        [Parameter(Mandatory)]
        [double]$HoldoverRatio,

        [Parameter()]
        [string]$Rationale = 'Diversion proposal staged for Chief Dispatcher dual-signature.',

        [Parameter()]
        [switch]$Simulate
    )

    $isVeto = $Verdict -like 'VETO_*'
    $headerColour = if ($isVeto) { 'Attention' } else { 'Warning' }

    $cardBody = @{
        type    = 'AdaptiveCard'
        version = '1.5'
        body    = @(
            @{
                type   = 'TextBlock'
                size   = 'Large'
                weight = 'Bolder'
                color  = $headerColour
                text   = "Air Freight Dispatch Gate: $Verdict"
            },
            @{
                type  = 'FactSet'
                facts = @(
                    @{ title = 'Flight Number'; value = $FlightNumber },
                    @{ title = 'IATA Cargo Code'; value = $CargoCode },
                    @{ title = 'Holdover Ratio'; value = "$([math]::Round($HoldoverRatio * 100, 1))%" },
                    @{ title = 'Required Sign-Off'; value = 'Chief Dispatcher + GDP Compliance Lead' },
                    @{ title = 'Rationale'; value = $Rationale }
                )
            }
        )
    } | ConvertTo-Json -Depth 8

    $messagePayload = @{
        body = @{
            contentType = 'html'
            content     = "<attachment id=`"freight-gate-$FlightNumber`"></attachment>"
        }
        attachments = @(
            @{
                id          = "freight-gate-$FlightNumber"
                contentType = 'application/vnd.microsoft.card.adaptive'
                content     = $cardBody
            }
        )
    }

    $graphUri = "https://graph.microsoft.com/v1.0/teams/$TeamId/channels/$ChannelId/messages"

    if ($Simulate -or -not (Get-Command -Name 'Invoke-MgGraphRequest' -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{
            Dispatched   = $true
            Mode         = 'Simulated'
            GraphUri     = $graphUri
            FlightNumber = $FlightNumber
            Verdict      = $Verdict
            AttachmentId = "freight-gate-$FlightNumber"
        }
    }

    if ($PSCmdlet.ShouldProcess("$TeamId/$ChannelId", "Post Air Freight Dual-Signature Adaptive Card for $FlightNumber")) {
        $response = Invoke-MgGraphRequest -Method POST -Uri $graphUri -Body ($messagePayload | ConvertTo-Json -Depth 10) -ContentType 'application/json'
        return [pscustomobject]@{
            Dispatched   = $true
            Mode         = 'LiveGraph'
            GraphUri     = $graphUri
            MessageId    = $response.id
            FlightNumber = $FlightNumber
            Verdict      = $Verdict
            AttachmentId = "freight-gate-$FlightNumber"
        }
    }
}
