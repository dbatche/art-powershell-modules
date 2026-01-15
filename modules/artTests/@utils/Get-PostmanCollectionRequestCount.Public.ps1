function Get-PostmanCollectionRequestCount {
    <#
    .SYNOPSIS
    Counts the number of named requests in a Postman collection.

    .DESCRIPTION
    Recursively traverses a Postman collection structure and counts all named requests,
    including those in nested folders. Can fetch collection from Postman API or analyze
    a local collection JSON file.

    .PARAMETER CollectionUid
    The Postman collection UID (e.g., '8229908-779780a9-97d0-4004-9a96-37e8c64c3405').
    Requires ApiKey parameter.

    .PARAMETER CollectionFile
    Path to a local Postman collection JSON file.

    .PARAMETER ApiKey
    Postman API key for fetching collections from the API.
    Can also be set via $env:POSTMAN_API_KEY.

    .PARAMETER IncludeScriptRequests
    If specified, also counts pm.sendRequest() calls in pre-request and test scripts.

    .PARAMETER ByFolder
    If specified, returns a breakdown of request counts by top-level folder.

    .PARAMETER FolderPath
    Specifies a folder path to start counting from (e.g., 'orders' or 'orders/suborders').
    Use forward slashes to separate nested folders. If not specified, starts from collection root.

    .PARAMETER Tag
    Filter requests by tag/pattern using regex (e.g., 'TM-123456' or 'TM-\d+').
    Only counts requests whose names match the pattern.

    .PARAMETER IncludeFolderPaths
    When using -Tag, also match against folder names in the path (not just request names).
    Useful for finding all requests under folders tagged with a Jira ticket.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY

    Returns the total count of named requests in the collection.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionFile 'C:\exports\my-collection.json'

    Counts requests in a local collection file.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY -ByFolder

    Returns request counts broken down by top-level folder.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY -IncludeScriptRequests

    Returns total named requests plus count of pm.sendRequest() calls in scripts.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-048191f7-b6f7-44ad-8d62-4178b8944f08' -ApiKey $env:POSTMAN_API_KEY -FolderPath 'orders' -ByFolder

    Drills into the 'orders' folder and returns a breakdown of its subfolders.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY -Tag 'TM-180264'

    Counts only requests whose names contain 'TM-180264' (known issues).

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY -Tag 'TM-180264' -IncludeFolderPaths

    Counts requests with 'TM-180264' in the request name OR in any parent folder name.

    .EXAMPLE
    Get-PostmanCollectionRequestCount -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY -Tag 'TM-\d+' -ByFolder

    Returns breakdown by folder of requests matching any Jira ticket pattern in request names.

    .OUTPUTS
    Int32 or PSCustomObject depending on parameters
    #>
    [CmdletBinding(DefaultParameterSetName='FromApi')]
    param(
        [Parameter(Mandatory, ParameterSetName='FromApi', Position=0)]
        [string]$CollectionUid,

        [Parameter(Mandatory, ParameterSetName='FromFile', Position=0)]
        [string]$CollectionFile,

        [Parameter(ParameterSetName='FromApi')]
        [string]$ApiKey,

        [Parameter()]
        [switch]$IncludeScriptRequests,

        [Parameter()]
        [switch]$ByFolder,

        [Parameter()]
        [string]$FolderPath,

        [Parameter()]
        [string]$Tag,

        [Parameter()]
        [switch]$IncludeFolderPaths
    )

    # Helper function to find a folder by path
    function Find-Folder {
        param(
            [Parameter(Mandatory)]
            $Items,
            
            [Parameter(Mandatory)]
            [string]$Path
        )
        
        $pathParts = $Path -split '/'
        $currentItems = $Items
        
        foreach ($part in $pathParts) {
            $found = $currentItems | Where-Object { $_.name -eq $part -and $_.item }
            
            if (-not $found) {
                Write-Error "Folder '$part' not found in path '$Path'"
                return $null
            }
            
            $currentItems = $found.item
        }
        
        return $currentItems
    }

    # Helper function to count requests recursively
    function Count-Requests {
        param(
            [Parameter(Mandatory)]
            $Items,
            
            [string]$ParentPath = ""
        )
        
        $count = 0
        $scriptCount = 0
        
        foreach ($item in $Items) {
            $currentPath = if ($ParentPath) { "$ParentPath / $($item.name)" } else { $item.name }
            
            if ($item.request) {
                # Check if tag filter is specified
                $matchesTag = $true
                if ($Tag) {
                    # By default, only match against request name
                    $matchesTag = $item.name -match $Tag
                    
                    # Optionally include folder paths in the search
                    if ($IncludeFolderPaths -and -not $matchesTag) {
                        $matchesTag = $currentPath -match $Tag
                    }
                }
                
                if ($matchesTag) {
                    $count++
                    
                    # Count pm.sendRequest() calls if requested
                    if ($IncludeScriptRequests -and $item.event) {
                        foreach ($event in $item.event) {
                            if ($event.script.exec) {
                                $scriptText = $event.script.exec -join "`n"
                                $scriptCount += ([regex]::Matches($scriptText, "pm\.sendRequest")).Count
                            }
                        }
                    }
                }
            }
            
            # Recurse into subfolders
            if ($item.item) {
                $subResult = Count-Requests -Items $item.item -ParentPath $currentPath
                $count += $subResult.Count
                $scriptCount += $subResult.ScriptCount
            }
        }
        
        return @{
            Count = $count
            ScriptCount = $scriptCount
        }
    }

    # Get collection data
    if ($PSCmdlet.ParameterSetName -eq 'FromApi') {
        # Use API key from parameter or environment
        $key = $ApiKey
        if (-not $key) {
            $key = $env:POSTMAN_API_KEY
        }
        
        if (-not $key) {
            Write-Error "API key required. Provide -ApiKey parameter or set `$env:POSTMAN_API_KEY"
            return
        }
        
        $headers = @{ "X-Api-Key" = $key }
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$CollectionUid" -Headers $headers -Method Get
            $collection = $response.collection
        }
        catch {
            Write-Error "Failed to fetch collection: $_"
            return
        }
    }
    else {
        # Load from file
        if (-not (Test-Path $CollectionFile)) {
            Write-Error "Collection file not found: $CollectionFile"
            return
        }
        
        try {
            $collectionData = Get-Content $CollectionFile -Raw | ConvertFrom-Json
            $collection = $collectionData
        }
        catch {
            Write-Error "Failed to parse collection file: $_"
            return
        }
    }

    # Determine starting items (collection root or specific folder)
    if ($FolderPath) {
        $startItems = Find-Folder -Items $collection.item -Path $FolderPath
        if (-not $startItems) {
            return
        }
    }
    else {
        $startItems = $collection.item
    }

    # Count by folder or total
    if ($ByFolder) {
        $results = @()
        
        foreach ($topFolder in $startItems) {
            $result = Count-Requests -Items @($topFolder)
            
            $obj = [PSCustomObject]@{
                Folder = $topFolder.name
                Requests = $result.Count
            }
            
            if ($IncludeScriptRequests) {
                $obj | Add-Member -MemberType NoteProperty -Name 'ScriptRequests' -Value $result.ScriptCount
                $obj | Add-Member -MemberType NoteProperty -Name 'Total' -Value ($result.Count + $result.ScriptCount)
            }
            
            $results += $obj
        }
        
        return $results | Sort-Object Requests -Descending
    }
    else {
        # Total count
        $result = Count-Requests -Items $startItems
        
        if ($IncludeScriptRequests) {
            return [PSCustomObject]@{
                CollectionName = $collection.info.name
                NamedRequests = $result.Count
                ScriptRequests = $result.ScriptCount
                Total = $result.Count + $result.ScriptCount
            }
        }
        else {
            return $result.Count
        }
    }
}

