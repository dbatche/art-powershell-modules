function Update-PostmanBackupSystem {
    <#
    .SYNOPSIS
    Updates the Postman Backup System collection with new backup requests and workspace IDs.
    
    .DESCRIPTION
    Adds backup requests for TM - Visibility and TM - ConnectedDock collections,
    and updates the environment backup script to include their workspace IDs.
    
    .EXAMPLE
    Update-PostmanBackupSystem
    
    .NOTES
    Requires POSTMAN_API_KEY environment variable or pass ApiKey parameter.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY
    )
    
    if (-not $ApiKey) {
        throw "ApiKey is required. Please provide it as a parameter or set the `$env:POSTMAN_API_KEY environment variable."
    }
    
    $BackupCollectionId = "2332132-669c5855-dd73-4858-9222-78547c739666"
    $headers = @{ 'X-Api-Key' = $ApiKey }
    
    Write-Verbose "Fetching Backup System collection..."
    $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$BackupCollectionId" -Headers $headers -Method Get
    $fullCollection = $response.collection
    
    $backupFolder = $fullCollection.item | Where-Object { $_.name -match 'Collection Backups' }
    $envFolder = $fullCollection.item | Where-Object { $_.name -match 'Environment Backups' }
    
    if (-not $backupFolder -or -not $envFolder) {
        throw "Required folders not found in collection"
    }
    
    $existingNames = $backupFolder.item | ForEach-Object { $_.name }
    $changesMade = $false
    
    # Add Visibility backup request
    if ($existingNames -notcontains "Backup: TM - Visibility") {
        if ($PSCmdlet.ShouldProcess("Backup: TM - Visibility", "Add backup request")) {
            $visRequest = @{
                name = "Backup: TM - Visibility"
                request = @{
                    method = "POST"
                    header = @(
                        @{ key = "X-Api-Key"; value = "{{POSTMAN_API_KEY}}"; type = "text" }
                        @{ key = "Content-Type"; value = "application/json"; type = "text" }
                    )
                    body = @{ mode = "raw"; raw = "{{backupCollection}}"; options = @{ raw = @{ language = "json" } } }
                    url = @{ raw = "https://api.getpostman.com/collections"; protocol = "https"; host = @("api", "getpostman", "com"); path = @("collections") }
                }
                event = @(
                    @{
                        listen = "prerequest"
                        script = @{
                            type = "text/javascript"
                            exec = @(
                                'const sourceCollectionId = "11896768-e6367dcf-d508-467e-aa2b-96bfa593a331";',
                                'pm.sendRequest({ url: `https://api.getpostman.com/collections/${sourceCollectionId}`, method: ''GET'', header: { ''X-Api-Key'': pm.environment.get("POSTMAN_API_KEY") } }, function (err, response) {',
                                '    if (err) { console.log("Error:", err); pm.variables.set("backupError", err.message); return; }',
                                '    const collection = response.json().collection; const originalName = collection.info.name;',
                                '    pm.variables.set("originalName", originalName);',
                                '    const backupPrefix = pm.variables.get("backupPrefix"); const dateStamp = pm.variables.get("dateStamp"); const timeStamp = pm.variables.get("timeStamp");',
                                '    const backupName = backupPrefix + " " + dateStamp + timeStamp + " - " + originalName;',
                                '    collection.info.name = backupName; collection.info.description = "Backup of " + originalName + " created on " + dateStamp + timeStamp;',
                                '    delete collection.info._postman_id;',
                                '    pm.variables.set("backupCollection", JSON.stringify({ collection: collection })); pm.variables.set("backupName", backupName);',
                                '    console.log("Prepared backup: " + backupName);',
                                '});'
                            )
                        }
                    }
                    @{
                        listen = "test"
                        script = @{ type = "text/javascript"; exec = @('pm.test("Backup created", function () { pm.response.to.have.status(200); });', 'if (pm.response.code === 200) { const r = pm.response.json(); console.log("SUCCESS: " + pm.variables.get("backupName")); }') }
                    }
                )
            }
            $backupFolder.item += $visRequest
            $changesMade = $true
            Write-Host "Added: Backup: TM - Visibility" -ForegroundColor Green
        }
    }
    
    # Add ConnectedDock backup request
    if ($existingNames -notcontains "Backup: TM - ConnectedDock") {
        if ($PSCmdlet.ShouldProcess("Backup: TM - ConnectedDock", "Add backup request")) {
            $dockRequest = @{
                name = "Backup: TM - ConnectedDock"
                request = @{
                    method = "POST"
                    header = @(
                        @{ key = "X-Api-Key"; value = "{{POSTMAN_API_KEY}}"; type = "text" }
                        @{ key = "Content-Type"; value = "application/json"; type = "text" }
                    )
                    body = @{ mode = "raw"; raw = "{{backupCollection}}"; options = @{ raw = @{ language = "json" } } }
                    url = @{ raw = "https://api.getpostman.com/collections"; protocol = "https"; host = @("api", "getpostman", "com"); path = @("collections") }
                }
                event = @(
                    @{
                        listen = "prerequest"
                        script = @{
                            type = "text/javascript"
                            exec = @(
                                'const sourceCollectionId = "8229908-b15b8488-7ab0-43a9-a532-fee56e26f738";',
                                'pm.sendRequest({ url: `https://api.getpostman.com/collections/${sourceCollectionId}`, method: ''GET'', header: { ''X-Api-Key'': pm.environment.get("POSTMAN_API_KEY") } }, function (err, response) {',
                                '    if (err) { console.log("Error:", err); pm.variables.set("backupError", err.message); return; }',
                                '    const collection = response.json().collection; const originalName = collection.info.name;',
                                '    pm.variables.set("originalName", originalName);',
                                '    const backupPrefix = pm.variables.get("backupPrefix"); const dateStamp = pm.variables.get("dateStamp"); const timeStamp = pm.variables.get("timeStamp");',
                                '    const backupName = backupPrefix + " " + dateStamp + timeStamp + " - " + originalName;',
                                '    collection.info.name = backupName; collection.info.description = "Backup of " + originalName + " created on " + dateStamp + timeStamp;',
                                '    delete collection.info._postman_id;',
                                '    pm.variables.set("backupCollection", JSON.stringify({ collection: collection })); pm.variables.set("backupName", backupName);',
                                '    console.log("Prepared backup: " + backupName);',
                                '});'
                            )
                        }
                    }
                    @{
                        listen = "test"
                        script = @{ type = "text/javascript"; exec = @('pm.test("Backup created", function () { pm.response.to.have.status(200); });', 'if (pm.response.code === 200) { const r = pm.response.json(); console.log("SUCCESS: " + pm.variables.get("backupName")); }') }
                    }
                )
            }
            $backupFolder.item += $dockRequest
            $changesMade = $true
            Write-Host "Added: Backup: TM - ConnectedDock" -ForegroundColor Green
        }
    }
    
    # Update environment backup script
    $envBackupReq = $envFolder.item | Where-Object { $_.name -match 'Backup.*Environment' }
    if ($envBackupReq) {
        $preReq = $envBackupReq.event | Where-Object { $_.listen -eq 'prerequest' }
        $scriptLines = $preReq.script.exec
        $scriptText = $scriptLines -join "`n"
        
        # Check if update is needed
        if ($scriptText -notmatch '419cd1fe-8bd3-4334-b574-6feba34d48d3' -or $scriptText -notmatch 'dfd62437-98b0-4af0-8466-dccdc2f4082c') {
            if ($PSCmdlet.ShouldProcess("Environment backup script", "Update workspaceIds array")) {
                $newScriptLines = @()
                $inArray = $false
                
                for ($i = 0; $i -lt $scriptLines.Count; $i++) {
                    $line = $scriptLines[$i]
                    if ($line -match 'const workspaceIds = \[') {
                        $inArray = $true
                        $newScriptLines += $line
                        $newScriptLines += "    'ae0ddd82-8128-4c1e-ae7a-ff9dd5708b29',  // TM - Orders"
                        $newScriptLines += "    'ac6817f5-408f-474f-802c-6189417e5775',  // TM - Trips"
                        $newScriptLines += "    '73c399a6-2cac-439d-be7e-cfcb3aef519a',  // TM - Finance"
                        $newScriptLines += "    '04a93675-32b1-4c85-b8f7-8aa0196a8e6b',  // TM - Master Data"
                        $newScriptLines += "    '5f0299ec-ffb6-42b4-9d53-9c4766132d60',  // TM - TruckMate"
                        $newScriptLines += "    '8336cc29-ee97-43dd-883d-ff8d36bfe143',  // TM - CloudHub"
                        $newScriptLines += "    '419cd1fe-8bd3-4334-b574-6feba34d48d3',  // TM - Visibility"
                        $newScriptLines += "    'dfd62437-98b0-4af0-8466-dccdc2f4082c'   // TM - ConnectedDock"
                        continue
                    }
                    if ($inArray -and $line -match '^\s*\]') {
                        $inArray = $false
                        $newScriptLines += $line
                        continue
                    }
                    if ($inArray) { continue }
                    $newScriptLines += $line
                }
                
                $preReq.script.exec = $newScriptLines
                $changesMade = $true
                Write-Host "Updated environment backup script workspaceIds array" -ForegroundColor Green
            }
        } else {
            Write-Verbose "Environment backup script already includes new workspaces"
        }
    }
    
    if ($changesMade) {
        if ($PSCmdlet.ShouldProcess("Postman Backup System collection", "Update via API")) {
            Write-Verbose "Uploading updated collection..."
            $updatePayload = @{ collection = $fullCollection } | ConvertTo-Json -Depth 20
            $utf8 = New-Object System.Text.UTF8Encoding $false
            $utf8Bytes = $utf8.GetBytes($updatePayload)
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add('X-Api-Key', $ApiKey)
            $webClient.Headers.Add('Content-Type', 'application/json; charset=utf-8')
            $webClient.Encoding = [System.Text.Encoding]::UTF8
            
            try {
                $null = $webClient.UploadData("https://api.getpostman.com/collections/$BackupCollectionId", 'PUT', $utf8Bytes)
                Write-Host "SUCCESS: Collection updated!" -ForegroundColor Green
                Write-Host "  Total backup requests: $($backupFolder.item.Count)" -ForegroundColor Green
            } catch {
                Write-Error "Failed to update collection: $($_.Exception.Message)"
                throw
            } finally {
                $webClient.Dispose()
            }
        }
    } else {
        Write-Host "No changes needed - collection is already up to date" -ForegroundColor Yellow
    }
}

