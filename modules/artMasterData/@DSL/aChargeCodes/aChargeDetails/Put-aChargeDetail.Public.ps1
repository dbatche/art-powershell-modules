function Put-aChargeDetail {
    <#
    .SYNOPSIS
    Updates an existing charge detail record.

    .DESCRIPTION
    Updates properties of an existing charge detail through the REST API.
    Requires a valid authentication token.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The parent charge code ID.

    .PARAMETER detailId
    The ID of the detail record to update.

    .PARAMETER bodyJson
    The JSON payload containing the updated detail data.

    .EXAMPLE
    $json = '{"rate":30.00,"rateType":"FLAT","effectiveDate":"2024-02-01"}'
    Put-aChargeDetail -aChargeCodeId "FUEL" -detailId 123 -bodyJson $json
    
    .NOTES
    Requires valid authentication token in $headers global variable
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId,
        [Parameter(Mandatory=$true)]
        [string]$detailId,
        [Parameter(Mandatory=$true)]
        $bodyJson
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails/$detailId"
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Put' -Uri $uri -Body $bodyJson
    $response.aChargeDetail
}
