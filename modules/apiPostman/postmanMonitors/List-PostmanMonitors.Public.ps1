function List-PostmanMonitors {
	<#
	.SYNOPSIS
	Lists Postman Monitors with basic information 

	.DESCRIPTION
	Can query by owner, active, name

	.EXAMPLE
	List-PostmanMonitors

	Returns list of all monitors showing UID and basic properties

	.EXAMPLE
	List-PostmanMonitors -owner 8229908

	.EXAMPLE
	List-PostmanMonitors -owner 8229908 -activeOnly

	.EXAMPLE
	List-PostmanMonitors -name "^TM |- Contract|Finance"

	#>

	param(

		# monitor owner, e.g. 8229908
		[argumentCompleter({'8229908'})]
		$owner,

		# active only
		[switch]$activeOnly,

		# Get a monitor by text match
		$name

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

		# Postman API call
		$response = Invoke-RestMethod -Uri $url -Headers $postmanHeaders 

		# Add the monitors from the current response to the array
		$allMonitors += $response.monitors

		# Check for the nextCursor in the meta object
		$nextCursor = $response.meta.nextCursor
		
		# If nextCursor exists, update the URL for the next request
		if (![string]::IsNullOrWhiteSpace($nextCursor)) {
			$url = $baseUrl + "&cursor=$nextCursor"
		}

		write-verbose ($allMonitors | Measure-Object ).count

	} while (![string]::IsNullOrWhiteSpace($nextCursor))


	if ($name) {
		# Additional filtering by name
		$output = $allMonitors | Where-Object name -match $name
	}
	else {
		$output = $allMonitors
	}

	Write-information "Monitor List Matching Criteria:"
	$output

}