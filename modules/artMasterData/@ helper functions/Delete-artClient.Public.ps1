function Delete-artClient{

	param (
		[Parameter(Mandatory = $true)]
		[string]$clientId
	)

	$url = $global:apibaseUrl + "/clients/$clientId"

	Invoke-RestMethod -Uri $url -Method Delete -Headers $global:Headers -ContentType "application/json"

	
}