function Get-aChargeDetails {
    <#
    .SYNOPSIS
    Retrieves charge details for an accessorial charge code.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The parent charge code ID.

    .PARAMETER detailId
    Optional. Specific detail ID to retrieve. If omitted, returns all details.

    .EXAMPLE
    Get-aChargeDetails -aChargeCodeId "FUEL"
    # Returns all details for FUEL charge code

    .EXAMPLE
    Get-aChargeDetails -aChargeCodeId "FUEL" -detailId 123
    # Returns specific detail record
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId,
        [string]$detailId
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails"
    if ($detailId) { $endpoint += "/$detailId" }
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Get' -Uri $uri
    if ($detailId) { $response.aChargeDetail } else { $response.aChargeDetails }
}
