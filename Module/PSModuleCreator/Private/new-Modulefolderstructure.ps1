<# 
 .SYNOPSIS 
 Makes a folder structure in Repo for repo src and module 

.DESCRIPTION 
 Makes a folder structure in Repo for repo src and module 

.PARAMETER modulename 
 string Parameter_modulename=modulename is a mandatory parameter of type String, name of module 

.PARAMETER projectPath 
 string Parameter_projectPath=projectPath is a mandatory parameter of type String, path to project 

.NOTES 
 Author: Mentaleak 

#> 
function new-Modulefolderstructure () {
 
	param(
		[Parameter(mandatory = $true)][string] $projectPath,
		[Parameter(mandatory = $true)][string] $modulename
	)
	if (!(Test-Path "$($projectPath)\src")) {
		New-Item -ItemType directory -Path "$($projectPath)\src" | Out-Null
	} if (!(Test-Path "$($projectPath)\src\AutomatedModuleDocs")) {
		New-Item -ItemType directory -Path "$($projectPath)\src\AutomatedModuleDocs" | Out-Null
	}
	New-Item -ItemType directory -Path "$($projectPath)\Module" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Private" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Public" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\en-US" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Bin" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Lib" | Out-Null
	New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Other-Dependencies" | Out-Null
}
