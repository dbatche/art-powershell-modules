function Put-aChargeCodeId {
    <#
    .SYNOPSIS
    Updates an existing accessorial charge code via the TruckMate MasterData API.

    .DESCRIPTION
    Modifies properties of an existing charge code through the REST API.
    Use this to update description, GL account, or other attributes of a charge code.
    Requires a valid authentication token (set via Set-artToken) before use.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The ID of the charge code to update.

    .PARAMETER bodyJson
    The JSON payload containing the updated charge code data.
    Must conform to the aChargeCode schema.

    .EXAMPLE
    $json = '{"shortDescription":"Updated Fuel Surcharge","truckmateGlAccount":"00-4020"}'
    Put-aChargeCodeId -aChargeCodeId "FUEL" -bodyJson $json
    # Updates the FUEL charge code properties

    .NOTES
    Requires valid authentication token in $headers global variable
    Endpoint: /masterData/aChargeCodes/{aChargeCodeId}
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId,
        [Parameter(Mandatory=$true)]
        $bodyJson
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId"
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Put' -Uri $uri -Body $bodyJson
    $response.aChargeCode
}