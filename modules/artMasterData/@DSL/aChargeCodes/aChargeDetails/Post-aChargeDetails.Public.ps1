function Post-aChargeDetails {
    <#
    .SYNOPSIS
    Posts charge detail records to an existing accessorial charge code.

    .DESCRIPTION
    Creates new charge detail entries for a specific charge code through the REST API.
    These details typically include rate information and conditions.
    Requires a valid authentication token (set via Set-artToken) before use.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The ID of the parent charge code to add details to.

    .PARAMETER bodyJson
    The JSON payload containing the charge detail data to post.
    Must conform to the aChargeDetail schema.

    .PARAMETER lastItemOnly
    Switch parameter. When specified, returns only the detailId of the last created item.
    When not specified, returns the complete response array with all created details.

    .EXAMPLE
    $json = '{"aChargeDetails":[{"rate":25.00,"rateType":"FLAT","effectiveDate":"2024-01-01"}]}'
    Post-aChargeDetails -aChargeCodeId "FUEL" -bodyJson $json
    # Creates new detail records for FUEL charge code

    .EXAMPLE
    Post-aChargeDetails -aChargeCodeId "TOLL" -bodyJson $json -lastItemOnly
    # Creates detail(s) and returns only the last created detail ID

    .NOTES
    Requires valid authentication token in $headers global variable
    Endpoint: /masterData/aChargeCodes/{aChargeCodeId}/aChargeDetails
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId,
        [Parameter(Mandatory=$true)]
        $bodyJson,
        [switch]$lastItemOnly
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails"
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Post' -Uri $uri -Body $bodyJson 

    if ($lastItemOnly) {
        # return the ID of the last created detail
        $response.aChargeDetails[-1].detailId
    }
    else {
        # return all created details
        $response.aChargeDetails
    }
}