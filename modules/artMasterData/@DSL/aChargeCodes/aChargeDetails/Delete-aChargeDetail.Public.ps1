function Delete-aChargeDetail {
    <#
    .SYNOPSIS
    Deletes a specific charge detail record.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The parent charge code ID.

    .PARAMETER detailId
    The ID of the detail record to delete.

    .EXAMPLE
    Delete-aChargeDetail -aChargeCodeId "FUEL" -detailId 123
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)]
        [string]$aChargeCodeId,
        [Parameter(Mandatory=$true)]
        [string]$detailId
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails/$detailId"
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
