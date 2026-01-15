function Get-PostmanRunFailures {
	<#
	.SYNOPSIS
	Analyzes Postman run results and extracts information about failing tests
	
	.DESCRIPTION
	Reads Postman Native format JSON report files and identifies requests with failing tests.
	Returns UIDs, request names, failure counts, and folder paths.
	Can optionally generate a postman CLI command to re-run only the failing tests.
	
	.PARAMETER Path
	Path to the Postman native format JSON report file
	
	.PARAMETER Format
	Output format: Table (default), List, Raw, or CommandLine
	
	.PARAMETER CollectionId
	Collection ID for generating command line (format: userid-collectionid)
	Optional - will be extracted from report file if available
	
	.PARAMETER EnvironmentId
	Environment ID for generating command line (format: workspaceid-environmentid)
	Optional - will be extracted from report file if available
	
	.PARAMETER OutputFile
	Output file path for JSON report when Format is 'CommandLine'
	Default: postman-cli-reports\{CollectionName}-FailedTests-{timestamp}.json
	
	.EXAMPLE
	Get-PostmanRunFailures -Path "Finance-Functional-Tests-2025-10-03.json"
	
	Shows table of failing tests with UIDs, names, and failure counts
	
	.EXAMPLE
	Get-PostmanRunFailures -Path "Finance-*.json" -Format List
	
	Shows detailed list format
	
	.EXAMPLE
	Get-PostmanRunFailures -Path "Finance-*.json" -Format Raw
	
	Returns raw PowerShell objects for further processing
	
	.EXAMPLE
	Get-PostmanRunFailures -Path "Finance-2025-10-03.json" -Format CommandLine -EnvironmentId "11896768-68887950-1feb-4817-87c5-f5dcffa370cb"
	
	Generates postman CLI command to re-run only failing tests (CollectionId auto-extracted)
	
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path,
		
		[ValidateSet('Table', 'List', 'Raw', 'CommandLine')]
		[string]$Format = 'Table',
		
		[string]$CollectionId,
		
		[string]$EnvironmentId,
		
		[string]$OutputFile
	)
	
	if (-not (Test-Path $Path)) {
		Write-Error "File not found: $Path"
		return
	}
	
	$file = Get-Item $Path
	Write-Host "Analyzing: $($file.Name)" -ForegroundColor Cyan
	
	try {
		Write-Host "Reading JSON file..." -ForegroundColor Yellow
		$content = Get-Content $file.FullName -Raw | ConvertFrom-Json
		$runData = $content.run
		
		# Extract collection and environment info
		$collectionIdFromFile = $runData.meta.collectionId
		$collectionNameFromFile = $runData.meta.collectionName
		# Note: Environment ID is not typically in the native format report
		
		Write-Host "Extracting failing test information..." -ForegroundColor Yellow
		
		# Track unique failing requests
		$failureMap = @{}
		$execIndex = 0
		
		foreach ($exec in $runData.executions) {
			$execIndex++
			
			if ($exec.tests) {
				$failedTests = @()
				foreach ($test in $exec.tests) {
					if ($test.status -eq 'failed') {
						$failedTests += $test.name
					}
				}
				
				if ($failedTests.Count -gt 0) {
					$uid = $exec.requestExecuted.id
					$requestName = $exec.requestExecuted.name
					$method = $exec.requestExecuted.method
					
					# Extract folder path from URL path, skipping generic prefixes
					$folderPath = ""
					if ($exec.requestExecuted.url.path) {
						$pathSegments = $exec.requestExecuted.url.path | Where-Object { 
							$_ -notmatch '^\{\{.*\}\}$' -and 
							$_ -ne "" -and 
							$_ -notmatch '^(fin|finance|api|v1|v2)$'
						}
						if ($pathSegments) {
							$folderPath = $pathSegments -join ' / '
						}
					}
					
					if (-not $failureMap.ContainsKey($uid)) {
						$failureMap[$uid] = @{
							UID = $uid
							RequestName = $requestName
							Method = $method
							FailedTestCount = 0
							FailedTests = @()
							FolderPath = $folderPath
							FirstExecution = $execIndex
						}
					}
					
					$failureMap[$uid].FailedTestCount += $failedTests.Count
					$failureMap[$uid].FailedTests += $failedTests
				}
			}
		}
		
		if ($failureMap.Count -eq 0) {
			Write-Host "`nNo failing tests found! 🎉" -ForegroundColor Green
			return
		}
		
		# Convert to array and sort
		$failures = $failureMap.Values | ForEach-Object {
			[PSCustomObject]@{
				ExecutionOrder = $_.FirstExecution
				UID = $_.UID
				Method = $_.Method
				RequestName = $_.RequestName
				FailedTestCount = $_.FailedTestCount
				FolderPath = $_.FolderPath
				FailedTests = $_.FailedTests
			}
		} | Sort-Object ExecutionOrder
		
		# Output based on format
		switch ($Format) {
			'CommandLine' {
				# Use provided CollectionId or extract from file
				$useCollectionId = if ($CollectionId) { $CollectionId } else { $collectionIdFromFile }
				if (-not $useCollectionId) {
					Write-Error "CollectionId not found in file and not provided as parameter"
					return
				}
				
				# Use provided EnvironmentId (cannot be extracted from native format)
				$useEnvironmentId = $EnvironmentId
				if (-not $useEnvironmentId) {
					Write-Warning "EnvironmentId parameter not provided - using placeholder <ENVIRONMENT_ID>"
					Write-Host "Replace <ENVIRONMENT_ID> with your actual environment ID" -ForegroundColor Yellow
					$useEnvironmentId = "<ENVIRONMENT_ID>"
				}
				
				Write-Host "`n" -NoNewline
				Write-Host ("=" * 80) -ForegroundColor Green
				Write-Host "POSTMAN CLI COMMAND TO RE-RUN FAILING TESTS" -ForegroundColor Green
				Write-Host ("=" * 80) -ForegroundColor Green
				Write-Host ""
				
				$cmd = "postman collection run $useCollectionId -e $useEnvironmentId"
				
				foreach ($failure in $failures) {
					$cmd += " -i $($failure.UID)"
				}
				
				$cmd += " --reporters json,cli"
				
				if ($OutputFile) {
					$cmd += " --reporter-json-export $OutputFile"
				} else {
					$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
					$cleanName = $collectionNameFromFile -replace '[^a-zA-Z0-9-]', '-'
					$cmd += " --reporter-json-export postman-cli-reports\$cleanName-FailedTests-$timestamp.json"
				}
				
				Write-Host $cmd -ForegroundColor Yellow
				Write-Host ""
				Write-Host ("=" * 80) -ForegroundColor Green
				Write-Host "Total failing requests: $($failures.Count)" -ForegroundColor Cyan
				Write-Host "Total failed assertions: $(($failures | Measure-Object -Property FailedTestCount -Sum).Sum)" -ForegroundColor Cyan
				Write-Host ""
			}
			'Raw' {
				# Just return the data object with no formatting
				return $failures
			}
			'List' {
				Write-Host "`n" -NoNewline
				Write-Host ("=" * 80) -ForegroundColor Yellow
				Write-Host "FAILING TESTS DETAIL" -ForegroundColor Yellow
				Write-Host ("=" * 80) -ForegroundColor Yellow
				Write-Host ""
				
				foreach ($failure in $failures) {
					Write-Host "Request: " -NoNewline -ForegroundColor Cyan
					Write-Host "$($failure.Method) $($failure.RequestName)" -ForegroundColor White
					Write-Host "  UID: " -NoNewline -ForegroundColor Gray
					Write-Host $failure.UID -ForegroundColor White
					Write-Host "  Path: " -NoNewline -ForegroundColor Gray
					Write-Host $failure.FolderPath -ForegroundColor White
					Write-Host "  Failed Tests: " -NoNewline -ForegroundColor Gray
					Write-Host $failure.FailedTestCount -ForegroundColor Red
					Write-Host "  Failures:" -ForegroundColor Gray
					foreach ($test in $failure.FailedTests) {
						Write-Host "    - $test" -ForegroundColor Red
					}
					Write-Host ""
				}
				
				Write-Host ("=" * 80) -ForegroundColor Yellow
				Write-Host "Total: $($failures.Count) requests with $($($failures | Measure-Object -Property FailedTestCount -Sum).Sum) failed assertions" -ForegroundColor Yellow
			}
			default {
				# Table format
				Write-Host "`n" -NoNewline
				Write-Host ("=" * 80) -ForegroundColor Yellow
				Write-Host "FAILING TESTS SUMMARY" -ForegroundColor Yellow
				Write-Host ("=" * 80) -ForegroundColor Yellow
				Write-Host ""
				
				$failures | Format-Table -Property @{
					Name = '#'
					Expression = {$_.ExecutionOrder}
					Width = 4
				}, @{
					Name = 'Method'
					Expression = {$_.Method}
					Width = 6
				}, @{
					Name = 'Request Name'
					Expression = {$_.RequestName}
					Width = 35
				}, @{
					Name = 'Failures'
					Expression = {$_.FailedTestCount}
					Width = 8
				}, @{
					Name = 'Folder Path'
					Expression = {$_.FolderPath}
					Width = 25
				} -AutoSize
				
				Write-Host ("=" * 80) -ForegroundColor Yellow
				Write-Host "Total: $($failures.Count) requests with $($($failures | Measure-Object -Property FailedTestCount -Sum).Sum) failed assertions" -ForegroundColor Cyan
				Write-Host ""
				Write-Host "TIP: Use -Format CommandLine to generate a command to re-run only these tests" -ForegroundColor Gray
			}
		}
	}
	catch {
		Write-Error "Failed to analyze file: $_"
	}
}

