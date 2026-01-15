function Get-ApiVersion {
    <#
    .SYNOPSIS
        Retrieve API version from the /version endpoint
    
    .DESCRIPTION
        Calls the /version endpoint to get API version information.
        Serves three purposes:
        1. Quick manual check of API status
        2. Pre-flight check before running tests
        3. Version tracking for reports and filenames
    
    .PARAMETER BaseUrl
        Base URL of the API (e.g., 'https://tde-truckmate.tmwcloud.com/fin/finance')
    
    .PARAMETER Token
        Optional bearer token for authentication
    
    .PARAMETER Quiet
        Suppress output, only return version object
    
    .OUTPUTS
        PSCustomObject with properties:
        - Version: Version string (e.g., "25.4.75.4")
        - Debug: Debug flag (e.g., "false")
        - Success: Boolean indicating if version was retrieved
        - BaseUrl: The API base URL
        - Timestamp: When the check was performed
    
    .EXAMPLE
        Get-ApiVersion -BaseUrl "https://api.example.com/finance" -Token $token
        # Shows version info and returns object
    
    .EXAMPLE
        $ver = Get-ApiVersion -BaseUrl $url -Token $token -Quiet
        if ($ver.Success) {
            Write-Host "API Version: $($ver.Version)"
        }
    
    .EXAMPLE
        # Use in filename
        $ver = Get-ApiVersion -BaseUrl $url -Token $token -Quiet
        $filename = "openapi-finance-v$($ver.Version).json"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl,
        
        [Parameter(Mandatory=$false)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [switch]$Quiet
    )
    
    # Use environment variables as fallback (try service-specific first, then generic)
    if (-not $BaseUrl) {
        $BaseUrl = $env:DOMAIN
    }
    if (-not $Token) {
        $Token = $env:TRUCKMATE_API_KEY
    }
    
    # Validate required parameters
    if (-not $BaseUrl) {
        throw "BaseUrl is required. Provide -BaseUrl or set environment variable (FINANCE_API_URL, VISIBILITY_API_URL, TM_API_URL, or DOMAIN)"
    }
    
    $versionUrl = "$($BaseUrl.TrimEnd('/'))/version"
    
    if (-not $Quiet) {
        Write-Host "Checking API version..." -ForegroundColor Cyan
        Write-Host "  URL: $versionUrl" -ForegroundColor Gray
    }
    
    try {
        $headers = @{}
        if ($Token) {
            $headers.Authorization = "Bearer $Token"
        }
        
        $response = Invoke-RestMethod -Uri $versionUrl -Headers $headers -Method GET -ErrorAction Stop
        
        $result = [PSCustomObject]@{
            Version = $response.version
            Debug = $response.debug
            Success = $true
            BaseUrl = $BaseUrl
            Timestamp = Get-Date -Format 'o'
        }
        
        if (-not $Quiet) {
            Write-Host "✅ API is running" -ForegroundColor Green
            Write-Host "  Version: $($result.Version)" -ForegroundColor Yellow
            if ($result.Debug) {
                Write-Host "  Debug: $($result.Debug)" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
        return $result
        
    } catch {
        $result = [PSCustomObject]@{
            Version = $null
            Debug = $null
            Success = $false
            BaseUrl = $BaseUrl
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format 'o'
        }
        
        if (-not $Quiet) {
            Write-Host "❌ Failed to get version" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
        }
        
        return $result
    }
}

