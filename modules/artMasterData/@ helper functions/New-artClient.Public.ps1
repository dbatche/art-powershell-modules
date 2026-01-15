function New-artClient {

	param (
		[Parameter(Mandatory = $true)]
		[string]$clientId
	)

	$url = $global:apibaseUrl + "/clients"


	# JSON is a bit tricky in PowerShell, so we prefer to create a hashtable and convert it to JSON
	$body = @{
		"clients" = @(
			@{
				"clientId" = $clientId
			})
	}
	
	$bodyJson = $body | ConvertTo-Json 
	
	# 	$bodyJson = @"
	# 	{
	#     "clients":	[{
	# 		"clientId": "$clientId"
	# }]}
	# "@
	# $bodyJson 

	Invoke-RestMethod -Uri $url -Method Post -Headers $global:Headers -ContentType "application/json" -Body $bodyJson

	
}