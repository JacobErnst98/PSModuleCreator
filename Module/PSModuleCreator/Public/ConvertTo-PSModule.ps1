<# 
 .SYNOPSIS 
 Converts a functionized single file script into a module 

.DESCRIPTION 
 Converts a linear functionized script into a module; it requires and uses data from the Git repo for it. 

.PARAMETER force 
 string Parameter_force=force is a parameter of type switch, will delete an existing module instance if one exists 

.PARAMETER installWhenFinished 
 string Parameter_installWhenFinished=installWhenFinished is a parameter of type switch, will install the finished module after conversion 

.PARAMETER projectPath 
 string Parameter_projectPath=projectPath is a parameter of type string, path to project, will be automatically assumed if not manually set 

.PARAMETER push 
 string Parameter_push=push is a parameter of type switch, Pushes an update to Github 

.PARAMETER release 
 string Parameter_release=release is a parameter of type switch, will push a release to github 

.PARAMETER source 
 string Parameter_source=source is a mandatory parameter of type string, the source file of the functionized code 

.PARAMETER UseExistingDocs 
 string Parameter_UseExistingDocs=UseExistingDocs is a parameter of type switch, will use existing documentation if possible 

.EXAMPLE 
 ConvertTo-PSModule -source $source -force
Will create a module from the $source file assuming its in a local git repo 

.NOTES 
 Author: Mentaleak 

#> 
function ConvertTo-PSModule () {
 
	param(
		[Parameter(mandatory = $true)] [string]$source,
		[string]$projectPath,
		[switch]$force,
		[switch]$release,
		[switch]$installWhenFinished,
        [switch]$push,
        [switch]$UseExistingDocs
	)
	$SourceFile = (Get-Item $source)
	if (!$projectPath) {
		if ($SourceFile.Directory.Name -eq "src") {
			$projectPath = $SourceFile.Directory.Parent.FullName }
		else { $projectPath = $SourceFile.Directory.FullName }
    	}
    $projectdirectory = get-item $projectPath
	if (test-GitLocal -ProjectPath $ProjectPath)
	{
		if ((Test-Path "$($projectPath)\Module") -and $force) {
            if((Test-Path "$($projectPath)\Module\$($projectdirectory.Name)\$($projectdirectory.Name).psd1")){
			    Import-Module "$($projectPath)\Module\$($projectdirectory.Name)"
            }
			Get-ChildItem -Path "$($projectPath)\Module" -Recurse | Remove-Item -Force -Recurse
			Remove-Item "$($projectPath)\Module" -Force
		}
		if (Test-Path "$($projectPath)\Module") { Write-Error "Module Already Exists" }
		else {
			if (!(Test-GitAuth -nobreak)) {
				Connect-github
			}
			if (Test-GitAuth) {

				$userData = get-gituserdata

				#Write-Host "Test remote"
				if (test-GitRemote -ProjectPath $ProjectPath) {


					$RepoData = Get-GitRepo -ProjectPath $ProjectPath

					#ModuleName
					$ModuleName = $RepoData.Name

					#ModuleAuthors
					$authors = ($RepoData.contributors_stats | Format-Table -AutoSize | Out-String)

					#region make directory for module
					new-Modulefolderstructure -ModuleName $ModuleName -ProjectPath $projectPath
					#endregion

					#region required modules
					$RequiredModules = get-requiredmodules -Source $source -ModuleName $ModuleName
					#endregion

					#region ModuleVersion
					$moduleVersion = get-ModuleVersion
					#endregion

					#region Function DataGatherer
					$functionDocumentation = get-functionDocumentation -Source $source -DocFolder "$($projectPath)\src\AutomatedModuleDocs"
					#endregion


					#Move File Dependencies
					if (!($ManuallyMoveDependencies)) {
						$scriptdependencies = copy-scriptdependencies -ModuleName $ModuleName -ProjectPath $projectPath 
                        # -ProjectDirectory $($SourceFile.Directory.Parent.FullName)
						if ($scriptdependencies) {
							$functionDocumentation = Update-moduleCode -functionDocumentation $functionDocumentation -Filedependencies $scriptdependencies -ProjectDirectory $projectPath
						}
					}



					#region export function files
					$filelist = @("$($ModuleName).psd1","$($ModuleName).psm1")
					$functionDocumentation | ForEach-Object {
						$fnDoc = New-functionDoc $_

						if ($_.Private) {
							$fnDoc | Out-File "$($projectPath)\Module\$($ModuleName)\Private\$($_.name).ps1"
						}
						else {
							$fnDoc | Out-File "$($projectPath)\Module\$($ModuleName)\Public\$($_.name).ps1"
						}
						$filelist += "$($_.name).ps1"
					}
					#endregion

					#region make PSM1
					$psm1File = Get-Content "$($PSScriptRoot)\PSMC_PSM1_template.psm1"
					$psm1File = $psm1File.Replace("<#{.ModuleName.}#>","$($ModuleName)")
					$psm1File = $psm1File.Replace("<#{.PSVersionREQ.}#>","$($PSVersionTable.PSVersion.Major)")
					$psm1File | Out-File "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psm1"
					$functionDocumentation | Where-Object { $_.Private -eq $false } | ForEach-Object { ". `$PSScriptRoot\public\$($_.name ).ps1" | Out-File -Append "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psm1" }
					$functionDocumentation | Where-Object { $_.Private -eq $true } | ForEach-Object { ". `$PSScriptRoot\private\$($_.name ).ps1" | Out-File -Append "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psm1" }
					$functionDocumentation | ForEach-Object { "Export-ModuleMember $($_.name )" | Out-File -Append "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psm1" }

					#endregion

					#region make .md file, and docxml
					$readmemd = format-DocumentationReadMeMD $functionDocumentation
					$readmemd | Out-File -FilePath "$($projectPath)\Module\$($ModuleName)\README.MD" -Encoding utf8
					$functionDocumentation | Export-Clixml -Path "$($projectPath)\src\AutomatedModuleDocs\MAIN.xml"
					#endregion

					#region Make Module Manifest
					New-ModuleManifest -Path "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psd1" `
 						-RootModule "$($ModuleName).psm1" `
 						-Description $RepoData.Description `
 						-Author $authors `
 						-ModuleVersion $ModuleVersion `
 						-HelpInfoUri $RepoData.html_url `
 						-PowerShellVersion "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" `
 						-Copyright "(c) $((get-date).Year) $($RepoData.owner.login). All rights reserved." `
 						-CompanyName "$($RepoData.owner.login)" `
 						-RequiredModules $RequiredModules `
 						-FunctionsToExport $($functionDocumentation | Where-Object { $_.Private -eq $false }).Name `
 						-FileList $filelist

					$psd1File = Get-Content "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psd1"
					$indexOfGeneratedBy = $psd1File.IndexOf("# Generated by: ")
					$psd1File[$indexOfGeneratedBy] = "# Generated by: https://github.com/Mentaleak/PSModuleCreator"
					$GeneratedWipeCount = ($indexOfGeneratedBy + 1)
					while ($psd1File[$GeneratedWipeCount] -ne "#") {
						#write-host "$GeneratedWipeCount :: $($psd1File[$GeneratedWipeCount])"
						$psd1File[$GeneratedWipeCount] = ""
						$GeneratedWipeCount++
					}
					$psd1File | Out-File -FilePath "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psd1"

					#endregion




					if ($release) {
						Add-GitAutoCommitPush $projectPath
						add-GitRelease -RepoFullName "$($RepoData.full_name)" -TagName "$($ModuleVersion)" -Name "Module Release $ModuleVersion" -Body $readmemd.Replace("`n","\r") | Out-Null
					}
					elseif ($push -and !($release)) {
						Add-GitAutoCommitPush $projectPath
					}

					if ($installWhenFinished) {
						$psModulePath = "$($env:USERPROFILE)\MY Documents\windowspowershell\Modules"
						if (Test-Path "$($psModulePath)\$($ModuleName)") {
							Get-ChildItem -Path "$($psModulePath)\$($ModuleName)" -Recurse | Remove-Item -Force -Recurse
							Remove-Item "$($psModulePath)\$($ModuleName)" -Force
						}
						Copy-Item -Path "$($projectPath)\Module\$($ModuleName)" -Destination "$($psModulePath)\" -Force -Recurse
						Import-Module $ModuleName
					}



				}
			}
		}
	}
[System.Windows.MessageBox]::Show("Module Created, please move any source files to the src folder.",'Move Source Files','ok','Information')
		
}
