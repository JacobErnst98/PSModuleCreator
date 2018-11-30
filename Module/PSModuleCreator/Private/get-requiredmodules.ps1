<# 
 .SYNOPSIS 
 Gets the modules found to be used in script. 

.DESCRIPTION 
 Gets the modules found to be used in script. Asks user if they are valid 

.PARAMETER modulename 
 string Parameter_modulename=modulename is a mandatory parameter of type String, name of module 

.PARAMETER source 
 string Parameter_source=source is a mandatory parameter of type String, source file of script to interrogate 

.NOTES 
 Author: Mentaleak 

#> 
function get-requiredmodules () {
 
	param(
		[Parameter(mandatory = $true)][String] $source,
		[Parameter(mandatory = $true)][String] $modulename
	)

	#Write-Progress -Status "Getting Modules" -Activity "This will take a while" -PercentComplete (10)
	#$availableModules = Get-Module -ListAvailable
	
	$FoundModules = get-usedCommands_PSTool $source
	$Gmodules = $FoundModules.GoodCommands | Where-Object { $_.Module -ne $ModuleName }
	$Mmodules = $FoundModules.MehCommands
	if ($Gmodules) {
		$Confirmation = [System.Windows.MessageBox]::Show("Please select modules used in your script from the following list of suspected valid modules.",'Select Modules','ok','Information')
		$SelectedModules = $Gmodules | Out-GridView -Title "Select Modules: Suspected Good, Press cancel for none" -PassThru
	}
	if ($Mmodules) {
		$Confirmation = [System.Windows.MessageBox]::Show("Please select modules used in your script from the following list of suspected false positives",'Select Modules','ok','Information')
		$SelectedModules += $Mmodules | Out-GridView -Title "Select Modules: Suspected False Positives, Press cancel for none" -PassThru
	}
    $requiredModules = @()
	foreach ($module in $SelectedModules) {
		$RequiredModules += @{ ModuleName = "$($module.Module)"
			ModuleVersion = "$($module.Version)"
			GUID = "$((get-module "$($module.Module)").guid)" }
    }
	#$ModuleNames = ($SelectedModules.Module | Sort| Get-Unique -AsString)

	return $RequiredModules
}
