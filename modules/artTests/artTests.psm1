###  I have made main module PSM1 file a pointer to other folders + a to-do list of ideas.

$ThisScriptRoot = $PSScriptRoot

# Set module home directory for use by functions
# Functions can reference this to find resources relative to the module root
$global:ArtTestsModuleRoot = $PSScriptRoot

#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $ThisScriptRoot\*.Public.ps1 -recurse )# -ErrorAction SilentlyContinue )
       
#Dot source the files
    
	#Foreach($import in @($Public + $Private))
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

##############################################

<# To-do list

#idea - check a given database to look for custom code.

#idea - d83 analyzer ... is the test data config/assumption ok?  (e.g. pass me a DLID .. i will check it out against known D83 rating success requirements.)

##powersehl idea
#check driver contracts ... do they have contract, is it effective date ok?, what about in paycon ...does it show there (active) ... lots of system maintenacne stuff
#cardmgmt ... setup .. comm 'test' doesn't even complain if the card mgmt component is not setup in com+

#secutiry bevents ... ok, if i have sql accesss .. does that eliminate security?

#This user does not have permission to perform this task

#SNoPermission = 'This user does not have permission to perform this task.';


#PS C:\Users\dbatchelor\Documents\scripting\modules\cases> (get-command Search-TMTableNames).Definition


#Hmm, if i can't install module remotely to run my scripts.

#Maybe i need to give my commands an option to output the SQL they were going to run ? so i can copy & paste into sqlexec
# e.g. -outputSQL

#>

