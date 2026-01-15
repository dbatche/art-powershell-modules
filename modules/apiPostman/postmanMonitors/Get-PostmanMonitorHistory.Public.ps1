function Get-PostmanMonitorHistory {
	<#
	.SYNOPSIS
	Analyzes historical Postman monitor results from saved JSON files
	
	.DESCRIPTION
	Reads the daily monitor JSON files and extracts historical data for a specific monitor.
	Shows trends in status, assertion success rate, request count, script errors, and run duration over time.
	
	.PARAMETER MonitorName
	Name or regex pattern to match the monitor name (e.g., "Finance", "^TM - Contract")
	
	.PARAMETER Path
	Directory containing the historical JSON files
	Default: C:\PostmanReports\MonitorHistory
	
	.PARAMETER Days
	Number of days of history to retrieve (default: 10)
	
	.PARAMETER Format
	Output format: Table (default), List, or Raw
	
	.EXAMPLE
	Get-PostmanMonitorHistory -MonitorName "Finance"
	
	Shows 10 day history for monitors matching "Finance" in table format
	
	.EXAMPLE
	Get-PostmanMonitorHistory -MonitorName "^TM - Contract" -Days 30
	
	Shows 30 day history for monitors starting with "TM - Contract"
	
	.EXAMPLE
	Get-PostmanMonitorHistory -MonitorName "Finance" -Format List
	
	Shows detailed list format with all available fields
	
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$MonitorName,
		
		[string]$Path = "C:\PostmanReports\MonitorHistory",
		
		[int]$Days = 10,
		
		[ValidateSet('Table', 'List', 'Raw')]
		[string]$Format = 'Table'
	)
	
	# Validate path exists
	if (-not (Test-Path $Path)) {
		Write-Error "Path not found: $Path"
		return
	}
	
	# Calculate date range
	$endDate = Get-Date
	$startDate = $endDate.AddDays(-$Days)
	
	Write-Verbose "Searching for monitors matching: $MonitorName"
	Write-Verbose "Date range: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))"
	
	# Get all JSON files in the date range
	$allFiles = Get-ChildItem -Path $Path -Filter "Monitors_*.json" | 
		Where-Object { 
			# Extract date from filename (format: Monitors_yyyy-MM-dd.json)
			if ($_.Name -match 'Monitors_(\d{4}-\d{2}-\d{2})\.json') {
				$fileDate = [DateTime]::ParseExact($matches[1], 'yyyy-MM-dd', $null)
				$fileDate -ge $startDate -and $fileDate -le $endDate
			}
		} | 
		Sort-Object Name
	
	if ($allFiles.Count -eq 0) {
		Write-Warning "No monitor files found in the specified date range"
		return
	}
	
	Write-Verbose "Found $($allFiles.Count) files to process"
	
	# Process each file and extract monitor data
	$history = @()
	
	foreach ($file in $allFiles) {
		Write-Verbose "Processing: $($file.Name)"
		
		# Extract date from filename
		$file.Name -match 'Monitors_(\d{4}-\d{2}-\d{2})\.json' | Out-Null
		$fileDate = $matches[1]
		
		try {
			# Read and parse JSON
			$content = Get-Content $file.FullName -Raw | ConvertFrom-Json
			
			# Filter monitors matching the name pattern
			$matchingMonitors = $content | Where-Object { $_.name -match $MonitorName }
			
			foreach ($monitor in $matchingMonitors) {
				# Extract key metrics from the monitor data
				$successfulAssertions = $monitor.assertions - $monitor.failed
				$successRate = if ($monitor.assertions -gt 0) { 
					[math]::Round((($monitor.assertions - $monitor.failed) / $monitor.assertions) * 100, 2) 
				} else { 0 }
				
				$history += [PSCustomObject]@{
					Date = $fileDate
					MonitorName = $monitor.name
					UID = $monitor.uid
					Status = $monitor.status
					Requests = $monitor.requests
					TotalAssertions = $monitor.assertions
					PassedAssertions = $successfulAssertions
					FailedAssertions = $monitor.failed
					SuccessRate = $successRate
					FailPercentage = $monitor.failPercentage
					ScriptErrors = $monitor.scriptErrors
					RunMinutes = [math]::Round($monitor.runMinutes, 2)
					StartedAt = $monitor.startedAt
					FinishedAt = $monitor.finishedAt
				}
			}
		}
		catch {
			Write-Warning "Error processing file $($file.Name): $_"
		}
	}
	
	if ($history.Count -eq 0) {
		Write-Warning "No monitors found matching pattern: $MonitorName"
		return
	}
	
	# Output results based on format
	switch ($Format) {
		'Raw' {
			$history
		}
		'List' {
			$history | Format-List
		}
		default {
			# Table format - show key metrics
			$headerText = "Monitor History for: $MonitorName"
			Write-Host "`n$headerText" -ForegroundColor Cyan
			Write-Host ("=" * $headerText.Length) -ForegroundColor Cyan
			
			$history | Format-Table -Property Date, Status, Requests, TotalAssertions, PassedAssertions, FailedAssertions, SuccessRate, ScriptErrors, RunMinutes -AutoSize
			
			# Summary statistics
			if ($history.Count -gt 0) {
				$totalRequests = ($history | Measure-Object -Property Requests -Sum).Sum
				$totalAssertions = ($history | Measure-Object -Property TotalAssertions -Sum).Sum
				$totalPassed = ($history | Measure-Object -Property PassedAssertions -Sum).Sum
				$totalFailed = ($history | Measure-Object -Property FailedAssertions -Sum).Sum
				$totalScriptErrors = ($history | Measure-Object -Property ScriptErrors -Sum).Sum
				$avgSuccessRate = ($history | Measure-Object -Property SuccessRate -Average).Average
				$avgRunMinutes = ($history | Measure-Object -Property RunMinutes -Average).Average
				$totalRunMinutes = ($history | Measure-Object -Property RunMinutes -Sum).Sum
				
				Write-Host "`nSummary (Last $Days days):" -ForegroundColor Cyan
				Write-Host "  Total Requests: $totalRequests"
				Write-Host "  Total Assertions: $totalAssertions"
				Write-Host "  Passed: $totalPassed"
				Write-Host "  Failed: $totalFailed"
				Write-Host "  Script Errors: $totalScriptErrors"
				Write-Host "  Average Success Rate: $([math]::Round($avgSuccessRate, 2))%"
				Write-Host "  Average Run Time: $([math]::Round($avgRunMinutes, 2)) minutes"
				Write-Host "  Total Run Time: $([math]::Round($totalRunMinutes, 2)) minutes"
				Write-Host "`n"
			}
		}
	}
	
	# Return the data object for further processing if needed
	# return $history
}

