function Get-aChargeCodes {
    <#
    .SYNOPSIS
    Retrieves accessorial charge codes from the TruckMate MasterData API.

    .DESCRIPTION
    Gets charge code data from TruckMate system through the REST API.
    Can retrieve either all charge codes or a specific one by ID.
    Requires a valid authentication token (set via Set-artToken) before use.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    Optional. The specific charge code ID to retrieve.
    If omitted, returns all charge codes.

    .PARAMETER filter
    Optional. Query string to filter results (if supported by API).
    Example: "shortDescription eq 'Fuel*'"

    .EXAMPLE
    Get-aChargeCodes
    # Returns all charge codes

    .EXAMPLE
    Get-aChargeCodes -aChargeCodeId "FUEL"
    # Returns only the FUEL charge code

    .EXAMPLE
    Get-aChargeCodes -filter "isActive eq true"
    # Returns active charge codes (if filtering supported)

    .NOTES
    Requires valid authentication token in $headers global variable
    Endpoint: /masterData/aChargeCodes
    #>

    param(
        $server = "http://localhost:9950",
        [string]$aChargeCodeId,
        [string]$filter
    )

    $endpoint = "/masterData/aChargeCodes"
    
    # Build URI based on parameters
    if ($aChargeCodeId) {
        $uri = "$server$endpoint/$aChargeCodeId"
    }
    elseif ($filter) {
        $uri = "$server$endpoint`?`$filter=$filter"
    }
    else {
        $uri = "$server$endpoint"
    }

    $response = Invoke-RestMethod -Headers $headers -Method 'Get' -Uri $uri

    # Return single object or array based on what was requested
    if ($aChargeCodeId) {
        $response.aChargeCode
    }
    else {
        $response.aChargeCodes
    }
}
