param(
    [Parameter(Mandatory)]
    [string]$ReportPath,
    [string]$OutFile = "$PSScriptRoot\requests_contract.ps1"
)

if (-not (Test-Path $ReportPath)) { Throw "Report not found: $ReportPath" }

$reportJson = Get-Content $ReportPath -Raw | ConvertFrom-Json
$executions  = $reportJson.run.executions
if (-not $executions) { Throw 'No executions found in report.' }

$items = @()
foreach ($exe in $executions) {
    $req  = $exe.requestExecuted
    if (-not $req) { continue }

    $name   = $req.name
    $method = $req.method.ToUpper()

    # Build URL string (remove {{OPEN_API_URL}} placeholder)
    $urlRaw = $req.url.raw
    if (-not $urlRaw) {
        $hostParts = ($req.url.host) -join '/'
        $pathParts = ($req.url.path) -join '/'
        $urlRaw = "$hostParts/$pathParts"
        if ($req.url.query) {
            $q = $req.url.query | ForEach-Object { "$($_.key)=$($_.value)" } -join '&'
            if ($q) { $urlRaw += "?$q" }
        }
    }
    $url = $urlRaw -replace '\{\{OPEN_API_URL\}\}', ''
    $url = $url -replace '^tde-truckmate/tmwcloud/com/cur/(visibility|tm|finance|masterdata)/?', ''

    $expected = if ($method -eq 'GET') { 200 } else { 400 }

    $bodyObj = $null
    if ($req.body.raw) {
        try { $bodyObj = $req.body.raw | ConvertFrom-Json } catch { $bodyObj = $req.body.raw }
    }

    $items += @{ Name = $name; Method = $method; Url = $url; ExpectedStatus = $expected; Body = $bodyObj }
}

# Serialize to ps1 data file
$outLines = @('@@(')
foreach ($it in $items) {
    $bodyPart = if ($it.Body -ne $null) {
        ' Body = ' + ($it.Body | ConvertTo-Json -Depth 10 -Compress)
    } else { '' }
    $outLines += "    @{ Name = '$($it.Name)'; Method = '$($it.Method)'; Url = '$($it.Url)'; ExpectedStatus = $($it.ExpectedStatus);$bodyPart },"
}
$outLines += ')'
$outLines -replace '@@','@' | Set-Content $OutFile -Encoding UTF8

Write-Host "Generated $($items.Count) requests to $OutFile"
