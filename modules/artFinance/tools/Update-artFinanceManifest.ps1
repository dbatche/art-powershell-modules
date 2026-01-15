param(
    [switch]$WhatIf
)

$moduleRoot = Split-Path -Parent $PSScriptRoot
$moduleName = Split-Path -Leaf $moduleRoot
$psm1Path = Join-Path $moduleRoot ($moduleName + '.psm1')
$psd1Path = Join-Path $moduleRoot ($moduleName + '.psd1')

if (!(Test-Path $psm1Path)) {
    throw "Expected module root module not found: $psm1Path"
}

Write-Host "Scanning public function files..." -ForegroundColor Cyan
$publicFiles = Get-ChildItem -Path $moduleRoot -Recurse -File -Filter '*.Public.ps1' -ErrorAction Stop

if ($publicFiles.Count -eq 0) {
    throw "No *.Public.ps1 files found under: $moduleRoot"
}

$parseErrors = $null
$tokens = $null

$functionNames = foreach ($file in $publicFiles) {
    $text = Get-Content -Path $file.FullName -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$parseErrors)

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $errSummaries = $parseErrors | ForEach-Object { $_.Message } | Select-Object -Unique
        throw "Parse error(s) in $($file.FullName): $($errSummaries -join '; ')"
    }

    $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
        ForEach-Object { $_.Name }
}

$functionNames =
    $functionNames |
    Where-Object { $_ } |
    Sort-Object -Unique

Write-Host ("Found {0} exported function(s)." -f $functionNames.Count) -ForegroundColor Green

if (!(Test-Path $psd1Path)) {
    Write-Host "Creating manifest: $psd1Path" -ForegroundColor Cyan
    New-ModuleManifest `
        -Path $psd1Path `
        -RootModule (Split-Path -Leaf $psm1Path) `
        -ModuleVersion '0.1.0' `
        -Description "$moduleName module" `
        -FunctionsToExport $functionNames `
        -AliasesToExport @() `
        -CmdletsToExport @() `
        -VariablesToExport @() `
        -DscResourcesToExport @() `
        -WhatIf:$WhatIf `
        | Out-Null
}
else {
    Write-Host "Updating manifest: $psd1Path" -ForegroundColor Cyan
    Update-ModuleManifest `
        -Path $psd1Path `
        -RootModule (Split-Path -Leaf $psm1Path) `
        -FunctionsToExport $functionNames `
        -AliasesToExport @() `
        -CmdletsToExport @() `
        -VariablesToExport @() `
        -DscResourcesToExport @() `
        -WhatIf:$WhatIf `
        | Out-Null
}

Write-Host "Done." -ForegroundColor Green

