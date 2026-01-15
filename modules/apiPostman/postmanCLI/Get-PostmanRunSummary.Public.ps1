function Get-PostmanRunSummary {
	<#
	.SYNOPSIS
	Extracts summary metadata from Postman Native format JSON report files
	
	.DESCRIPTION
	Reads large Postman CLI JSON output files (native format) and extracts just the meta and summary sections,
	which contain the high-level execution statistics without the detailed execution data.
	Also extracts the application version from the /version endpoint response.
	
	.PARAMETER Path
	Path to the Postman native format JSON report file
	
	.PARAMETER Format
	Output format: Object (default), Table, or Json
	
	.EXAMPLE
	Get-PostmanRunSummary -Path "Finance-Functional-Tests-2025-10-02.json"
	
	Returns the summary as a PowerShell object
	
	.EXAMPLE
	Get-PostmanRunSummary -Path "Finance-*.json" -Format Table
	
	Shows summaries for multiple files in table format
	
	.EXAMPLE
	$summary = Get-PostmanRunSummary -Path "report.json"
	$summary.TestsExecuted
	
	Access specific metrics from the summary
	
	#>
	
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string]$Path,
		
		[ValidateSet('Object', 'Table', 'Json')]
		[string]$Format = 'Object'
	)
	
	begin {
		$summaries = @()
	}
	
	process {
		# Support wildcards
		$files = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
		
		if (-not $files) {
			Write-Error "No files found matching: $Path"
			return
		}
		
		foreach ($file in $files) {
			Write-Verbose "Processing: $($file.Name)"
			
			try {
				# Read and parse JSON (this will take a moment for large files)
				Write-Host "Reading $($file.Name)..." -ForegroundColor Cyan
				$content = Get-Content $file.FullName -Raw | ConvertFrom-Json
				
				# Extract just the meta and summary
				$runData = $content.run
				
				# Extract version from the /version endpoint response
				$version = $null
				$debugMode = $null
				try {
					$versionExec = $runData.executions | Where-Object { $_.requestExecuted.name -eq 'version' } | Select-Object -First 1
					if ($versionExec -and $versionExec.response.stream.data) {
						$bytes = [byte[]]$versionExec.response.stream.data
						$versionText = [System.Text.Encoding]::UTF8.GetString($bytes)
						$versionObj = $versionText | ConvertFrom-Json
						$version = $versionObj.version
						$debugMode = $versionObj.debug
					}
				}
				catch {
					Write-Verbose "Could not extract version from response: $_"
				}
				
				# Create a clean summary object
				$summary = [PSCustomObject]@{
					FileName = $file.Name
					CollectionId = $runData.meta.collectionId
					CollectionName = $runData.meta.collectionName
					Version = $version
					DebugMode = $debugMode
					StartTime = [DateTimeOffset]::FromUnixTimeMilliseconds($runData.meta.started).LocalDateTime
					CompletedTime = [DateTimeOffset]::FromUnixTimeMilliseconds($runData.meta.completed).LocalDateTime
					DurationSeconds = [math]::Round($runData.meta.duration / 1000, 2)
					Iterations = $runData.summary.iterations.executed
					IterationErrors = $runData.summary.iterations.errors
					RequestsExecuted = $runData.summary.executedRequests.executed
					RequestErrors = $runData.summary.executedRequests.errors
					PreRequestScripts = $runData.summary.prerequestScripts.executed
					PreRequestErrors = $runData.summary.prerequestScripts.errors
					PostResponseScripts = $runData.summary.postresponseScripts.executed
					PostResponseErrors = $runData.summary.postresponseScripts.errors
					TestsExecuted = $runData.summary.tests.executed
					TestsPassed = $runData.summary.tests.passed
					TestsFailed = $runData.summary.tests.failed
					TestsSkipped = $runData.summary.tests.skipped
					TestPassRate = if ($runData.summary.tests.executed -gt 0) {
						[math]::Round(($runData.summary.tests.passed / $runData.summary.tests.executed) * 100, 2)
					} else { 0 }
					AvgResponseTime = [math]::Round($runData.summary.timeStats.responseAverage, 2)
					MinResponseTime = $runData.summary.timeStats.responseMin
					MaxResponseTime = $runData.summary.timeStats.responseMax
					ResponseStdDev = [math]::Round($runData.summary.timeStats.responseStandardDeviation, 2)
				}
				
				$summaries += $summary
			}
			catch {
				Write-Error "Failed to process $($file.Name): $_"
			}
		}
	}
	
	end {
		if ($summaries.Count -eq 0) {
			return
		}
		
		# Output based on format
		switch ($Format) {
			'Json' {
				$summaries | ConvertTo-Json -Depth 5
			}
			'Table' {
				$summaries | Format-Table -Property FileName, CollectionName, Version, StartTime, RequestsExecuted, TestsExecuted, TestsPassed, TestsFailed, TestPassRate, DurationSeconds -AutoSize
			}
			default {
				$summaries
			}
		}
	}
}

