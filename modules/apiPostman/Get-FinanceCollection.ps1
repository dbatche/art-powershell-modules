# Fetch Finance Functional Tests collection
$apiKey = $env:POSTMAN_API_KEY
if (-not $apiKey) {
    Write-Error "POSTMAN_API_KEY environment variable not set. Run Setup-EnvironmentVariables first."
    exit 1
}
$headers = @{ "X-Api-Key" = $apiKey }

Write-Host "`nFetching Finance Functional Tests collection..." -ForegroundColor Cyan

$collections = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers).collections
$financeCollections = $collections | Where-Object { $_.name -eq "Finance Functional Tests" }

if ($financeCollections) {
    Write-Host "✓ Found $(@($financeCollections).Count) Finance collection(s)" -ForegroundColor Green
    
    # Try each one until we find the apInvoices folder
    $fullCollection = $null
    foreach ($fc in $financeCollections) {
        Write-Host "`nTrying UID: $($fc.uid)" -ForegroundColor Gray
        
        try {
            $tempCollection = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$($fc.uid)" -Headers $headers).collection
            
            # Quick check if it has apInvoices
            $hasApInvoices = $false
            foreach ($item in $tempCollection.item) {
                if ($item.name -like "*apInvoices*" -or $item.name -like "*apinvoices*") {
                    $hasApInvoices = $true
                    break
                }
                if ($item.item) {
                    foreach ($subItem in $item.item) {
                        if ($subItem.name -like "*apInvoices*" -or $subItem.name -like "*apinvoices*") {
                            $hasApInvoices = $true
                            break
                        }
                    }
                }
            }
            
            if ($hasApInvoices) {
                Write-Host "  ✓ This one has apInvoices!" -ForegroundColor Green
                $fullCollection = $tempCollection
                break
            } else {
                Write-Host "  No apInvoices folder in this one" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Error fetching: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    if (-not $fullCollection) {
        Write-Host "`n✗ Could not find a Finance collection with apInvoices folder" -ForegroundColor Red
        exit 1
    }
    
    # Save full collection
    $fullCollection | ConvertTo-Json -Depth 50 | Out-File "postmanAPI/temp-finance-collection.json" -Encoding utf8
    Write-Host "✓ Saved to: postmanAPI/temp-finance-collection.json" -ForegroundColor Green
    
    # Find apInvoices folder
    Write-Host "`nSearching for apInvoices folder..." -ForegroundColor Cyan
    
    function Find-Folder {
        param($items, $folderName, $path = "")
        
        foreach ($item in $items) {
            $currentPath = if ($path) { "$path / $($item.name)" } else { $item.name }
            
            if ($item.name -like "*$folderName*") {
                Write-Host "  Found: $currentPath" -ForegroundColor Yellow
                return $item
            }
            
            if ($item.item) {
                $result = Find-Folder -items $item.item -folderName $folderName -path $currentPath
                if ($result) { return $result }
            }
        }
    }
    
    $apInvoicesFolder = Find-Folder -items $fullCollection.item -folderName "apInvoices"
    
    if ($apInvoicesFolder) {
        Write-Host "`n✓ Found apInvoices folder!" -ForegroundColor Green
        Write-Host "`nSearching for 'ista' requests..." -ForegroundColor Cyan
        
        function Find-IstaRequests {
            param($items, $path = "")
            
            $results = @()
            
            foreach ($item in $items) {
                $currentPath = if ($path) { "$path / $($item.name)" } else { $item.name }
                
                if ($item.name -like "*ista*") {
                    $results += [PSCustomObject]@{
                        Name = $item.name
                        Path = $currentPath
                        Item = $item
                    }
                }
                
                if ($item.item) {
                    $results += Find-IstaRequests -items $item.item -path $currentPath
                }
            }
            
            return $results
        }
        
        $istaRequests = Find-IstaRequests -items $apInvoicesFolder.item
        
        if ($istaRequests) {
            Write-Host "`nFound $($istaRequests.Count) ista-related request(s):" -ForegroundColor Green
            
            foreach ($req in $istaRequests) {
                Write-Host "`n  • $($req.Name)" -ForegroundColor White
                Write-Host "    Path: $($req.Path)" -ForegroundColor Gray
                
                # Save this specific request to a file
                $safeName = $req.Name -replace '[^\w\-]', '_'
                $outputFile = "postmanAPI/ista-request-$safeName.json"
                $req.Item | ConvertTo-Json -Depth 20 | Out-File $outputFile -Encoding utf8
                Write-Host "    Saved to: $outputFile" -ForegroundColor Cyan
            }
        } else {
            Write-Host "No ista requests found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ apInvoices folder not found" -ForegroundColor Red
    }
    
} else {
    Write-Host "✗ Finance Functional Tests collection not found" -ForegroundColor Red
}

Write-Host ""
