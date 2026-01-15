function Get-PostmanMonitor {
	<#
	.SYNOPSIS
	Gets information about Postman monitors or gets detailed information about a particular monitor

	.DESCRIPTION

	.EXAMPLE
	Get-PostmanMonitor

	Returns list of all monitors showing UID and basic properties, allows name filtering by name

	.EXAMPLE
	Get-PostmanMonitor -monitorUid "1f00a95e-d6e9-4ea0-85f7-6209a1271d8b""

	Returns detailed information about a particular monitor, including 'lastrun' stats

	.EXAMPLE

	:>$mons.monitors | where name -match "- contract" | % {Get-PostmanMonitor -uid $_.uid -lastRun } | % {$_.stats} | ft -p assertions, requests -AutoSize

	assertions                requests
	----------                --------
	@{total=41; failed=8}     @{total=113}
	@{total=611; failed=174}  @{total=666}
	@{total=1589; failed=114} @{total=1649}
	@{total=1232; failed=122} @{total=1295}

	#>

	param(

		# Get a specific Monitor by UID
		$uid,

		# Get a monitor by text match
		$name,

		# monitor owner, e.g. 8229908
		[argumentCompleter({'8229908'})]
		$owner,

		# active only
		[switch]$activeOnly,

		# Show Lastrun stats
		[switch]$report
	)

	# Use environment variable (run Setup-EnvironmentVariables first)
	$postmanApiKey = $env:POSTMAN_API_KEY
	if (-not $postmanApiKey) {
		Write-Error "POSTMAN_API_KEY environment variable not set. Run Setup-EnvironmentVariables first."
		return
	}
	$postmanHeaders = @{"X-Api-Key"= $postmanApiKey}

	# Base URL for Postman Monitors
	$baseUrl = "https://api.getpostman.com/monitors"
	#alternative? $baseUrl = "https://monitoring-api.postman.tech/monitors?limit=25"
	
	# Monitor UID examples
	# $OrdersUid= "1f00a95e-d6e9-4ea0-85f7-6209a1271d8b"
	# $FinanceUid = "1ef5754b-9daa-4c40-9360-7d8c7916f3c8"

	# if ($uid) {
	# 	$url += "/" + $uid
	# }
	




	# $monitors = Invoke-RestMethod -uri $url -Headers $postmanHeaders
	

	if ($uid) {

		$url += $baseUrl + "/" + $uid

		$response = Invoke-RestMethod -Uri $url -Headers $postmanHeaders 

		# singular
		$output = $response.monitor

		if ($report) {
			$reportOutput = [PSCustomObject]@{
				name = $output.name
				status = $output.lastRun.status
				requests = $output.lastRun.stats.requests.total
				assertions = $output.lastRun.stats.assertions.total 
				failed = $output.lastRun.stats.assertions.failed
				failPercentage = [Math]::Round(100*($output.lastRun.stats.assertions.failed / $output.lastRun.stats.assertions.total),2)
				scriptErrors = $output.lastRun.stats.errorCount
				runMinutes = ($output.lastRun.stats.responseLatency)/(1000*60)
				startedAt = $output.lastRun.startedAt
				finishedAt = $output.lastRun.finishedAt
				uid = $output.uid
			}

			$output = $reportOutput
		}

	}
	else {

		# plural
		#$output = $monitors.monitors

		$allMonitors = @()
		$baseUrl += "?limit=25"

		if ($owner) {
			$baseUrl += "&owner=$owner"
		}

		if ($activeOnly) {
			$baseUrl += "&active=true"
		}

		$url = $baseUrl

		do {
			

			Write-verbose $url

			$response = Invoke-RestMethod -Uri $url -Headers $postmanHeaders 


			# Add the monitors from the current response to the array
			$allMonitors += $response.monitors

			# Check for the nextCursor in the meta object
			$nextCursor = $response.meta.nextCursor
			
			# If nextCursor exists, update the URL for the next request
			if (![string]::IsNullOrWhiteSpace($nextCursor)) {
				$url = $baseUrl + "&cursor=$nextCursor"
			}

			write-verbose ($allMonitors | measure ).count

		} while (![string]::IsNullOrWhiteSpace($nextCursor))

		if ($name) {
			$output = $allMonitors | where name -match $name
		}
		else {
			$output = $allMonitors
		}
	}

	Write-verbose "Output Monitors/Monitor"
	$output

}