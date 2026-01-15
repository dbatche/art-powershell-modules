function Post-restrictedBillTypes {
    <#
    .SYNOPSIS
    Posts bill type restrictions to an existing accessorial charge code.

    .DESCRIPTION
    Creates new bill type restrictions for a specific charge code through the REST API.
    These restrictions control which bill types the charge code can be used with.
    Requires a valid authentication token (set via Set-artToken) before use.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The ID of the parent charge code to add bill type restrictions to.

    .PARAMETER bodyJson
    The JSON payload containing the bill type restriction data.
    Must conform to the restrictedBillTypes schema.

    .PARAMETER lastItemOnly
    Switch parameter. When specified, returns only the last created restriction ID.
    When not specified, returns the complete response array.

    .EXAMPLE
    $json = '{"restrictedBillTypes":[{"billTypeId":"FRT","isRestricted":true}]}'
    Post-restrictedBillTypes -aChargeCodeId "FUEL" -bodyJson $json
    # Adds bill type restriction to FUEL charge code

    .EXAMPLE
    $json = '{"restrictedBillTypes":[{"billTypeId":"FRT"},{"billTypeId":"INV"}]}'
    Post-restrictedBillTypes -aChargeCodeId "TOLL" -bodyJson $json -lastItemOnly
    # Adds multiple restrictions and returns only the last ID

    .NOTES
    Requires valid authentication token in $headers global variable
    Endpoint: /masterData/aChargeCodes/{aChargeCodeId}/restrictedBillTypes
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId,
        [Parameter(Mandatory=$true)]
        $bodyJson,
        [switch]$lastItemOnly
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/restrictedBillTypes"
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Post' -Uri $uri -Body $bodyJson 

    if ($lastItemOnly) {
        # return the last restriction ID
        $response.restrictedBillTypes[-1].restrictionId
    }
    else {
        # return all restrictions
        $response.restrictedBillTypes
    }
}