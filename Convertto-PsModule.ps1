# builds a PS Module
# requires PSGit
# requires PSTools

# testing
# $source="\\dutchess\support\Power Shell Scripts\Other\PSTools\PSTools.ps1"
# $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

function ConvertTo-PSModule () {
	param(
		[Parameter(mandatory = $true)] [string]$source,
		[string]$projectPath,
		[switch]$force
	)
	$SourceFile = (Get-Item $source)
	if (!$projectPath) {
		if ($SourceFile.Directory.Name -eq "src") {
			$projectPath = $SourceFile.Directory.Parent.FullName }
		else { $projectPath = $SourceFile.Directory.FullName }
	}
	if (test-GitLocal -ProjectPath $ProjectPath)
	{
		if ((Test-Path "$($projectPath)\Module") -and $force) {
			Import-Module "$((get-childitem "$($projectPath)\Module\")[0].FullName)"
			Get-ChildItem -Path "$($projectPath)\Module" -Recurse | Remove-Item -Force -Recurse
			Remove-Item "$($projectPath)\Module" -Force
		}
		if (Test-Path "$($projectPath)\Module") { Write-Error "Module Already Exists" }
		else {
			if (!(Test-GitAuth -nobreak)) {
				Connect-github
			}
			if (Test-GitAuth) {
				if (!(Test-Path "$($projectPath)\src")) {
					New-Item -ItemType directory -Path "$($projectPath)\src" | Out-Null
				}

				$userData = get-gituserdata

				#Write-Host "Test remote"
				if (test-GitRemote -ProjectPath $ProjectPath) {


					$RepoData = Get-GitRepo -ProjectPath $ProjectPath

					#ModuleName
					$ModuleName = $RepoData.Name

					#ModuleAuthors
					$authors = ($RepoData.contributors_stats | Format-Table -AutoSize | Out-String)


					#region required modules
					Write-Progress -Status "Getting Modules" -Activity "This will take a while" -PercentComplete (10)
					$availableModules = Get-Module -ListAvailable
					$requiredModules = @()
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
					foreach ($module in $SelectedModules) {
						$RequiredModules += [pscustomobject]@{ ModuleName = "$($module.Module)"
							ModuleVersion = "$($module.Version)"
							GUID = "$(($availableModules| where {$_.name -match $module.Module}).guid)" }
					}
					$RequiredModules = ($RequiredModules | Sort-Object -Property ModuleName | Get-Unique -AsString)
					#endregion

					#region ModuleVersion
					#$UpdateDate = $($RepoData.updated_at).split("T")[0].split("-")
					#$UpdateTime = $($RepoData.updated_at).split("T")[1].split(":")
					#$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2].split(`"Z`")[0])"
					$time = (Get-Date)
					$UpdateDate = @("$($time.year.ToString("0000"))","$($time.Month.ToString("00"))","$($time.day.ToString("00"))")
					$UpdateTime = @("$($time.Hour.ToString("00"))","$($time.Minute.ToString("00"))","$($time.second.ToString("00"))")
					$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2])"
					#endregion

					#region Function DataGatherer
					$functions = Get-functions_PSTool $source
					$functionDocumentation = @()

					$fncount = 0
					foreach ($fn in $functions) {
						$fncount++
						Write-Progress -Status "Gathering data on functions" -Activity "$($fn.name) $fncount / $($functions.count)" -PercentComplete (100 * ($fncount / $functions.count))
						try { $ExistingFnDoc = (Get-Help -Full "$($fn.name)")
							$fnTemp = [pscustomobject]@{
								Private = $false
								Synopsis = "$($ExistingFnDoc.synopsis) `n"
								Description = "$(($ExistingFnDoc.description.Text) -join "`n") `n"
								Notes = "$(try{($ExistingFnDoc.alertSet.alert.Text) -join "`n"}catch{$_|out-null}) `n"
								Example_A = "$($ExistingFnDoc.examples.example[0].code) $(try{($ExistingFnDoc.examples.example[0].remarks.Text) -join "`n"}catch{$_|out-null}) `n"
								Example_B = "$($ExistingFnDoc.examples.example[1].code) $(try{($ExistingFnDoc.examples.example[1].remarks.Text) -join "`n"}catch{$_|out-null}) `n"
								Example_C = "$($ExistingFnDoc.examples.example[2].code) $(try{($ExistingFnDoc.examples.example[2].remarks.Text) -join "`n"}catch{$_|out-null}) `n"
								Example_D = "$($ExistingFnDoc.examples.example[3].code) $(try{($ExistingFnDoc.examples.example[3].remarks.Text) -join "`n"}catch{$_|out-null}) `n"
							}
						}
						catch { Write-Progress -Status "$($fn.name)" -Activity "NO DATA FOUND" -PercentComplete (100 * ($fncount / $functions.count))
							$fnTemp = [pscustomobject]@{
								Private = $false
								Synopsis = "`n"
								Description = "`n"
								Notes = "`n"
								Example_A = "`n"
								Example_B = "`n"
								Example_C = "`n"
								Example_D = "`n"
							}
						}



						foreach ($parameter in ($fn.parameters.values -as [array])) {
							if (($fn.ResolveParameter("$($parameter.name)").Attributes.TransformNullOptionalParameters -eq "$true") -or ($fn.ResolveParameter("$($parameter.name)").parametersets.values.position -ne -2147483648))
							{
								$paramDescription = ""
								try { $paramDoc = ($ExistingFnDoc.parameters.parameter | Where-Object { $_.Name -eq "$($parameter.Name)" }).Description[0].text
									$paramDescription = $paramDoc
									if ($paramDescription -eq "") { Write-Error "No Parameter Data" }
								}
								catch { $paramDescription = "$($parameter.Name) "
									if ($parameter.parametersets.values.ismandatory) { $paramDescription += "is a mandatory parameter" } else { $paramDescription += "is a parameter" }
									$paramDescription += " of type $($parameter.ParameterType)"
								}
								Add-Member -InputObject $fnTemp -MemberType NoteProperty -Name "Parameter_$($parameter.name)" -Value $paramDescription
							}
						}
						$fnOBJ = Show-Psgui -Object $fnTemp -Title "$($fn.Name) $($fncount)/$($functions.count)" -showbreak
						if ($fnOBJ) {
							Add-Member -InputObject $fnOBJ -MemberType NoteProperty -Name "Name" -Value ($fn.Name)
							Add-Member -InputObject $fnOBJ -MemberType NoteProperty -Name "FunctionData" -Value ($fn)
						}


						# $fnOBJ = New-Object PsObject
						#     $fnTemp.psobject.properties | % {
						#         $fnOBJ | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
						#   }
						if ($fnOBJ -eq "Cancel All") {
							break
						}
						elseif ($fnOBJ)
						{
							$functionDocumentation += $fnOBJ
						}
					}
					#endregion

					#region make directory for module
					New-Item -ItemType directory -Path "$($projectPath)\Module" | Out-Null
					New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)" | Out-Null
					New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Private" | Out-Null
					New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\Public" | Out-Null
					New-Item -ItemType directory -Path "$($projectPath)\Module\$($ModuleName)\en-US" | Out-Null



					#endregion

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
					$readmemd = new-ReadMeMD $functionDocumentation
					$readmemd | Out-File -FilePath "$($projectPath)\Module\$($ModuleName)\README.MD" -Encoding utf8
					$functionDocumentation | Export-Clixml -Path "$($projectPath)\src\documentation.xml"
					#endregion

					#region Make Module Manifest
					New-ModuleManifest -Path "$($projectPath)\Module\$($ModuleName)\$($ModuleName).psd1" `
 						-RootModule "$($ModuleName).psm1" `
 						-Description $RepoData.Description `
 						-Author $authors `
 						-ModuleVersion $ModuleVersion `
 						-HelpInfoUri $RepoData.html_url `
 						-PowerShellVersion "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" `
 						-Copyright "(c) $($UpdateDate[0]) $($RepoData.owner.login). All rights reserved." `
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

					Add-GitAutoCommitPush $projectPath
					add-GitRelease -RepoFullName "$($RepoData.full_name)" -TagName "$($ModuleVersion)" -Name "Module Release $ModuleVersion" -Body $readmemd.Replace("`n","\r") | Out-Null
				}
			}
		}
	}

}



function New-functionDoc () {
	param(
		[Parameter(mandatory = $true)] $functionData
	)
	## .EXTERNALHELP UpdateOneGet.psm1-help.xml
	$functionhelp = "<# `n "
	if ($functionData.Synopsis -and $functionData.Synopsis -ne "`n") { $FunctionHelp += ".SYNOPSIS `n $(($functionData.synopsis.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Description -and $functionData.Description -ne "`n") { $FunctionHelp += ".DESCRIPTION `n $(($functionData.description.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	$parameters = $functiondata | Get-Member | Where-Object { $_.Name -match "Parameter" }
	foreach ($param in $parameters)
	{
		$FunctionHelp += ".PARAMETER $($param.Name.Split("_")[1]) `n $(($param.Definition.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n"
	}
	if ($functionData.Example_A -ne "`n" -and $functionData.Example_A) { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_A.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Example_B -ne "`n" -and $functionData.Example_B) { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_B.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Example_C -ne "`n" -and $functionData.Example_C) { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_C.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Example_D -ne "`n" -and $functionData.Example_D) { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_D.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Notes -and $functionData.Notes -ne "`n") { $FunctionHelp += ".NOTES `n $(($functionData.Notes.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	$FunctionHelp += "#>    `n"

	#function Code
	$functionCode = "function $($functionData.name) () {`n "
	$functionCode += $($functionData.FunctionData.Definition)
	$functionCode += "}"

	$functionString = $functionhelp
	$functionString += "`n"
	$functionString += $functionCode

	return $functionString
}



function new-ReadMeMD () {
	param(
		[Parameter(mandatory = $true)] $functiondocumentation
	)
	$readmeMD = ""
	foreach ($fn in $functiondocumentation) {
		$readmeMD += "# $($fn.Name) `n"
		$readmeMD += "$($fn.Synopsis) `n"
		$readmeMD += "--- `n"
	}

	return $readmeMD
}

<# 
# RootModule = ''

# Author of this moduleAuthor = 'User01'

# Description of the functionality provided by this module
# Description = ''

# Version number of this module.ModuleVersion = '1.0'

# HelpInfo URI of this module
# HelpInfoURI = '

# Copyright statement for this moduleCopyright = '(c) 2012 User01. All rights reserved.'

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = ''

# Company or vendor of this moduleCompanyName = 'Unknown'

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# ID used to uniquely identify this moduleGUID = 'd0a9150d-b6a4-4b17-a325-e3a24fed0aa9' (AUTOGEN)





N/a
-FormatsToProcess "$($ModuleName).Format.ps1xml" `


# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()



#>













# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this moduleFunctionsToExport = '*'

# Cmdlets to export from this moduleCmdletsToExport = '*'
# Variables to export from this moduleVariablesToExport = '*'
# Aliases to export from this moduleAliasesToExport = '*'

# List of all modules packaged with this module# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''}
