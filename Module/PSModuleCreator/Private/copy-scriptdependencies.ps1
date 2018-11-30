<# 
 .SYNOPSIS 
 Copies dependencies to module folder 

.DESCRIPTION 
 Generates list of possible dependencies, asks user if they are dependencies, Copies them to module subfolder 

.PARAMETER ModuleName 
 string Parameter_ModuleName=ModuleName is a mandatory parameter of type String, The name of the Module 

.PARAMETER projectPath 
 string Parameter_projectPath=projectPath is a mandatory parameter of type String the path to the local git repo 

.NOTES 
 Author: Mentaleak 

#> 
function copy-scriptdependencies () {
 
	param(
		[Parameter(mandatory = $true)][string] $projectPath,
		[Parameter(mandatory = $true)][string] $ModuleName
	)
	#copies files

	$Filedependencies = Get-ChildItem $projectPath  -Exclude @("*.ps1","README.MD") -Recurse -File

	$Filedependencies = $Filedependencies | Where-Object { $_.FullName -notmatch [regex]::Escape("$($ProjectDirectory)\Module") }
	$Filedependencies = $Filedependencies | Where-Object { $_.FullName -notmatch [regex]::Escape("$($ProjectDirectory)\src\AutomatedModuleDocs") }
	$Filedependencies = $Filedependencies | Where-Object { $_.FullName -notmatch [regex]::Escape("$($ProjectDirectory)\src\Non-Dependent") }
	$Filedependencies = $Filedependencies | Where-Object { $_.FullName -notmatch [regex]::Escape("$($ProjectDirectory)\.git") }

	$Filedependencies = $Filedependencies | Out-GridView -Title "Select Files Which are dependencies" -PassThru

	$fdcount = 0
	foreach ($item in $Filedependencies) {
		$fdcount++
		Write-Progress -Status "Copying Script Dependencies" -Activity " " -PercentComplete (100 * ($fdcount / $Filedependencies.count))
		switch ($item.Extension)
		{
			{ @(".dll",".cab",".jar") -contains $_ } {
				Copy-Item -Path "$($item.FullName)" -Destination "$($projectPath)\Module\$($ModuleName)\Lib\"
			}
			{ @(".exe",".msi",".bin",".dat") -contains $_ } {
				Copy-Item -Path "$($item.FullName)" -Destination "$($projectPath)\Module\$($ModuleName)\Bin\"
			}
			default {
				Copy-Item -Path "$($item.FullName)" -Destination "$($projectPath)\Module\$($ModuleName)\Other-Dependencies\"
			}
		}
	}
	return $Filedependencies
}
