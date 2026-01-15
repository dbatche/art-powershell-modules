function Delete-aChargeCodeId {
    <#
    .SYNOPSIS
    Deletes an accessorial charge code from the TruckMate MasterData API.

    .DESCRIPTION
    Removes an existing charge code from the TruckMate system through the REST API.
    Requires a valid authentication token (set via Set-artToken) before use.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The unique identifier of the charge code to delete.

    .EXAMPLE
    Delete-aChargeCodeId -aChargeCodeId "FUEL"
    # Deletes the FUEL charge code

    .EXAMPLE
    Delete-aChargeCodeId -server "http://prod-server:9950" -aChargeCodeId "TOLL"
    # Deletes the TOLL charge code from specified server

    .NOTES
    Requires valid authentication token in $headers global variable
    Endpoint: /masterData/aChargeCodes/{aChargeCodeId}
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId"
    $uri = $server + $endpoint
    
    try {
        $response = Invoke-RestMethod -Headers $headers -Method 'Delete' -Uri $uri
        $response
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
        }
    }
}