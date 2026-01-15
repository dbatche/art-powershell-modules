# Examples of handling stderr (Stream 2) in tests

Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artFinance\artFinance.psm1 -Force -WarningAction SilentlyContinue
Setup-EnvironmentVariables -Quiet

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "STDERR HANDLING EXAMPLES" -ForegroundColor White
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# OLD WAY: Suppress stderr completely (loses information)
# ============================================================================
Write-Host "[1] OLD: Suppressing errors with 2>`$null" -ForegroundColor Yellow
Write-Host "    (Error details are completely lost)" -ForegroundColor Gray

$result1 = Set-InterlinerPayable -InterlinerPayableId 999999 -InterlinerPayable @{
    adjustedExtras = 100
} 2>$null

Write-Host "    Result type: $($result1.GetType().Name)" -ForegroundColor Gray
Write-Host ""


# ============================================================================
# NEW WAY 1: Redirect stderr to log file
# ============================================================================
Write-Host "[2] NEW: Redirect errors to log file with 2>>" -ForegroundColor Green
Write-Host "    (Errors captured in test-errors.log)" -ForegroundColor Gray

$result2 = Set-InterlinerPayable -InterlinerPayableId 999999 -InterlinerPayable @{
    adjustedExtras = 100
} 2>> "test-errors.log"

Write-Host "    Result type: $($result2.GetType().Name)" -ForegroundColor Gray
Write-Host "    Check test-errors.log for error details" -ForegroundColor DarkGray
Write-Host ""


# ============================================================================
# NEW WAY 2: Using helper function
# ============================================================================
Write-Host "[3] NEW: Using Invoke-TestApiCall helper" -ForegroundColor Green
Write-Host "    (Clean syntax, errors auto-logged)" -ForegroundColor Gray

$result3 = Invoke-TestApiCall {
    Set-InterlinerPayable -InterlinerPayableId 999999 -InterlinerPayable @{
        adjustedExtras = 100
    }
}

Write-Host "    Result type: $($result3.GetType().Name)" -ForegroundColor Gray
Write-Host "    Errors automatically logged to test-errors.log" -ForegroundColor DarkGray
Write-Host ""


# ============================================================================
# Show log file contents
# ============================================================================
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "ERROR LOG CONTENTS" -ForegroundColor White
Write-Host ("=" * 80) -ForegroundColor Cyan

if (Test-Path "test-errors.log") {
    Get-Content "test-errors.log" | Select-Object -Last 10
    Write-Host ""
    Write-Host "Full log: $(Resolve-Path 'test-errors.log')" -ForegroundColor DarkGray
} else {
    Write-Host "No error log found" -ForegroundColor Yellow
}

