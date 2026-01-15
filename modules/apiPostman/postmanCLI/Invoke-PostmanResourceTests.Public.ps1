<#
.SYNOPSIS
    Helper script to run Postman CLI commands from Get-PostmanResourceGroups output.

.DESCRIPTION
    Simplifies running resource-specific tests by filtering and executing commands
    from Get-PostmanResourceGroups CLI format output. Supports sequential and
    parallel (background job) execution.

.PARAMETER Path
    Path to the Postman JSON report file.

.PARAMETER ResourceFilter
    Optional regex pattern to filter resources (e.g., "checks|apInvoices").

.PARAMETER MaxResources
    Maximum number of resources to run (default: all).

.PARAMETER Parallel
    Run commands as background jobs instead of sequentially.

.PARAMETER NewmanStructure
    Include --reporter-json-structure newman in commands.

.EXAMPLE
    Invoke-PostmanResourceTests -Path "report.json" -MaxResources 1
    
    Runs the first resource test synchronously.

.EXAMPLE
    Invoke-PostmanResourceTests -Path "report.json" -ResourceFilter "checks|apInvoices"
    
    Runs only /checks and /apInvoices resources.

.EXAMPLE
    Invoke-PostmanResourceTests -Path "report.json" -Parallel -MaxResources 3
    
    Runs the first 3 resources as background jobs.

.NOTES
    File Name      : Invoke-PostmanResourceTests.Public.ps1
    Prerequisite   : PowerShell 5.1 or higher, Get-PostmanResourceGroups
#>

function Invoke-PostmanResourceTests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$ResourceFilter,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxResources,
        
        [Parameter(Mandatory=$false)]
        [switch]$Parallel,
        
        [Parameter(Mandatory=$false)]
        [switch]$NewmanStructure
    )
    
    # Get all commands
    Write-Host "Generating commands..." -ForegroundColor Cyan
    $params = @{
        Path = $Path
        Format = 'CLI'
    }
    if ($NewmanStructure) {
        $params.NewmanStructure = $true
    }
    
    $output = Get-PostmanResourceGroups @params
    
    # Extract commands with their resource comments
    $lines = @($output)
    $commandPairs = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^# Resource: (.+) \((\d+) tests\)') {
            $resourceName = $matches[1]
            $testCount = $matches[2]
            
            # Next line should be the command
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match '^postman collection run') {
                $command = $lines[$i + 1]
                
                # Apply filter if specified
                if (-not $ResourceFilter -or $resourceName -match $ResourceFilter) {
                    $commandPairs += [PSCustomObject]@{
                        Resource = $resourceName
                        TestCount = $testCount
                        Command = $command
                    }
                }
            }
        }
    }
    
    # Apply max resources limit
    if ($MaxResources -gt 0 -and $commandPairs.Count -gt $MaxResources) {
        $commandPairs = $commandPairs | Select-Object -First $MaxResources
    }
    
    Write-Host ""
    Write-Host "Found $($commandPairs.Count) resource(s) to run" -ForegroundColor Green
    Write-Host ""
    
    if ($commandPairs.Count -eq 0) {
        Write-Warning "No resources matched the criteria"
        return
    }
    
    if ($Parallel) {
        # Run as background jobs
        Write-Host "Starting background jobs..." -ForegroundColor Yellow
        $jobs = @()
        
        foreach ($pair in $commandPairs) {
            Write-Host "  Starting: $($pair.Resource) ($($pair.TestCount) tests)" -ForegroundColor Gray
            
            $job = Start-Job -Name "Postman-$($pair.Resource.Replace('/', ''))" -ScriptBlock {
                param($cmd)
                Invoke-Expression $cmd
            } -ArgumentList $pair.Command
            
            $jobs += $job
        }
        
        Write-Host ""
        Write-Host "All jobs started. Use the following commands to monitor:" -ForegroundColor Cyan
        Write-Host "  Get-Job                    # Check status" -ForegroundColor Gray
        Write-Host "  Get-Job | Wait-Job         # Wait for completion" -ForegroundColor Gray
        Write-Host "  Get-Job | Receive-Job      # Get results" -ForegroundColor Gray
        Write-Host "  Get-Job | Remove-Job       # Clean up" -ForegroundColor Gray
        Write-Host ""
        
        # Return job objects
        return $jobs
    }
    else {
        # Run sequentially
        $results = @()
        $current = 0
        
        foreach ($pair in $commandPairs) {
            $current++
            Write-Host "[$current/$($commandPairs.Count)] Running: $($pair.Resource) ($($pair.TestCount) tests)" -ForegroundColor Yellow
            Write-Host "Command: $($pair.Command)" -ForegroundColor Gray
            Write-Host ""
            
            try {
                $startTime = Get-Date
                Invoke-Expression $pair.Command
                $duration = (Get-Date) - $startTime
                
                Write-Host ""
                Write-Host "Completed in $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Green
                Write-Host ("=" * 100) -ForegroundColor DarkGray
                Write-Host ""
                
                $results += [PSCustomObject]@{
                    Resource = $pair.Resource
                    Status = "Success"
                    Duration = $duration
                }
            }
            catch {
                Write-Host ""
                Write-Host "ERROR: $_" -ForegroundColor Red
                Write-Host ("=" * 100) -ForegroundColor DarkGray
                Write-Host ""
                
                $results += [PSCustomObject]@{
                    Resource = $pair.Resource
                    Status = "Failed"
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Summary
        Write-Host ""
        Write-Host "=" * 100 -ForegroundColor Magenta
        Write-Host "EXECUTION SUMMARY" -ForegroundColor Magenta
        Write-Host "=" * 100 -ForegroundColor Magenta
        $results | Format-Table -AutoSize
        
        return $results
    }
}

