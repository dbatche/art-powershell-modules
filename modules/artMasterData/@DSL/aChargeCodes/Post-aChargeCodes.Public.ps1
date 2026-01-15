function Post-aChargeCodes {
    <#
    .SYNOPSIS
    Posts accessorial charge code data to the TruckMate MasterData API.

    .DESCRIPTION
    Creates new charge code entries in the TruckMate system through the REST API.
    Requires a valid authentication token (set via Set-artToken) before use.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER bodyJson
    The JSON payload containing the charge code data to post.
    Must conform to the aChargeCode schema.

    .PARAMETER lastItemOnly
    Switch parameter. When specified, returns only the aChargeCodeId of the last created item.
    When not specified, returns the complete response array with all created charge codes.

    .EXAMPLE
    $json = '{"aChargeCodes":[{"aCodeId":"FUEL","shortDescription":"Fuel Surcharge","truckmateGlAccount":"00-4010"}]}'
    Post-aChargeCodes -bodyJson $json
    # Creates a new charge code and returns full response

    .EXAMPLE
    Post-aChargeCodes -bodyJson $json -lastItemOnly
    # Creates charge code(s) and returns only the last created ID

    .NOTES
    Requires valid authentication token in $headers global variable
    Endpoint: /masterData/aChargeCodes
    #>

    param(
        $server = "http://localhost:9950",
        $bodyJson,
        [switch]$lastItemOnly
    )

    # $headers from global variable - see Set-artToken
    # $endpoint is assumed
    $endpoint = "/masterData/aChargeCodes"

    $uri = $server + $endpoint

    # $body assumed valid json, passed as is
    
    $response= Invoke-RestMethod -Headers $headers  -Method 'Post' -uri $uri  -Body $bodyJson 

    if ($lastItemOnly) {
        # return the code of the last item in the array (useful for subsequent commands)
        $response.aChargeCodes[-1].aChargeCodeId
    }
    else {
        # return entire array of codes and properties
        $response.aChargeCodes
    }

}