function Get-multiClients {
    <#
    .SYNOPSIS
    Retrieves multi-client assignments for a charge detail.

    .DESCRIPTION
    Gets client-specific rates and assignments for a charge detail record.
    Supports retrieving either all assignments or a specific one.

    .PARAMETER server 
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The ID of the parent charge code.

    .PARAMETER detailId
    The ID of the parent detail record.

    .PARAMETER clientAssignmentId
    Optional. Specific client assignment ID to retrieve.

    .EXAMPLE
    Get-multiClients -aChargeCodeId "FUEL" -detailId 123
    # Returns all client assignments for the detail

    .EXAMPLE
    Get-multiClients -aChargeCodeId "FUEL" -detailId 123 -clientAssignmentId 456
    # Returns specific client assignment
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory = $true)][string]$aChargeCodeId,
        [Parameter(Mandatory = $true)][string]$detailId,
        [string]$clientAssignmentId
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails/$detailId/multiClients"
    if ($clientAssignmentId) { $endpoint += "/$clientAssignmentId" }
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Get' -Uri $uri
    if ($clientAssignmentId) { $response.multiClient } else { $response.multiClients }
}
