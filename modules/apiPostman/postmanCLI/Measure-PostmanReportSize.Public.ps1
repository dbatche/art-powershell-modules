function Measure-PostmanReportSize {
	<#
	.SYNOPSIS
	Analyzes size contributions of different components in a Postman native format report
	
	.DESCRIPTION
	Samples executions from a Postman report file and estimates how much space is consumed by
	headers, request bodies, response bodies, and other metadata.
	
	.PARAMETER Path
	Path to the Postman native format JSON report file
	
	.PARAMETER SampleSize
	Number of executions to sample for size estimation (default: 50)
	
	.EXAMPLE
	Measure-PostmanReportSize -Path "Finance-Functional-Tests-2025-10-02.json"
	
	Analyzes the file and shows size breakdown
	
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path,
		
		[int]$SampleSize = 50
	)
	
	if (-not (Test-Path $Path)) {
		Write-Error "File not found: $Path"
		return
	}
	
	$file = Get-Item $Path
	$totalFileSizeMB = [math]::Round($file.Length / 1MB, 2)
	
	Write-Host "`nAnalyzing: $($file.Name)" -ForegroundColor Cyan
	Write-Host "Total File Size: $totalFileSizeMB MB" -ForegroundColor Cyan
	Write-Host "`nReading JSON file (this may take a moment)..." -ForegroundColor Yellow
	
	try {
		$content = Get-Content $Path -Raw | ConvertFrom-Json
		$runData = $content.run
		
		# Get total execution count
		$totalExecutions = $runData.executions.Count
		Write-Host "Total Executions: $totalExecutions" -ForegroundColor Green
		
		# Sample executions for analysis
		$sampleCount = [Math]::Min($SampleSize, $totalExecutions)
		Write-Host "Sampling $sampleCount executions for analysis..." -ForegroundColor Yellow
		
		# Take evenly distributed samples
		$step = [Math]::Max(1, [Math]::Floor($totalExecutions / $sampleCount))
		$samples = @()
		for ($i = 0; $i -lt $totalExecutions; $i += $step) {
			if ($samples.Count -ge $sampleCount) { break }
			$samples += $runData.executions[$i]
		}
		
		# Analyze each component
		$totalSampleSize = 0
		$responseBodySize = 0
		$requestHeaderSize = 0
		$responseHeaderSize = 0
		$metadataSize = 0
		
		foreach ($exec in $samples) {
			# Measure response body (stream.data array)
			if ($exec.response.stream.data) {
				$streamJson = $exec.response.stream | ConvertTo-Json -Compress -Depth 10
				$responseBodySize += $streamJson.Length
			}
			
			# Measure request headers
			if ($exec.requestExecuted.headers) {
				$reqHeaderJson = $exec.requestExecuted.headers | ConvertTo-Json -Compress -Depth 10
				$requestHeaderSize += $reqHeaderJson.Length
			}
			
			# Measure response headers
			if ($exec.response.headers) {
				$respHeaderJson = $exec.response.headers | ConvertTo-Json -Compress -Depth 10
				$responseHeaderSize += $respHeaderJson.Length
			}
			
			# Measure total execution size
			$execJson = $exec | ConvertTo-Json -Compress -Depth 10
			$totalSampleSize += $execJson.Length
		}
		
		# Calculate metadata size (everything else)
		$metadataSize = $totalSampleSize - $responseBodySize - $requestHeaderSize - $responseHeaderSize
		
		# Calculate averages per execution
		$avgResponseBody = $responseBodySize / $samples.Count
		$avgRequestHeader = $requestHeaderSize / $samples.Count
		$avgResponseHeader = $responseHeaderSize / $samples.Count
		$avgMetadata = $metadataSize / $samples.Count
		$avgTotal = $totalSampleSize / $samples.Count
		
		# Extrapolate to full file
		$estimatedResponseBodyMB = [math]::Round(($avgResponseBody * $totalExecutions) / 1MB, 2)
		$estimatedRequestHeaderMB = [math]::Round(($avgRequestHeader * $totalExecutions) / 1MB, 2)
		$estimatedResponseHeaderMB = [math]::Round(($avgResponseHeader * $totalExecutions) / 1MB, 2)
		$estimatedMetadataMB = [math]::Round(($avgMetadata * $totalExecutions) / 1MB, 2)
		$estimatedExecutionsTotalMB = [math]::Round(($avgTotal * $totalExecutions) / 1MB, 2)
		
		# Meta/summary overhead
		$metaSummaryJson = @{
			meta = $runData.meta
			summary = $runData.summary
		} | ConvertTo-Json -Compress -Depth 10
		$metaSummaryMB = [math]::Round($metaSummaryJson.Length / 1MB, 4)
		
		# Calculate percentages
		$responseBodyPct = [math]::Round(($estimatedResponseBodyMB / $totalFileSizeMB) * 100, 1)
		$requestHeaderPct = [math]::Round(($estimatedRequestHeaderMB / $totalFileSizeMB) * 100, 1)
		$responseHeaderPct = [math]::Round(($estimatedResponseHeaderMB / $totalFileSizeMB) * 100, 1)
		$metadataPct = [math]::Round(($estimatedMetadataMB / $totalFileSizeMB) * 100, 1)
		
		# Display results
		Write-Host "`n" + ("=" * 80) -ForegroundColor Green
		Write-Host "SIZE BREAKDOWN (Estimated based on $sampleCount samples)" -ForegroundColor Green
		Write-Host ("=" * 80) -ForegroundColor Green
		
		$results = @(
			[PSCustomObject]@{
				Component = "Response Bodies (stream.data)"
				SizeMB = $estimatedResponseBodyMB
				Percentage = "$responseBodyPct%"
				AvgPerExecution = "$([math]::Round($avgResponseBody / 1KB, 2)) KB"
			}
			[PSCustomObject]@{
				Component = "Response Headers"
				SizeMB = $estimatedResponseHeaderMB
				Percentage = "$responseHeaderPct%"
				AvgPerExecution = "$([math]::Round($avgResponseHeader, 0)) bytes"
			}
			[PSCustomObject]@{
				Component = "Request Headers"
				SizeMB = $estimatedRequestHeaderMB
				Percentage = "$requestHeaderPct%"
				AvgPerExecution = "$([math]::Round($avgRequestHeader, 0)) bytes"
			}
			[PSCustomObject]@{
				Component = "Other Metadata"
				SizeMB = $estimatedMetadataMB
				Percentage = "$metadataPct%"
				AvgPerExecution = "$([math]::Round($avgMetadata, 0)) bytes"
			}
			[PSCustomObject]@{
				Component = "Meta/Summary (overhead)"
				SizeMB = $metaSummaryMB
				Percentage = "$([math]::Round(($metaSummaryMB / $totalFileSizeMB) * 100, 1))%"
				AvgPerExecution = "N/A"
			}
		)
		
		$results | Format-Table -AutoSize
		
		Write-Host "`nEstimated Total (executions): $estimatedExecutionsTotalMB MB" -ForegroundColor Cyan
		Write-Host "Actual File Size: $totalFileSizeMB MB" -ForegroundColor Cyan
		$difference = $totalFileSizeMB - $estimatedExecutionsTotalMB - $metaSummaryMB
		Write-Host "Difference (JSON formatting overhead): $([math]::Round($difference, 2)) MB" -ForegroundColor Yellow
		
		Write-Host "`n" + ("=" * 80) -ForegroundColor Green
		Write-Host "RECOMMENDATIONS" -ForegroundColor Green
		Write-Host ("=" * 80) -ForegroundColor Green
		
		if ($responseBodyPct -gt 50) {
			Write-Host "• Response bodies consume $responseBodyPct% of the file" -ForegroundColor Yellow
			Write-Host "  Consider omitting response bodies if you don't need them for analysis" -ForegroundColor Gray
		}
		
		if ($requestHeaderPct + $responseHeaderPct -gt 20) {
			$headerTotal = $requestHeaderPct + $responseHeaderPct
			Write-Host "• Headers consume $headerTotal% of the file" -ForegroundColor Yellow
			Write-Host "  Consider omitting headers if you only need test results" -ForegroundColor Gray
		}
		
		# Return summary object
		[PSCustomObject]@{
			FileName = $file.Name
			TotalSizeMB = $totalFileSizeMB
			TotalExecutions = $totalExecutions
			ResponseBodiesMB = $estimatedResponseBodyMB
			ResponseBodiesPct = $responseBodyPct
			ResponseHeadersMB = $estimatedResponseHeaderMB
			ResponseHeadersPct = $responseHeaderPct
			RequestHeadersMB = $estimatedRequestHeaderMB
			RequestHeadersPct = $requestHeaderPct
			MetadataMB = $estimatedMetadataMB
			MetadataPct = $metadataPct
		}
	}
	catch {
		Write-Error "Failed to analyze file: $_"
	}
}

