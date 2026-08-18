param(
    [Parameter(Mandatory=$true)]
    [string]$JtlFile,

    [double]$MaxErrorRate = 1.0,
    [int]$TR02P95MaxMs = 2000,
    [int]$TR03P95MaxMs = 2000,
    [int]$TR04P95MaxMs = 2000,
    [int]$TR05P95MaxMs = 4000
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $JtlFile)) {
    Write-Host "QUALITY GATE: JTL nao encontrado: $JtlFile"
    exit 1
}

$data = Import-Csv -Path $JtlFile

if (-not $data -or $data.Count -eq 0) {
    Write-Host "QUALITY GATE: JTL vazio."
    exit 1
}

function Get-Percentile {

    param(
        [array]$Values,
        [double]$Percentile
    )

    $sorted = @(
        $Values |
        ForEach-Object { [double]$_ } |
        Sort-Object
    )

    if ($sorted.Count -eq 0) {
        return $null
    }

    $rank = [Math]::Ceiling(
        ($Percentile / 100.0) * $sorted.Count
    )

    if ($rank -lt 1) {
        $rank = 1
    }

    if ($rank -gt $sorted.Count) {
        $rank = $sorted.Count
    }

    return [Math]::Round(
        $sorted[$rank - 1],
        0
    )
}

# Consideramos apenas os Transaction Controllers
# para evitar duplicar sampler filho + transacao.

$transactions = @(
    $data |
    Where-Object {
        $_.label -match '^TR0[1-5]\s*-'
    }
)

if ($transactions.Count -eq 0) {

    Write-Host "Nenhuma Transaction Controller encontrada."

    exit 1
}

$failedTransactions = @(
    $transactions |
    Where-Object {
        $_.success -ne 'true'
    }
)

$errorRate = (
    $failedTransactions.Count /
    [double]$transactions.Count
) * 100

$errorRate = [Math]::Round(
    $errorRate,
    2
)

$gateFailed = $false

$summary = @()

$summary += "=============================================="
$summary += " JMETER PERFORMANCE QUALITY GATE"
$summary += "=============================================="
$summary += ""
$summary += "Arquivo: $JtlFile"
$summary += "Transacoes: $($transactions.Count)"
$summary += "Falhas: $($failedTransactions.Count)"
$summary += "Error Rate: $errorRate% | Limite: < $MaxErrorRate%"
$summary += ""

if ($errorRate -ge $MaxErrorRate) {
    $summary += "[FAIL] Error Rate >= $MaxErrorRate%"
    $gateFailed = $true
}
else {
    $summary += "[PASS] Error Rate < $MaxErrorRate%"
}

$rules = @(

    @{
        Prefix = "TR02"
        Name   = "Navegacao"
        Limit  = $TR02P95MaxMs
    },

    @{
        Prefix = "TR03"
        Name   = "Carrinho"
        Limit  = $TR03P95MaxMs
    },

    @{
        Prefix = "TR04"
        Name   = "Checkout"
        Limit  = $TR04P95MaxMs
    },

    @{
        Prefix = "TR05"
        Name   = "Pagamento"
        Limit  = $TR05P95MaxMs
    }
)

Write-Host ""

foreach ($rule in $rules) {

    $samples = @(
        $data |
        Where-Object {
            $_.label -like "$($rule.Prefix)*"
        }
    )

    if ($samples.Count -eq 0) {

        $summary += "[FAIL] $($rule.Name) - sem samples"

        $gateFailed = $true

        continue
    }

    $elapsed = @(
        $samples |
        ForEach-Object {
            [double]$_.elapsed
        }
    )

    $p95 = Get-Percentile `
        -Values $elapsed `
        -Percentile 95

    if ($p95 -lt $rule.Limit) {

        $summary += "[PASS] $($rule.Name) | P95=${p95}ms | Limite < $($rule.Limit)ms"

    }
    else {

        $summary += "[FAIL] $($rule.Name) | P95=${p95}ms | Limite < $($rule.Limit)ms"

        $gateFailed = $true
    }
}

Write-Host ""
Write-Host "=============================================="

if ($gateFailed) {
$summary += ""
$summary += "=============================================="

if ($gateFailed) {

    $summary += " QUALITY GATE: FAILED"

}
else {

    $summary += " QUALITY GATE: PASSED"
}

$summary += "=============================================="

$jtlName = [System.IO.Path]::GetFileNameWithoutExtension($JtlFile)
$summaryPath = Join-Path `
    (Split-Path $JtlFile -Parent) `
    "$jtlName-quality-gate.txt"

$summary |
    Set-Content `
        -Path $summaryPath `
        -Encoding UTF8

$summary |
    ForEach-Object {
        Write-Host $_
    }

Write-Host ""
Write-Host "Resumo salvo em:"
Write-Host $summaryPath

if ($gateFailed) {
    exit 1
}
else {

    exit 0
}