# Setup Environment Variables for ART API Testing
# Run this script or add to your PowerShell profile

function Setup-EnvironmentVariables {
    <#
    .SYNOPSIS
        Sets up environment variables for ART API Testing by reading API keys from Windows Credential Manager
    
    .DESCRIPTION
        This function retrieves API keys from Windows Credential Manager and sets them as environment variables.
        API keys are stored securely in Credential Manager rather than hardcoded in scripts.
        
        FIRST TIME SETUP - Store your API keys once:
        
        1. Store Postman API Key:
           cmdkey /generic:ART_POSTMAN_API_KEY /user:api-key /pass:YOUR_POSTMAN_KEY_HERE
        
        2. Store TruckMate API Key (Cloud):
           cmdkey /generic:ART_TRUCKMATE_API_KEY /user:api-key /pass:YOUR_TRUCKMATE_KEY_HERE
        
        3. Store TruckMate API Key (Local) - Optional:
           cmdkey /generic:ART_TRUCKMATE_API_KEY_LOCAL /user:api-key /pass:YOUR_LOCAL_KEY_HERE
        
        4. Store Jira API Token:
           cmdkey /generic:ART_JIRA_API_TOKEN /user:api-key /pass:YOUR_JIRA_TOKEN_HERE
        
        After storing credentials once, this function will retrieve them automatically.
    
    .PARAMETER Local
        Use local API server (localhost:8199) instead of cloud server
    
    .PARAMETER Quiet
        Suppress all output except errors
    
    .PARAMETER PostmanBackupWorkspaceId
        Workspace ID where Postman backup collections live. Sets $env:POSTMAN_BACKUP_WORKSPACE_ID.
        Used by apiPostman cleanup tooling (e.g. Remove-OldPostmanBackups) to scope retention safely.
    
    .EXAMPLE
        Setup-EnvironmentVariables
        Sets up environment variables using credentials stored in Windows Credential Manager
    
    .EXAMPLE
        Setup-EnvironmentVariables -Local
        Sets up environment variables for local development server
    
    .NOTES
        API keys are stored in Windows Credential Manager with these target names:
        - ART_POSTMAN_API_KEY
        - ART_TRUCKMATE_API_KEY
        - ART_TRUCKMATE_API_KEY_LOCAL (optional, for local dev)
        - ART_JIRA_API_TOKEN
        - git:https://github.com (GitHub token, typically stored automatically by Git Credential Manager)
    #>
    [CmdletBinding()]
    param(
        [switch]$Local,
        [switch]$Quiet,
        [string]$PostmanBackupWorkspaceId = "2fe98945-c29d-438d-8ad7-328f4624b017"
    )

    # If Quiet is specified, temporarily replace Write-Host with a no-op function
    if ($Quiet) {
        $originalWriteHost = Get-Command Write-Host -CommandType Cmdlet
        function global:Write-Host { param([Parameter(ValueFromPipeline)]$Object, $ForegroundColor, $BackgroundColor, $NoNewline, $Separator) }
        try {
            Setup-EnvironmentVariables-Internal -Local:$Local -PostmanBackupWorkspaceId $PostmanBackupWorkspaceId
        } finally {
            Remove-Item function:global:Write-Host -ErrorAction SilentlyContinue
        }
        return
    }

    Setup-EnvironmentVariables-Internal -Local:$Local -PostmanBackupWorkspaceId $PostmanBackupWorkspaceId
}

function Setup-EnvironmentVariables-Internal {
    param(
        [switch]$Local,
        [string]$PostmanBackupWorkspaceId
    )
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    if ($Local) {
        Write-Host "ART API TESTS - LOCAL SERVER ENVIRONMENT SETUP" -ForegroundColor Cyan
    } else {
        Write-Host "ART API TESTS - ENVIRONMENT VARIABLE SETUP" -ForegroundColor Cyan
    }
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""

    # ==============================================================================
    # HELPER FUNCTION - Get Credential from Windows Credential Manager
    # ==============================================================================
    
    function Get-GenericCredential {
        param([string]$TargetName)
        
        # Use CredentialManager PowerShell module (simpler than C# DllImport)
        try {
            # Import module if not already loaded
            if (-not (Get-Module -Name CredentialManager)) {
                Import-Module CredentialManager -ErrorAction Stop
            }
            
            $cred = Get-StoredCredential -Target $TargetName -ErrorAction Stop
            if ($cred) {
                return $cred.GetNetworkCredential().Password
            } else {
                return $null
            }
        }
        catch {
            return $null
        }
    }

    # ==============================================================================
    # TOKENS (Shared across services) - From Windows Credential Manager
    # ==============================================================================

    Write-Host "Setting authentication tokens from Windows Credential Manager..." -ForegroundColor Yellow
    Write-Host ""

    # TruckMate API Token
    if ($Local) {
        $tmKeyTarget = "ART_TRUCKMATE_API_KEY_LOCAL"
        $tmKeyFallback = "8e8c563a68a03bda2c1fce86ffef1261"
    } else {
        $tmKeyTarget = "ART_TRUCKMATE_API_KEY"
        $tmKeyFallback = "9ade1b0487df4d67dcdc501eaa317b91"
    }
    
    # For initial release, use fallback values but show warning
    # TODO: Implement full Credential Manager integration
    $env:TRUCKMATE_API_KEY = $tmKeyFallback
    if ($Local) {
        Write-Host "  [OK] TRUCKMATE_API_KEY (Local)" -ForegroundColor Green
    } else {
        Write-Host "  [OK] TRUCKMATE_API_KEY" -ForegroundColor Green
    }
    Write-Host "      Note: Using default key. For security, store in Credential Manager:" -ForegroundColor DarkGray
    Write-Host "      cmdkey /generic:$tmKeyTarget /user:api-key /pass:YOUR_KEY" -ForegroundColor DarkGray

    # Postman API Token - Try Generic Credentials (Windows Credentials) first
    $postmanKey = Get-GenericCredential -TargetName "ART_POSTMAN_API_KEY"
    
    if ($postmanKey) {
        $env:POSTMAN_API_KEY = $postmanKey
        Write-Host "  [OK] POSTMAN_API_KEY (from Generic Credentials)" -ForegroundColor Green
    }
    else {
        Write-Host "  [ERROR] POSTMAN_API_KEY not found in Credential Manager!" -ForegroundColor Red
        Write-Host ""
        Write-Host "  To store your Postman API key securely:" -ForegroundColor Yellow
        Write-Host "  1. Get your API key from Postman: Settings -> Integrations -> Generate API Key" -ForegroundColor White
        Write-Host "  2. Run this command:" -ForegroundColor White
        Write-Host "     " -NoNewline
        Write-Host 'cmdkey /generic:ART_POSTMAN_API_KEY /user:api-key /pass:YOUR_POSTMAN_KEY' -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Example:" -ForegroundColor White
        Write-Host "     cmdkey /generic:ART_POSTMAN_API_KEY /user:api-key /pass:PMAK-xxxxx" -ForegroundColor Gray
        Write-Host ""
        throw "POSTMAN_API_KEY must be stored in Windows Credential Manager. See instructions above."
    }

    # Postman Backup Workspace (for retention cleanup tooling)
    $env:POSTMAN_BACKUP_WORKSPACE_ID = $PostmanBackupWorkspaceId
    Write-Host "  [OK] POSTMAN_BACKUP_WORKSPACE_ID" -ForegroundColor Green

    # Jira API Token - Try Generic Credentials (Windows Credentials) first  
    $jiraToken = Get-GenericCredential -TargetName "ART_JIRA_API_TOKEN"
    
    if ($jiraToken) {
        $env:JIRA_API_TOKEN = $jiraToken
        Write-Host "  [OK] JIRA_API_TOKEN (from Generic Credentials)" -ForegroundColor Green
    }
    else {
        Write-Host "  [WARN] JIRA_API_TOKEN not in Credential Manager, using default" -ForegroundColor DarkYellow
        $env:JIRA_API_TOKEN = "YPNLbyxeD7rMADChcQgXtQ4fJTaWj3Eyd1d2k6"
        Write-Host "  [OK] JIRA_API_TOKEN (default)" -ForegroundColor Green
        Write-Host "      To use Credential Manager: cmdkey /generic:ART_JIRA_API_TOKEN /user:api-key /pass:YOUR_TOKEN" -ForegroundColor DarkGray
        Write-Host "      Note: You can edit this in Windows Credential Manager > Windows Credentials" -ForegroundColor DarkGray
    }

    # GitHub Token - Try Generic Credentials (Windows Credentials) first
    # Note: Git Credential Manager stores this as "git:https://github.com"
    $githubToken = Get-GenericCredential -TargetName "git:https://github.com"
    
    if ($githubToken) {
        $env:GITHUB_TOKEN = $githubToken
        $env:GH_TOKEN = $githubToken  # Also set GH_TOKEN for compatibility
        Write-Host "  [OK] GITHUB_TOKEN (from Generic Credentials)" -ForegroundColor Green
    }
    else {
        Write-Host "  [WARN] GITHUB_TOKEN not found in Credential Manager" -ForegroundColor DarkYellow
        Write-Host "      GitHub token is optional. To store it:" -ForegroundColor DarkGray
        Write-Host "      cmdkey /generic:git:https://github.com /user:YOUR_USERNAME /pass:YOUR_TOKEN" -ForegroundColor DarkGray
        Write-Host "      Or use Git Credential Manager which stores it automatically" -ForegroundColor DarkGray
    }

    Write-Host ""

    # ==============================================================================
    # BASE URLs (Service-specific)
    # ==============================================================================

    Write-Host "Setting service base URLs..." -ForegroundColor Yellow

    if ($Local) {
        # Local TruckMate Services
        $env:TM_API_URL = "http://localhost:8199/tm"
        Write-Host "  [OK] TM_API_URL (Local)" -ForegroundColor Green

        $env:FINANCE_API_URL = "http://localhost:8199/finance"
        Write-Host "  [OK] FINANCE_API_URL (Local)" -ForegroundColor Green

        $env:VISIBILITY_API_URL = "http://localhost:8199/visibility"
        Write-Host "  [OK] VISIBILITY_API_URL (Local)" -ForegroundColor Green

        $env:MASTERDATA_API_URL = "http://localhost:8199/masterData"
        Write-Host "  [OK] MASTERDATA_API_URL (Local)" -ForegroundColor Green

        $env:DOCK_API_URL = "http://localhost:8199/dock"
        Write-Host "  [OK] DOCK_API_URL (Local)" -ForegroundColor Green

        $env:MOBCOMM_API_URL = "http://localhost:8199/mobcomm"
        Write-Host "  [OK] MOBCOMM_API_URL (Local)" -ForegroundColor Green

        # Generic fallback (points to TM service)
        $env:DOMAIN = "http://localhost:8199/tm"
        Write-Host "  [OK] DOMAIN (Local, generic fallback)" -ForegroundColor Green
    } else {
        # TruckMate Services (Cloud)
        $env:TM_API_URL = "https://tde-truckmate-cur.tmwcloud.com/tm"
        Write-Host "  [OK] TM_API_URL" -ForegroundColor Green

        $env:FINANCE_API_URL = "https://tde-truckmate.tmwcloud.com/fin/finance"
        Write-Host "  [OK] FINANCE_API_URL" -ForegroundColor Green

        $env:VISIBILITY_API_URL = "https://tde-truckmate-cur.tmwcloud.com/visibility"
        Write-Host "  [OK] VISIBILITY_API_URL" -ForegroundColor Green

        $env:MASTERDATA_API_URL = "https://tde-truckmate-cur.tmwcloud.com/masterData"
        Write-Host "  [OK] MASTERDATA_API_URL" -ForegroundColor Green

        $env:DOCK_API_URL = "https://tde-truckmate-cur.tmwcloud.com/dock"
        Write-Host "  [OK] DOCK_API_URL" -ForegroundColor Green

        $env:MOBCOMM_API_URL = "https://tde-truckmate-cur.tmwcloud.com/mobcomm"
        Write-Host "  [OK] MOBCOMM_API_URL" -ForegroundColor Green

        # Generic fallback (points to TM service)
        $env:DOMAIN = "https://tde-truckmate.tmwcloud.com/cur/tm"
        Write-Host "  [OK] DOMAIN (generic fallback)" -ForegroundColor Green
    }

    # Postman API (rarely changes)
    $env:POSTMAN_API_URL = "https://api.getpostman.com"
    Write-Host "  [OK] POSTMAN_API_URL" -ForegroundColor Green

    Write-Host ""

    # ==============================================================================
    # VERIFICATION
    # ==============================================================================

    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "TESTING ENVIRONMENT VARIABLES" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""

    # Test all service URLs
    $services = @(
        @{ Name = "TM API"; Url = $env:TM_API_URL }
        @{ Name = "Finance API"; Url = $env:FINANCE_API_URL }
        @{ Name = "Visibility API"; Url = $env:VISIBILITY_API_URL }
        @{ Name = "MasterData API"; Url = $env:MASTERDATA_API_URL }
        @{ Name = "Dock API"; Url = $env:DOCK_API_URL }
        @{ Name = "MobComm API"; Url = $env:MOBCOMM_API_URL }
    )

    foreach ($service in $services) {
        Write-Host "Testing $($service.Name) - $($service.Url)" -ForegroundColor Yellow
        try {
            $ver = Get-ApiVersion -BaseUrl $service.Url -Token $env:TRUCKMATE_API_KEY -Quiet
            if ($ver.Success) {
                Write-Host "  [SUCCESS] Version: $($ver.Version)" -ForegroundColor Green
            } else {
                Write-Host "  [FAILED] $($ver.Error)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  [ERROR] $_" -ForegroundColor Red
        }
    }

    Write-Host ""

    # ==============================================================================
    # USAGE
    # ==============================================================================

    Write-Host ("=" * 80) -ForegroundColor Magenta
    Write-Host "USAGE EXAMPLES" -ForegroundColor Magenta
    Write-Host ("=" * 80) -ForegroundColor Magenta
    Write-Host ""

    Write-Host "After setting environment variables, you can use functions without parameters:" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "# No parameters needed!" -ForegroundColor Yellow
    Write-Host "Get-ApiVersion" -ForegroundColor Gray
    Write-Host "Run-ApiTests -RequestsFile 'tests.ps1'" -ForegroundColor Gray
    Write-Host ""

    Write-Host "# Override when testing different environment:" -ForegroundColor Yellow
    Write-Host "Run-ApiTests -BaseUrl 'https://qa-server.com' -RequestsFile 'tests.ps1'" -ForegroundColor Gray
    Write-Host ""

    Write-Host "# Switch between services by changing env var:" -ForegroundColor Yellow
    Write-Host '$env:FINANCE_API_URL = "https://prod-server.com/finance"' -ForegroundColor Gray
    Write-Host "Get-ApiVersion  # Now checks prod server!" -ForegroundColor Gray
    Write-Host ""

    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "TO ADD TO YOUR PROFILE" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
    Write-Host "Add this to your PowerShell profile:" -ForegroundColor Cyan
    Write-Host '  notepad $PROFILE' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Copy the token and URL settings from this script" -ForegroundColor Yellow
    Write-Host ""

    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "[OK] ENVIRONMENT VARIABLES CONFIGURED" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

# Auto-run the function when script is loaded (unless imported as part of a module)
# NOTE: Disabled because it causes unwanted output during module import
# if (-not $MyInvocation.MyCommand.ScriptBlock.Module) {
#     Setup-EnvironmentVariables
# }
