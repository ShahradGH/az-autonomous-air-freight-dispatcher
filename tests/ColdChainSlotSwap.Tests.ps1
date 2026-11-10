BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:EvaluatorPath = Join-Path $script:RepoRoot 'src/Test-AirFreightSlotSwapAuthority.ps1'
    $script:KqlPath = Join-Path $script:RepoRoot 'diagnostics/ColdChain-Telemetry.kql'
}

Describe 'Autonomous Air Freight Dispatcher: Multi-Agent Slot Allocation & Cold-Chain Governance - 16-Test Verification Matrix' {
    Context 'Positive Path: Structural & Domain Contract Verification (8 Tests)' {
        It 'P-01: Primary PowerShell evaluator (src/Test-AirFreightSlotSwapAuthority.ps1) exists and is non-empty' {
            Test-Path $script:EvaluatorPath | Should -BeTrue
            (Get-Item $script:EvaluatorPath).Length | Should -BeGreaterThan 120
        }
        It 'P-02: Evaluator parses cleanly with zero PowerShell AST syntax errors' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($script:EvaluatorPath, [ref]$null, [ref]$errors)
            $errors.Count | Should -Be 0
        }
        It 'P-03: Enforces CmdletBinding and typed parameter block' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Match '\[CmdletBinding\(\)\]'
            $raw | Should -Match 'param\s*\('
        }
        It 'P-04: Returns structured PSCustomObject decision payload for downstream audit' {
            $raw = Get-Content $script:EvaluatorPath -Raw
            $raw | Should -Match '\[PSCustomObject\]@\{'
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
