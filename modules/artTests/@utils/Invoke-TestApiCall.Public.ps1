function Invoke-TestApiCall {
    <#
    .SYNOPSIS
        Wrapper for API calls in tests that captures stderr to log file
    
    .DESCRIPTION
        Executes an API call and captures stderr (Write-Error output) to a log file
        instead of suppressing it with 2>$null. This preserves error details for
        troubleshooting while keeping console output clean.
    
    .PARAMETER ScriptBlock
        The API call to execute
        
    .PARAMETER ErrorLogFile
        Path to error log file (default: test-errors.log in current directory)
        
    .EXAMPLE
        $result = Invoke-TestApiCall {
            Set-InterlinerPayable -InterlinerPayableId $id -InterlinerPayable @{ amount = -100 }
        }
        
    .EXAMPLE
        $result = Invoke-TestApiCall -ErrorLogFile "interliner-errors.log" {
            Set-CashReceipt -CashReceiptId $id -CashReceipt @{ checkAmount = 'invalid' }
        }
    
    .OUTPUTS
        API response object or JSON error string
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        [string]$ErrorLogFile = "test-errors.log"
    )
    
    # Resolve full path
    $logPath = if ([System.IO.Path]::IsPathRooted($ErrorLogFile)) {
        $ErrorLogFile
    } else {
        Join-Path (Get-Location) $ErrorLogFile
    }
    
    # Capture both output and errors
    try {
        # Redirect stderr (stream 2) to the log file
        # This captures Write-Error output without suppressing it completely
        $result = & $ScriptBlock 2>> $logPath
        return $result
    }
    catch {
        # Unexpected errors (not API errors)
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        "[$timestamp] EXCEPTION: $_" | Out-File -FilePath $logPath -Append -Encoding UTF8
        throw
    }
}

