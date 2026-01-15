# Get-PostmanResourceGroups CLI Format Usage Examples

## Basic Usage

### 1. View commands with helpful comments (copy/paste to console)
```powershell
Get-PostmanResourceGroups -Path "report.json" -Format CLI
```

### 2. Capture commands in a variable
```powershell
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI
```

### 3. Get only actual commands (no comments/blanks)
```powershell
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }
```

## Running Commands

### 4. Run the first command immediately
```powershell
Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' } | 
    Select-Object -First 1 | 
    ForEach-Object { iex $_ }
```

### 5. Run all commands sequentially
```powershell
Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' } | 
    ForEach-Object { 
        Write-Host "Executing: $_" -ForegroundColor Cyan
        iex $_
    }
```

### 6. Run specific resource commands
```powershell
Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -match '# Resource: /checks' -or $_ -match 'postman collection run' } | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' } | 
    Select-Object -First 1 | 
    ForEach-Object { iex $_ }
```

## Background Jobs

### 7. Run commands as background jobs
```powershell
# Get all commands
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }

# Start first 3 commands as background jobs
$commands | Select-Object -First 3 | ForEach-Object {
    $cmd = $_
    Start-Job -ScriptBlock { 
        param($command)
        Invoke-Expression $command
    } -ArgumentList $cmd
}

# Check job status
Get-Job

# Get results when done
Get-Job | Wait-Job | Receive-Job
```

### 8. Run all commands in parallel with progress tracking
```powershell
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }

# Start all as jobs
$jobs = $commands | ForEach-Object {
    $cmd = $_
    # Extract resource name from previous comment if needed
    Start-Job -Name "PostmanRun-$([guid]::NewGuid())" -ScriptBlock { 
        param($command)
        Invoke-Expression $command
    } -ArgumentList $cmd
}

# Monitor progress
while ($jobs | Where-Object { $_.State -eq 'Running' }) {
    $completed = ($jobs | Where-Object { $_.State -eq 'Completed' }).Count
    $total = $jobs.Count
    Write-Host "`rCompleted: $completed / $total" -NoNewline
    Start-Sleep -Seconds 2
}

Write-Host "`nAll jobs completed!"
Get-Job | Receive-Job
```

### 9. Run commands with retry logic
```powershell
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI | 
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }

foreach ($cmd in $commands) {
    $maxRetries = 3
    $attempt = 0
    $success = $false
    
    while (-not $success -and $attempt -lt $maxRetries) {
        $attempt++
        Write-Host "Attempt $attempt of $maxRetries..." -ForegroundColor Yellow
        
        try {
            Invoke-Expression $cmd
            $success = $true
            Write-Host "Success!" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $_" -ForegroundColor Red
            if ($attempt -lt $maxRetries) {
                Start-Sleep -Seconds 5
            }
        }
    }
}
```

## Advanced Filtering

### 10. Run only resources with fewer than 10 tests
```powershell
$output = Get-PostmanResourceGroups -Path "report.json" -Format CLI

$i = 0
$lines = @($output)
while ($i -lt $lines.Count) {
    if ($lines[$i] -match '# Resource: .* \((\d+) tests\)') {
        $testCount = [int]$matches[1]
        if ($testCount -lt 10) {
            $command = $lines[$i + 1]
            if ($command -notmatch '^#' -and $command -notmatch '^\s*$') {
                Write-Host "Running: $($lines[$i])" -ForegroundColor Cyan
                iex $command
            }
        }
    }
    $i++
}
```

## With Newman Structure

### 11. Generate commands with Newman structure for reusable reports
```powershell
Get-PostmanResourceGroups -Path "report.json" -Format CLI -NewmanStructure

# The generated commands will include:
# --reporters json --reporter-json-structure newman
# This ensures the output files can be analyzed with Get-PostmanResourceGroups again
```

## Notes

- **Comments are safe**: The `#` comments won't cause errors if copied with commands
- **Blank lines**: Empty string output creates visual separation (safe to ignore or filter)
- **Headers/Footers**: `Write-Host` output shows context but doesn't interfere with pipeline
- **Error handling**: Consider adding `try/catch` when using `iex` for production scripts
- **Job cleanup**: Remember to run `Get-Job | Remove-Job` after receiving results

