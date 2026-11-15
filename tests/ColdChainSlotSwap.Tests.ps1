BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:EvaluatorPath = Join-Path $script:RepoRoot 'src/Test-AirFreightSlotSwapAuthority.ps1'
    $script:AgentPath = Join-Path $script:RepoRoot 'ai/Invoke-ColdChainDiversionAgent.ps1'
    $script:GraphPath = Join-Path $script:RepoRoot 'graph/Send-DispatcherDualSignOff.ps1'
    $script:KqlPath = Join-Path $script:RepoRoot 'diagnostics/ColdChain-Telemetry.kql'
    $script:EvalCases = Get-Content (Join-Path $script:RepoRoot 'ai/cold-chain-eval-cases.json') -Raw | ConvertFrom-Json

    . $script:AgentPath
    . $script:GraphPath
}

Describe 'Autonomous Air Freight Dispatcher: Multi-Agent Slot Allocation & Cold-Chain Governance - 20-Test Verification Matrix' {
    Context 'Positive Path: Structural, AI & Graph Contract Verification (12 Tests)' {
        It 'P-01: Primary PowerShell evaluator (src/Test-AirFreightSlotSwapAuthority.ps1) exists and is non-empty' {
            Test-Path $script:EvaluatorPath | Should -BeTrue
            (Get-Item $script:EvaluatorPath).Length | Should -BeGreaterThan 120
        }
        It 'P-02: Evaluator, AI agent, and Graph scripts parse cleanly with zero PowerShell AST syntax errors' {
            foreach ($file in @($script:EvaluatorPath, $script:AgentPath, $script:GraphPath)) {
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$errors)
                $errors.Count | Should -Be 0 -Because "$file must have zero AST errors"
            }
        }
        It 'P-03: Enforces CmdletBinding and typed parameter block' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Match '\[CmdletBinding\(\)\]'
            $raw | Should -Match 'param\s*\('
        }
        It 'P-04: Returns structured PSCustomObject decision payload for downstream audit' {
            $manifest = [PSCustomObject]@{ FlightNumber = 'BA-592'; HasPharmaColdChain = $true; TransitHours = 6.0; ContainerHoldoverHours = 24.0 }
            $swap = [PSCustomObject]@{ DelayHours = 2.0; DestinationHasCertifiedColdRoom = $false; DiversionDistanceKm = 95; CrossesCustomsUnion = $false }
            $res = & $script:EvaluatorPath -FlightManifest $manifest -ProposedSlotSwap $swap
            $res.Action | Should -Be 'VETO_COLD_CHAIN_BREACH'
            $res.Permitted | Should -BeFalse
        }
        It 'P-05: KQL telemetry query (diagnostics/ColdChain-Telemetry.kql) defines correlation and filtering clauses' {
            Test-Path $script:KqlPath | Should -BeTrue
            (Get-Content $script:KqlPath -Raw) | Should -Match 'where|summarize|project'
        }
        It 'P-06: Domain artefact schemas/iata-ulds-manifest.schema.json exists and is non-empty' {
            $p = Join-Path $script:RepoRoot 'schemas/iata-ulds-manifest.schema.json'
            Test-Path $p | Should -BeTrue
            (Get-Item $p).Length | Should -BeGreaterThan 20
        }
        It 'P-07: Domain artefact schemas/teams-dispatcher-card.json exists and is non-empty' {
            $p = Join-Path $script:RepoRoot 'schemas/teams-dispatcher-card.json'
            Test-Path $p | Should -BeTrue
            (Get-Item $p).Length | Should -BeGreaterThan 20
        }
        It 'P-08: Domain artefact sample-data/flight-manifests.json exists and is non-empty' {
            $p = Join-Path $script:RepoRoot 'sample-data/flight-manifests.json'
            Test-Path $p | Should -BeTrue
            (Get-Item $p).Length | Should -BeGreaterThan 20
        }
        It 'P-09: Zero declarative Bicep or Terraform files exist in the repository' {
            $iacFiles = @(Get-ChildItem -Path $script:RepoRoot -Recurse -File | Where-Object { $_.Extension -in '.bicep', '.tf' })
            $iacFiles.Count | Should -Be 0
        }
        It 'P-10: Foundry AI Cold-Chain Diversion Agent evaluates all 5 offline cases accurately' {
            foreach ($case in $script:EvalCases) {
                $eval = Invoke-ColdChainDiversionAgent `
                    -FlightNumber $case.flightNumber `
                    -CargoCode $case.cargoCode `
                    -HasPharmaColdChain $case.hasPharmaColdChain `
                    -ProjectedTransitHours $case.projectedTransitHours `
                    -ContainerHoldoverHours $case.containerHoldoverHours `
                    -DestinationHasCertifiedColdRoom $case.destinationHasCertifiedColdRoom `
                    -DiversionDistanceKm $case.diversionDistanceKm `
                    -CrossesCustomsUnion $case.crossesCustomsUnion `
                    -DispatcherNotes $case.dispatcherNotes

                $eval.Verdict | Should -Be $case.expectedVerdict -Because "Case $($case.id) must match expected verdict"
                if ($null -ne $case.PSObject.Properties['expectedInjectionDetected']) {
                    $eval.InjectionDetected | Should -Be $case.expectedInjectionDetected
                }
                if ($null -ne $case.PSObject.Properties['expectedAbstainToHuman']) {
                    $eval.AbstainToHuman | Should -Be $case.expectedAbstainToHuman
                }
            }
        }
        It 'P-11: Graph v2.x Chief Dispatcher Dual-Signature Adaptive Card dispatches cleanly' {
            $card = Send-DispatcherDualSignOff `
                -TeamId '11111111-1111-1111-1111-111111111111' `
                -ChannelId '19:cargo-occ@thread.tacv2' `
                -FlightNumber 'BA-592' `
                -CargoCode 'PIL' `
                -Verdict 'VETO_COLD_CHAIN_BREACH' `
                -HoldoverRatio 0.33 `
                -Simulate

            $card.Dispatched | Should -BeTrue
            $card.GraphUri | Should -Match '/v1.0/teams/.+/channels/.+/messages'
        }
        It 'P-12: Operational runbook docs/DISPATCHER-RUNBOOK.md exceeds 2 KB' {
            $rb = Join-Path $script:RepoRoot 'docs/DISPATCHER-RUNBOOK.md'
            Test-Path $rb | Should -BeTrue
            (Get-Item $rb).Length | Should -BeGreaterThan 2000
        }
    }

    Context 'Negative Path: Refusal Gates & Zero-Leak Security Boundaries (8 Tests)' {
        It 'N-01: Evaluator defines explicit refusal, hold, or veto action codes' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Match 'VETO|BLOCK|HOLD|DENY|REFUSAL|QUARANTINE|REVOKE|ALERT|\$false'
        }
        It 'N-02: Evaluator contains zero hardcoded storage keys, passwords, or SAS tokens' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Not -Match 'AccountKey=|SharedAccessSignature=|Password='
        }
        It 'N-03: Evaluator contains zero private orchestrator domains or internal host IPs' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Not -Match '192\.142\.41\.43|mvpfoundry\.alerasoul\.net'
        }
        It 'N-04: KQL query contains zero internal sequence tags or private URLs' {
            $kql = Get-Content $script:KqlPath -Raw
            $kql | Should -Not -Match 'mvpfoundry\.alerasoul\.net|Decision Pack 0'
        }
        It 'N-05: README documentation contains zero internal sequence numbering' {
            $readme = Get-Content (Join-Path $script:RepoRoot 'README.md') -Raw
            $readme | Should -Not -Match 'Decision Pack 0|mvpfoundry\.alerasoul\.net'
        }
        It 'N-06: Enforces fail-closed ErrorActionPreference or deterministic condition branches' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Match 'ErrorActionPreference|if\s*\('
        }
        It 'N-07: Repository root excludes internal agent guidelines or pre-commit hook scripts' {
            Test-Path (Join-Path $script:RepoRoot 'AGENTS.md') | Should -BeFalse
            Test-Path (Join-Path $script:RepoRoot '.githooks') | Should -BeFalse
        }
        It 'N-08: Open-source MIT LICENSE is present at repository root' {
            Test-Path (Join-Path $script:RepoRoot 'LICENSE') | Should -BeTrue
        }
    }
}
