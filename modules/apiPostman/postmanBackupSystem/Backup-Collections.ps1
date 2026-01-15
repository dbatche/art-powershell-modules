<#
.SYNOPSIS
    Runs the Postman "Backup Runner" collection via Postman CLI.

.DESCRIPTION
    This is a standalone helper script (NOT auto-loaded by the `apiPostman` PowerShell module).
    It exists as a quick wrapper around the Postman CLI command:
        postman collection run <collectionId> -e <environmentId>

    Why it is not named *.Public.ps1:
    - `apiPostman.psm1` dot-sources every `*.Public.ps1` at import time.
    - This script runs a Postman CLI command and should only run when you execute it explicitly.

.PREREQUISITES
    - Postman CLI installed and available on PATH as `postman`
    - Access to the referenced Postman collection/environment (and any required auth)

.EXAMPLE
    pwsh .\postmanBackupSystem\Backup-Collections.ps1

.EXAMPLE
    # If you want to edit IDs, update the variables at the top of this file.
#>

$backupRunnerCollection = "2332132-fdd6be92-cea2-4421-8109-0bcd3724ae20"
$backupRunnerEnvironment = "2332132-8d882001-d4b6-4c4d-ab14-e3fac66252ec"

postman collection run $backupRunnerCollection -e $backupRunnerEnvironment

