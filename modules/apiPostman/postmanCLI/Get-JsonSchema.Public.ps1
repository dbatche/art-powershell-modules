function Get-JsonSchema {
	<#
	.SYNOPSIS
	Analyzes and displays the schema structure of a JSON file
	
	.DESCRIPTION
	Reads a JSON file and shows the hierarchical structure of properties and their types
	without displaying all the data. Useful for understanding large JSON files.
	
	.PARAMETER Path
	Path to the JSON file
	
	.PARAMETER MaxDepth
	Maximum depth to traverse (default: 5)
	
	.PARAMETER MaxArrayItems
	Number of array items to sample (default: 1)
	
	.EXAMPLE
	Get-JsonSchema -Path "newman-report.json"
	
	Shows the structure of the JSON file
	
	.EXAMPLE
	Get-JsonSchema -Path "newman-report.json" -MaxDepth 3
	
	Shows structure up to 3 levels deep
	
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path,
		
		[int]$MaxDepth = 5,
		
		[int]$MaxArrayItems = 1
	)
	
	function Get-ObjectSchema {
		param(
			$Object,
			[int]$Depth = 0,
			[string]$Indent = ""
		)
		
		if ($Depth -gt $MaxDepth) {
			return "$Indent... (max depth reached)"
		}
		
		$output = @()
		
		if ($null -eq $Object) {
			return "$Indent" + "<null>"
		}
		
		$type = $Object.GetType().Name
		
		if ($Object -is [System.Management.Automation.PSCustomObject]) {
			$properties = $Object.PSObject.Properties
			foreach ($prop in $properties) {
				$propName = $prop.Name
				$propValue = $prop.Value
				
				if ($null -eq $propValue) {
					$output += "$Indent$propName" + ": <null>"
				}
				elseif ($propValue -is [Array] -or $propValue -is [System.Collections.ArrayList]) {
					$count = $propValue.Count
					$output += "$Indent$propName" + ": [array, $count items]"
					
					if ($count -gt 0 -and $Depth -lt $MaxDepth) {
						# Sample first item to show array structure
						$sampleItems = [Math]::Min($MaxArrayItems, $count)
						for ($i = 0; $i -lt $sampleItems; $i++) {
							$output += "$Indent  [$i]" + ":"
							$output += Get-ObjectSchema -Object $propValue[$i] -Depth ($Depth + 1) -Indent "$Indent    "
						}
						if ($count -gt $MaxArrayItems) {
							$output += "$Indent  ... ($($count - $MaxArrayItems) more items)"
						}
					}
				}
				elseif ($propValue -is [PSCustomObject] -or $propValue -is [System.Management.Automation.PSObject]) {
					$output += "$Indent$propName" + ": {object}"
					$output += Get-ObjectSchema -Object $propValue -Depth ($Depth + 1) -Indent "$Indent  "
				}
				elseif ($propValue -is [string]) {
					$preview = if ($propValue.Length -gt 50) { 
						$propValue.Substring(0, 50) + "..." 
					} else { 
						$propValue 
					}
					$output += "$Indent$propName" + ": ""$preview"" (string, length: $($propValue.Length))"
				}
				elseif ($propValue -is [int] -or $propValue -is [long] -or $propValue -is [double]) {
					$output += "$Indent$propName" + ": $propValue ($($propValue.GetType().Name))"
				}
				elseif ($propValue -is [bool]) {
					$output += "$Indent$propName" + ": $propValue (bool)"
				}
				else {
					$output += "$Indent$propName" + ": $propValue ($($propValue.GetType().Name))"
				}
			}
		}
		elseif ($Object -is [Array]) {
			$count = $Object.Count
			$output += "$Indent[array, $count items]"
			if ($count -gt 0) {
				$output += Get-ObjectSchema -Object $Object[0] -Depth ($Depth + 1) -Indent "$Indent  "
			}
		}
		else {
			$output += "$Indent$Object ($type)"
		}
		
		return $output
	}
	
	if (-not (Test-Path $Path)) {
		Write-Error "File not found: $Path"
		return
	}
	
	$file = Get-Item $Path
	Write-Host "Analyzing JSON schema for: $($file.Name)" -ForegroundColor Cyan
	Write-Host "File size: $([math]::Round($file.Length / 1MB, 2)) MB" -ForegroundColor Cyan
	Write-Host ""
	
	try {
		Write-Host "Reading JSON file (this may take a moment)..." -ForegroundColor Yellow
		$json = Get-Content $Path -Raw | ConvertFrom-Json
		
		Write-Host "`nJSON Schema Structure:" -ForegroundColor Green
		Write-Host "=" * 80 -ForegroundColor Green
		
		$schema = Get-ObjectSchema -Object $json -Depth 0 -Indent ""
		$schema | ForEach-Object { Write-Host $_ }
		
		Write-Host "`n" + ("=" * 80) -ForegroundColor Green
		Write-Host "Total top-level properties: $($json.PSObject.Properties.Count)" -ForegroundColor Cyan
	}
	catch {
		Write-Error "Failed to parse JSON: $_"
	}
}

