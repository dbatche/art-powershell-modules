#################### Dynamic load of PS1 files in module folder
$ThisScriptRoot = $PSScriptRoot

#Get public and private function definition files.
    #$Public  = @( Get-ChildItem -Path $ThisScriptRoot\Public\*.ps1 -Recurse )# -ErrorAction SilentlyContinue )
    $Public  = @( Get-ChildItem -Path $ThisScriptRoot\*.Public.ps1 -Recurse )# -ErrorAction SilentlyContinue )
   
#Dot source the files
    
	Foreach($import in @($Public))
	{
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }
####################