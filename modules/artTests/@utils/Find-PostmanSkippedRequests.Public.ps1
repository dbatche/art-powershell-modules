function Find-PostmanSkippedRequests {
    <#
    .SYNOPSIS
    Finds requests in a Postman collection that have skip logic.

    .DESCRIPTION
    Searches through a Postman collection for requests that contain pm.execution.skipRequest()
    or pm.test.skip in their pre-request or test scripts. Useful for identifying disabled or
    conditionally skipped tests.

    .PARAMETER CollectionUid
    The Postman collection UID (e.g., '8229908-779780a9-97d0-4004-9a96-37e8c64c3405').
    Requires ApiKey parameter.

    .PARAMETER CollectionFile
    Path to a local Postman collection JSON file.

    .PARAMETER ApiKey
    Postman API key for fetching collections from the API.
    Can also be set via $env:POSTMAN_API_KEY.

    .PARAMETER ShowContext
    If specified, shows a few lines of context around the skip logic.

    .EXAMPLE
    Find-PostmanSkippedRequests -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ApiKey $env:POSTMAN_API_KEY

    Finds all requests with skip logic in the collection.

    .EXAMPLE
    Find-PostmanSkippedRequests -CollectionFile 'C:\exports\my-collection.json'

    Finds skipped requests in a local collection file.

    .EXAMPLE
    Find-PostmanSkippedRequests -CollectionUid '8229908-779780a9-97d0-4004-9a96-37e8c64c3405' -ShowContext

    Shows skip logic with surrounding code context.

    .OUTPUTS
    PSCustomObject array with Name, Path, SkipType, and optionally Context
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
        [switch]$ShowContext
    )

    # Helper function to extract context around skip logic
    function Get-SkipContext {
        param(
            [string]$ScriptText,
            [string]$Pattern,
            [int]$ContextLines = 2
        )
        
        $lines = $ScriptText -split "`n"
        $matchingLines = @()
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $Pattern) {
                $start = [Math]::Max(0, $i - $ContextLines)
                $end = [Math]::Min($lines.Count - 1, $i + $ContextLines)
                
                $context = @()
                for ($j = $start; $j -le $end; $j++) {
                    $prefix = if ($j -eq $i) { "→" } else { " " }
                    $context += "$prefix $($lines[$j])"
                }
                
                $matchingLines += ($context -join "`n")
            }
        }
        
        return $matchingLines -join "`n---`n"
    }

    # Helper function to find skipped requests recursively
    function Find-SkippedRequests {
        param(
            [Parameter(Mandatory)]
            $Items,
            
            [string]$Path = ""
        )
        
        $results = @()
        
        foreach ($item in $Items) {
            $currentPath = if ($Path) { "$Path / $($item.name)" } else { $item.name }
            
            if ($item.request -and $item.event) {
                $skipInfo = @{
                    Name = $item.name
                    Path = $currentPath
                    UID = $item.uid
                    SkipTypes = @()
                    Context = @()
                }
                
                foreach ($event in $item.event) {
                    if ($event.script.exec) {
                        $scriptText = $event.script.exec -join "`n"
                        
                        # Check for pm.execution.skipRequest()
                        if ($scriptText -match "pm\.execution\.skipRequest") {
                            $skipInfo.SkipTypes += "pm.execution.skipRequest() [PRE-REQUEST]"
                            
                            if ($ShowContext) {
                                $context = Get-SkipContext -ScriptText $scriptText -Pattern "pm\.execution\.skipRequest"
                                $skipInfo.Context += "PRE-REQUEST:`n$context"
                            }
                        }
                        
                        # Check for pm.test.skip
                        if ($scriptText -match "pm\.test\.skip") {
                            $skipInfo.SkipTypes += "pm.test.skip [TEST]"
                            
                            if ($ShowContext) {
                                $context = Get-SkipContext -ScriptText $scriptText -Pattern "pm\.test\.skip"
                                $skipInfo.Context += "TEST:`n$context"
                            }
                        }
                    }
                }
                
                if ($skipInfo.SkipTypes.Count -gt 0) {
                    $obj = [PSCustomObject]@{
                        Name = $skipInfo.Name
                        Path = $skipInfo.Path
                        UID = $skipInfo.UID
                        SkipType = $skipInfo.SkipTypes -join ", "
                    }
                    
                    if ($ShowContext) {
                        $obj | Add-Member -MemberType NoteProperty -Name 'Context' -Value ($skipInfo.Context -join "`n`n")
                    }
                    
                    $results += $obj
                }
            }
            
            # Recurse into subfolders
            if ($item.item) {
                $results += Find-SkippedRequests -Items $item.item -Path $currentPath
            }
        }
        
        return $results
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

    # Find skipped requests
    $results = Find-SkippedRequests -Items $collection.item
    
    if ($results.Count -eq 0) {
        Write-Host "✓ No requests found with skip logic (pm.execution.skipRequest or pm.test.skip)" -ForegroundColor Green
        return $null
    }
    
    return $results
}

