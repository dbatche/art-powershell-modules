param(
    [string]$OutFile = (Join-Path (Split-Path -Parent $PSScriptRoot) 'artFinance.help-index.md'),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot

function Get-HelpBlockForFunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$FunctionName
    )

    $fn = [regex]::Escape($FunctionName)

    # Pattern A: help block immediately preceding function keyword
    # NOTE: In PowerShell string literals, backslash does not need escaping. Use \s, not \\s.
    $patternBefore = "(?s)<#(.*?)#>\s*function\s+$fn\b"
    $m = [regex]::Match($Content, $patternBefore)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }

    # Pattern B: help block immediately after `function Name {`
    # This matches the style used in artFinance (help block inside function body).
    $patternAfterBrace = "(?s)function\s+$fn\b[^{]*\{\s*<#(.*?)#>"
    $m = [regex]::Match($Content, $patternAfterBrace)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }

    return $null
}

function Get-HelpBlockForFunctionAst {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst
    )

    # Prefer using AST offsets to avoid any name/regex edge cases.
    $start = $FunctionAst.Extent.StartOffset
    $end = $FunctionAst.Extent.EndOffset
    if ($start -lt 0 -or $end -le $start -or $end -gt $Content.Length) {
        return $null
    }

    # Only scan the beginning of the function for speed.
    $maxScan = [Math]::Min($end - $start, 8000)
    $chunk = $Content.Substring($start, $maxScan)

    # Match a help block immediately after the opening brace.
    $m = [regex]::Match($chunk, "(?s)\{\s*<#(.*?)#>")
    if ($m.Success) {
        return $m.Groups[1].Value.Trim()
    }

    # Fallback: some styles put help before the function keyword.
    return $null
}

function Parse-CommentHelp {
    param(
        [string]$HelpBlock
    )

    if (-not $HelpBlock) {
        return [pscustomobject]@{
            Synopsis    = $null
            Description = $null
            Parameters  = @()
            Examples    = @()
        }
    }

    # Use a non-capturing newline split (capturing groups in -split include the delimiters as tokens)
    $lines = $HelpBlock -split '\r?\n'
    $section = $null
    $synopsis = New-Object System.Text.StringBuilder
    $description = New-Object System.Text.StringBuilder
    $examples = New-Object System.Text.StringBuilder
    $params = New-Object System.Collections.Generic.List[object]
    $currentParam = $null

    foreach ($raw in $lines) {
        $line = ($raw ?? '').TrimEnd()

        # Support common styles:
        # - .SYNOPSIS
        # - # .SYNOPSIS   (some people include comment markers inside <# #>)
        if ($line -match '^\s*#?\s*\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE)\b\s*(.*)$') {
            $section = $matches[1].ToUpperInvariant()

            if ($section -eq 'PARAMETER') {
                $currentParam = [pscustomobject]@{
                    Name = $matches[2].Trim()
                    Text = New-Object System.Text.StringBuilder
                }
                if ($currentParam.Name) {
                    $params.Add($currentParam)
                }
            }

            continue
        }

        switch ($section) {
            'SYNOPSIS'    { [void]$synopsis.AppendLine($line) }
            'DESCRIPTION' { [void]$description.AppendLine($line) }
            'EXAMPLE'     { [void]$examples.AppendLine($line) }
            'PARAMETER'   {
                if ($currentParam) { [void]$currentParam.Text.AppendLine($line) }
            }
        }
    }

    return [pscustomobject]@{
        Synopsis    = ($synopsis.ToString().Trim())
        Description = ($description.ToString().Trim())
        Parameters  = @(
            foreach ($p in $params) {
                [pscustomobject]@{
                    Name = $p.Name
                    Text = ($p.Text.ToString().Trim())
                }
            }
        )
        Examples    = @(
            $exText = $examples.ToString().Trim()
            if ($exText) { $exText }
        )
    }
}

Write-Host "Scanning public function files under: $moduleRoot" -ForegroundColor Cyan
$publicFiles = Get-ChildItem -Path $moduleRoot -Recurse -File -Filter '*.Public.ps1'

if ($publicFiles.Count -eq 0) {
    throw "No *.Public.ps1 files found under: $moduleRoot"
}

$entries = foreach ($file in $publicFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $parseErrors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $errSummaries = $parseErrors | ForEach-Object { $_.Message } | Select-Object -Unique
        throw "Parse error(s) in $($file.FullName): $($errSummaries -join '; ')"
    }

    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        $helpBlock = Get-HelpBlockForFunctionAst -Content $content -FunctionAst $fn
        if (-not $helpBlock) {
            $helpBlock = Get-HelpBlockForFunction -Content $content -FunctionName $fn.Name
        }
        $help = Parse-CommentHelp -HelpBlock $helpBlock

        [pscustomobject]@{
            Name        = $fn.Name
            File        = $file.FullName
            Synopsis    = $help.Synopsis
            Description = $help.Description
            Parameters  = $help.Parameters
            Examples    = $help.Examples
        }
    }
}

$entries = $entries | Sort-Object Name

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# artFinance help index")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("Module root: $moduleRoot")
[void]$sb.AppendLine("Total functions: $($entries.Count)")
[void]$sb.AppendLine(("Synopses found: {0}" -f (($entries | Where-Object { $_.Synopsis } | Measure-Object).Count)))
[void]$sb.AppendLine(("Descriptions found: {0}" -f (($entries | Where-Object { $_.Description } | Measure-Object).Count)))
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Functions")
[void]$sb.AppendLine("")

foreach ($e in $entries) {
    [void]$sb.AppendLine("### $($e.Name)")
    [void]$sb.AppendLine("")
    # Keep output simple and parse-safe (no markdown backticks) for maximum compatibility.
    [void]$sb.AppendLine(('- File: ' + $e.File))
    if ($e.Synopsis) {
        [void]$sb.AppendLine(("- Synopsis: {0}" -f ($e.Synopsis -replace '\s+', ' ')))
    }
    [void]$sb.AppendLine("")

    if ($e.Description) {
        [void]$sb.AppendLine("#### Description")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine($e.Description)
        [void]$sb.AppendLine("")
    }

    if ($e.Parameters -and $e.Parameters.Count -gt 0) {
        [void]$sb.AppendLine("#### Parameters")
        [void]$sb.AppendLine("")
        foreach ($p in $e.Parameters) {
            if ($p.Name) {
                $pText = ($p.Text ?? '').Trim()
                if ($pText) {
                    [void]$sb.AppendLine(('- ' + $p.Name + ': ' + ($pText -replace '\s+', ' ')))
                }
                else {
                    [void]$sb.AppendLine(('- ' + $p.Name))
                }
            }
        }
        [void]$sb.AppendLine("")
    }

    if ($e.Examples -and $e.Examples.Count -gt 0) {
        [void]$sb.AppendLine("#### Examples")
        [void]$sb.AppendLine("")
        foreach ($ex in $e.Examples) {
            if ($ex) {
                # Use single quotes to avoid PowerShell backtick escaping inside double-quoted strings.
                [void]$sb.AppendLine('```powershell')
                [void]$sb.AppendLine($ex.Trim())
                [void]$sb.AppendLine('```')
                [void]$sb.AppendLine("")
            }
        }
    }
}

if ($WhatIf) {
    Write-Host ("WhatIf: would write {0}" -f $OutFile) -ForegroundColor Yellow
    return
}

New-Item -ItemType Directory -Path (Split-Path -Parent $OutFile) -Force | Out-Null
Set-Content -Path $OutFile -Value $sb.ToString() -Encoding UTF8

Write-Host ("Wrote: {0}" -f $OutFile) -ForegroundColor Green

