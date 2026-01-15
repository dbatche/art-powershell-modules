# Get-PostmanResourceGroups CLI Output Fix

## The Issue

When using `Write-Host`, the output goes directly to the console and **bypasses the PowerShell pipeline**. This means you can't pipe the output to other commands like `Select-Object`, `Where-Object`, or `Invoke-Expression`.

```powershell
# ❌ DOESN'T WORK (Write-Host output)
Get-PostmanResourceGroups -Path "report.json" -Format CLI | Select-Object -First 1
# Nothing in the pipeline to select!

# ❌ DOESN'T WORK
Get-PostmanResourceGroups -Path "report.json" -Format CLI | ForEach-Object { iex $_ }
# Nothing in the pipeline to execute!
```

## The Solution

Changed CLI format to output strings directly to the pipeline (implicit `Write-Output`):

```powershell
# ✅ NOW WORKS!
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI

# ✅ Can filter
$commands | Where-Object { $_ -match 'checks' }

# ✅ Can limit
$commands | Select-Object -First 3

# ✅ Can execute
$commands | Where-Object { $_ -notmatch '^#' } | ForEach-Object { iex $_ }
```

## Key Differences

| Aspect | Write-Host | Write-Output (implicit) |
|--------|-----------|------------------------|
| **Goes to pipeline** | ❌ No | ✅ Yes |
| **Can be captured** | ❌ No | ✅ Yes |
| **Can be piped** | ❌ No | ✅ Yes |
| **Supports colors** | ✅ Yes | ❌ No |
| **Good for headers/footers** | ✅ Yes | ❌ No |

## Current Implementation

**CLI Format Output Strategy:**
- **Headers/Footers**: Use `Write-Host` (colorized, informational)
- **Commands**: Use implicit output (pipeline-friendly)

This gives us the best of both worlds:
- Beautiful, colorized headers for context
- Pipeline-compatible command strings for automation

## Usage Examples

### 1. Basic Command Capture
```powershell
# Get all commands
$all = Get-PostmanResourceGroups -Path "report.json" -Format CLI

# Get only actual commands (no comments/blanks)
$commands = $all | Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }

Write-Host "Total commands: $($commands.Count)"
```

### 2. Execute First Command
```powershell
Get-PostmanResourceGroups -Path "report.json" -Format CLI |
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' } |
    Select-Object -First 1 |
    ForEach-Object { iex $_ }
```

### 3. Filter and Execute Specific Resources
```powershell
$all = Get-PostmanResourceGroups -Path "report.json" -Format CLI
$i = 0
$lines = @($all)

while ($i -lt $lines.Count) {
    if ($lines[$i] -match '# Resource: /(checks|apInvoices)') {
        # Next line is the command
        $command = $lines[$i + 1]
        if ($command -match '^postman collection run') {
            Write-Host "Executing: $($lines[$i])" -ForegroundColor Cyan
            Invoke-Expression $command
        }
    }
    $i++
}
```

### 4. Background Jobs
```powershell
$commands = Get-PostmanResourceGroups -Path "report.json" -Format CLI |
    Where-Object { $_ -notmatch '^#' -and $_ -notmatch '^\s*$' }

# Start first 3 as jobs
$jobs = $commands | Select-Object -First 3 | ForEach-Object {
    Start-Job -ScriptBlock {
        param($cmd)
        Invoke-Expression $cmd
    } -ArgumentList $_
}

# Monitor
Get-Job | Wait-Job | Receive-Job
Get-Job | Remove-Job
```

### 5. Using Helper Function
```powershell
# Load the helper
. .\Invoke-PostmanResourceTests.Public.ps1

# Run first resource
Invoke-PostmanResourceTests -Path "report.json" -MaxResources 1

# Run specific resources
Invoke-PostmanResourceTests -Path "report.json" -ResourceFilter "checks|apInvoices"

# Run in parallel
Invoke-PostmanResourceTests -Path "report.json" -Parallel -MaxResources 3
```

## Newman Structure Option

The `-NewmanStructure` switch adds the Newman format flag to commands:

```powershell
# Without flag
Get-PostmanResourceGroups -Path "report.json" -Format CLI
# Output: --reporters json

# With flag
Get-PostmanResourceGroups -Path "report.json" -Format CLI -NewmanStructure
# Output: --reporters json --reporter-json-structure newman
```

**Why use Newman structure?**
- Includes folder IDs in output reports
- Allows chaining: run → analyze → run specific folders → analyze...
- Preserves collection structure for future analysis

## Comment Safety

Commands include `#` comment lines that are **safe for copy/paste**:

```powershell
# Resource: /checks (80 tests)
postman collection run <collection-id> -e <env-id> -i <folder-id> --reporters json
```

When you paste both lines:
1. PowerShell ignores the comment line (no error)
2. The command executes normally

This keeps the helpful context while remaining executable!

## Tips

1. **Filter early**: Use `Where-Object` to filter before executing
2. **Test first**: Use `-MaxResources 1` to test your pipeline
3. **Background jobs**: Great for parallel execution, but remember to clean up
4. **Error handling**: Wrap `iex` in `try/catch` for production
5. **Dry run**: Capture commands first, review, then execute

## See Also

- `CLI-Command-Examples.md` - Comprehensive usage examples
- `Invoke-PostmanResourceTests.Public.ps1` - Helper function for common workflows
- `Get-PostmanResourceGroups.Public.ps1` - Main function

