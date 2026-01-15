function Get-artClient {

	param (
		[Parameter(Mandatory = $true)]
		[string]$clientId,

		[argumentCompleter({'shippingInstructions'})]
		$childResource = $null,

		$childResourceId
	)

	$url = $global:apibaseUrl + "/clients"

	if ($clientId) {
		$url += "/$clientId"
	}

	if ($childResource) {
		$url += "/$childResource"
	}

	if ($childResourceId) {
		$url += "/$childResourceId"
	}

	Invoke-RestMethod -Uri $url -Method Get -Headers $global:Headers -ContentType "application/json" 

	
}