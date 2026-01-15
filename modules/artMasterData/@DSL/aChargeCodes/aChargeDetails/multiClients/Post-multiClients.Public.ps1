function Post-multiClients {
    <#
    .SYNOPSIS
    Posts multi-client assignments to a charge detail record.

    .PARAMETER server
    The base URL of the API server. Defaults to http://localhost:9950.

    .PARAMETER aChargeCodeId
    The parent charge code ID.

    .PARAMETER detailId
    The parent detail record ID.

    .PARAMETER bodyJson
    JSON payload containing client assignments.
    Example: '{"multiClients":[{"clientId":"ACME01","rate":25.00}]}'

    .PARAMETER lastItemOnly
    When specified, returns only the last created assignment ID.
    #>

    param(
        $server = "http://localhost:9950",
        [Parameter(Mandatory=$true)][string]$aChargeCodeId,
        [Parameter(Mandatory=$true)][string]$detailId,
        [Parameter(Mandatory=$true)]$bodyJson,
        [switch]$lastItemOnly
    )

    $endpoint = "/masterData/aChargeCodes/$aChargeCodeId/aChargeDetails/$detailId/multiClients"
    $uri = $server + $endpoint
    
    $response = Invoke-RestMethod -Headers $headers -Method 'Post' -Uri $uri -Body $bodyJson 

    if ($lastItemOnly) {
        $response.multiClients[-1].clientAssignmentId
    } else {
        $response.multiClients
    }
}
