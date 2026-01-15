function Delete-multiClient {
    <#
    .SYNOPSIS
    Deletes a specific multi-client assignment.

    .DESCRIPTION
    Removes a client-specific rate assignment from a charge detail record.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The ID of the parent charge code.

    .PARAMETER detailId
    The ID of the parent detail record.

    .PARAMETER clientAssignmentId
    The ID of the client assignment to delete.

    .EXAMPLE
    Delete-multiClient -aChargeCodeId "FUEL" -detailId 123 -clientAssignmentId 456
    # Removes the specified client assignment

    .NOTES
    Will fail if the client assignment is in use
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)][string]$aChargeCodeId,
        [Parameter(Mandatory=$true)][string]$detailId,
        [Parameter(Mandatory=$true)][string]$clientAssignmentId
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails/$detailId/multiClients/$clientAssignmentId"
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
