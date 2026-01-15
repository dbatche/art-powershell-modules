function Test-ApptTimestamps {
	<#

	.SYNOPSIS
		Test-ApptTimestamps is a function that tests the ability to update the pickup and delivery appointment timestamps for a specific order.
		
	.DESCRIPTION
		Test-ApptTimestamps is a function that tests the ability to update the pickup and delivery appointment timestamps for a specific order. 
		The function takes in the order ID, the API key, and a parameter set. 
		The parameter set is used to determine which set of timestamps to use. 
		The function then sends a PUT request to the TM API to update the timestamps for the order. 
		The function returns the response from the API.

	.PARAMETER url
		The URL of the TM API endpoint.

	.PARAMETER dlid
		The ID of the order to update.

	.PARAMETER apiKey
		The API key to authenticate the request.

	.PARAMETER paramSet
		The parameter set to use. 
		The function has two sets of timestamps to choose from. 
		The parameter set determines which set of timestamps to use.

	.EXAMPLE
		Test-ApptTimestamps -url "http://localhost:9900/tm/orders/" -dlid 1234 -apiKey "8e8c563a68a03bda2c1fce86ffef1261" -paramSet 1


	.NOTES
		File Name      : Test-ApptTimestamps.Public.ps1
		Author         : Doug Batchelor
		

	#>

	param(
		$url = "http://localhost:9900/tm/orders/",
		$dlid,
		$apiKey = "8e8c563a68a03bda2c1fce86ffef1261",
		$paramSet = 1
	)

	# Define the URL
	$url += $dlid

	# Define method (GET, POST, PUT, DELETE, etc.)
	$method = "PUT"

	# Define the body as a PowerShell object
	$psobj1 = @{
		pickUpApptReq    = "True"
		pickUpApptMade   = "True" 
		pickUpBy         = "2024-05-24T07:00:00"
		pickUpByEnd      = "2024-05-24T18:00:00"
		deliveryApptReq  = "True"
		deliveryApptMade = "True"
		deliverBy        = "2024-05-26T08:00:00"
		deliverByEnd     = "2024-05-26T17:00:00"
	}

	$psobj2 = @{
		pickUpApptReq    = "False"
		pickUpApptMade   = "False" 
		pickUpBy         = "2024-05-23T07:00:00"
		pickUpByEnd      = "2024-05-23T18:00:00"
		deliveryApptReq  = "False"
		deliveryApptMade = "False"
		deliverBy        = "2024-05-25T08:00:00"
		deliverByEnd     = "2024-05-25T17:00:00"
	}


	if ($paramSet -eq 1) {
		$psobj = $psobj1
	}
	else {
		$psobj = $psobj2
	}

	# Convert the body to JSON
	$body = $psobj | ConvertTo-Json

	# Define headers (example: Content-Type and Authorization)
	$header = @{
		"Content-Type"  = "application/json"
		# Add an Authorization header if needed
		"Authorization" = "Bearer $apiKey"
	}

	# Make the web request
	$response = Invoke-WebRequest -Uri $url -Method $method -Headers $header -Body $body

	# Output the response
	Write-Output $response.Content

}