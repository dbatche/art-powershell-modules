param(
    [Parameter(Mandatory)]
    [string]$CollectionPath,
    [string]$OutFile = "$PSScriptRoot\requests_governance.ps1"
)

function Get-ItemsRecursive($items) {
    foreach ($it in $items) {
        if ($it.item) { Get-ItemsRecursive $it.item }
        else { $it }
    }
}

if (-not (Test-Path $CollectionPath)) { throw "Collection file not found." }

$col = Get-Content $CollectionPath -Raw | ConvertFrom-Json
$all = Get-ItemsRecursive $col.item

$mapLimit = @{ decimal = '1.1'; negative = '-5'; 'out of bounds' = '99999'; string='abc' }
$mapOffset = @{ decimal = '1.1'; negative='-2'; 'out of bounds'='99999'; string='abc' }

$out = @()
foreach ($i in $all) {
    $name = $i.name
    if ($name -match '^(limit|offset) - (.+)$') {
        $kind = $matches[1]
        $variant = $matches[2].Trim()
        $value = if ($kind -eq 'limit') { $mapLimit[$variant] } else { $mapOffset[$variant] }
        if ($value) {
            $url = "/orders?$kind=$value"
            $out += @{ Name = $name; Method = $i.request.method; Url = $url; ExpectedStatus = 400 }
        }
    }
}

$outLines = @("@(")
foreach ($o in $out) {
    $outLines += "    @{ Name = '$($o.Name)'; Method = '$($o.Method)'; Url = '$($o.Url)'; ExpectedStatus = $($o.ExpectedStatus) },"
}
$outLines += ')'
$outLines | Set-Content $OutFile -Encoding utf8

Write-Host "Generated $($out.Count) entries to $OutFile"
