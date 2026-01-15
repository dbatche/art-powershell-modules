function Export-PostmanMonitorSnapshot {
	<#
	.SYNOPSIS
	Exports a daily snapshot of Postman monitor reports to JSON file
	
	.DESCRIPTION
	Retrieves all active monitors for a specified owner, gets their detailed reports,
	and saves them to a dated JSON file for historical tracking and analysis.
	
	.PARAMETER Owner
	The Postman owner ID (e.g., 8229908)
	
	.PARAMETER Name
	Filter monitors by name using regex pattern (e.g., "Finance", "^TM - Contract")
	
	.PARAMETER Path
	Directory to save the snapshot files
	Default: C:\PostmanReports\MonitorHistory
	
	.PARAMETER Date
	Date to use for the filename (defaults to today)
	Format: yyyy-MM-dd
	
	.PARAMETER ActiveOnly
	Only include active monitors (default: true)
	
	.PARAMETER Overwrite
	Overwrite existing file if it exists (default: false)
	
	.EXAMPLE
	Export-PostmanMonitorSnapshot -Owner 8229908
	
	Exports all active monitors for owner 8229908 to today's dated file
	
	.EXAMPLE
	Export-PostmanMonitorSnapshot -Owner 8229908 -Name "Finance"
	
	Exports only monitors matching "Finance" in the name
	
	.EXAMPLE
	Export-PostmanMonitorSnapshot -Owner 8229908 -Date "2025-09-15"
	
	Exports monitors with a specific date in the filename
	
	.EXAMPLE
	Export-PostmanMonitorSnapshot -Owner 8229908 -Path "D:\Backups\Monitors"
	
	Exports to a custom directory
	
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[ArgumentCompleter({'8229908'})]
		[string]$Owner,
		
		[string]$Name,
		
		[string]$Path = "C:\PostmanReports\MonitorHistory",
		
		[string]$Date,
		
		[bool]$ActiveOnly = $true,
		
		[switch]$Overwrite
	)
	
	# Use provided date or default to today
	if ([string]::IsNullOrWhiteSpace($Date)) {
		$Date = Get-Date -Format yyyy-MM-dd
	}
	else {
		# Validate date format
		try {
			$parsedDate = [DateTime]::ParseExact($Date, 'yyyy-MM-dd', $null)
			$Date = $parsedDate.ToString('yyyy-MM-dd')
		}
		catch {
			Write-Error "Invalid date format. Please use yyyy-MM-dd format."
			return
		}
	}
	
	# Ensure output directory exists
	if (-not (Test-Path $Path)) {
		Write-Verbose "Creating directory: $Path"
		New-Item -Path $Path -ItemType Directory -Force | Out-Null
	}
	
	# Build output file path
	$outputFile = Join-Path $Path "Monitors_$Date.json"
	
	# Check if file exists
	if ((Test-Path $outputFile) -and -not $Overwrite) {
		Write-Warning "File already exists: $outputFile"
		Write-Warning "Use -Overwrite to replace it"
		return
	}
	
	$filterDesc = "owner $Owner"
	if ($Name) { $filterDesc += " matching '$Name'" }
	Write-Host "Retrieving monitors for $filterDesc..." -ForegroundColor Cyan
	
	# Get list of monitors
	$listParams = @{
		Owner = $Owner
	}
	if ($ActiveOnly) {
		$listParams.ActiveOnly = $true
	}
	if (-not [string]::IsNullOrWhiteSpace($Name)) {
		$listParams.Name = $Name
	}
	
	$monitors = List-PostmanMonitors @listParams
	
	if (-not $monitors -or $monitors.Count -eq 0) {
		$filterMsg = "owner $Owner"
		if ($Name) { $filterMsg += " matching '$Name'" }
		Write-Warning "No monitors found for $filterMsg"
		return
	}
	
	Write-Host "Found $($monitors.Count) monitor(s). Retrieving detailed reports..." -ForegroundColor Cyan
	
	# Get detailed report for each monitor
	$reports = @()
	$counter = 0
	foreach ($monitor in $monitors) {
		$counter++
		Write-Progress -Activity "Retrieving Monitor Reports" `
			-Status "Processing $($monitor.name) ($counter of $($monitors.Count))" `
			-PercentComplete (($counter / $monitors.Count) * 100)
		
		try {
			$report = Get-PostmanMonitor -uid $monitor.uid -report
			if ($report) {
				$reports += $report
			}
		}
		catch {
			Write-Warning "Failed to get report for monitor $($monitor.name): $_"
		}
	}
	
	Write-Progress -Activity "Retrieving Monitor Reports" -Completed
	
	if ($reports.Count -eq 0) {
		Write-Warning "No reports retrieved"
		return
	}
	
	Write-Host "Exporting $($reports.Count) report(s) to $outputFile..." -ForegroundColor Cyan
	
	# Convert to JSON and save
	try {
		$reports | ConvertTo-Json -Compress | Out-File $outputFile -Encoding utf8
		
		$fileInfo = Get-Item $outputFile
		Write-Host "Successfully exported to: $outputFile" -ForegroundColor Green
		Write-Host "File size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Green
		
		# Return summary object
		[PSCustomObject]@{
			OutputFile = $outputFile
			Date = $Date
			MonitorCount = $reports.Count
			FileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
			Owner = $Owner
		}
	}
	catch {
		Write-Error "Failed to export file: $_"
	}
}

