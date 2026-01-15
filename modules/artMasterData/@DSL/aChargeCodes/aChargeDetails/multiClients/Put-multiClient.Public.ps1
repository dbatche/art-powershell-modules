function Put-multiClient {
    <#
    .SYNOPSIS
    Updates an existing multi-client assignment.

    .DESCRIPTION
    Modifies properties of an existing client assignment through the REST API.
    Used to update client-specific rates or other properties.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The ID of the parent charge code.

    .PARAMETER detailId
    The ID of the parent detail record.

    .PARAMETER clientAssignmentId
    The ID of the client assignment to update.

    .PARAMETER bodyJson
    JSON payload containing updated assignment data.
    Example: '{"clientId":"ACME01","rate":30.00}'

    .EXAMPLE
    $json = '{"clientId":"ACME01","rate":30.00}'
    Put-multiClient -aChargeCodeId "FUEL" -detailId 123 -clientAssignmentId 456 -bodyJson $json
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)][string]$aChargeCodeId,
        [Parameter(Mandatory=$true)][string]$detailId,
        [Parameter(Mandatory=$true)][string]$clientAssignmentId,
        [Parameter(Mandatory=$true)]$bodyJson
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails/$detailId/multiClients/$clientAssignmentId"
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Put' -Uri $uri -Body $bodyJson
    $response.multiClient
}
