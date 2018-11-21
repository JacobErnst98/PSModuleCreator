# builds a PS Module
# requires PSGit
# requires PSTools

# testing
# $source="\\dutchess\support\Power Shell Scripts\Other\PSGit\PSGit.ps1"
#$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

function ConvertTo-PSModule () {
	param(
		[Parameter(mandatory = $true)] [string]$source
	)
	if (!(Test-GitAuth -nobreak)) {
		Connect-github
	}
	if (Test-GitAuth) {
		$SourceFile = (Get-Item $source)
		$ProjectPath = (Get-Item $source).Directory.FullName
		$userData = get-gituserdata

		#Write-Host "Test Local"
		if (test-GitLocal -ProjectPath $ProjectPath) {
			#Write-Host "Test remote"
			if (test-GitRemote -ProjectPath $ProjectPath) {
				$RepoData = Get-GitRepo -ProjectPath $ProjectPath

				#ModuleName
				$ModuleName = $RepoData.Name

				#ModuleAuthors
				$authors = ($RepoData.contributors_stats | Format-Table -AutoSize | Out-String)


				#region required modules
				$availableModules = Get-Module -ListAvailable
				$requiredModules = @()
				$FoundModules = get-PSTool_usedCommands $source
				$Confirmation = [System.Windows.MessageBox]::Show("Please select modules used in your script from the following lists.The first list will be suspected valid modules.",'Select Modules','ok','Information')
				$SelectedModules = $FoundModules.GoodCommands | Out-GridView -Title "Select Modules: Suspected Good, Press cancel for none" -PassThru
				$Confirmation = [System.Windows.MessageBox]::Show("Please select modules used in your script from the following lists.`nThe second list will be suspected false positives",'Select Modules','ok','Information')
				$SelectedModules += $FoundModules.MehCommands | Out-GridView -Title "Select Modules: Suspected False Positives, Press cancel for none" -PassThru
				foreach ($module in $SelectedModules) {
					$RequiredModules += [pscustomobject]@{ ModuleName = "$($module.Module)"
						ModuleVersion = "$($module.Version)"
						GUID = "$(($availableModules| where {$_.name -match $module.Module}).guid)" }
				}
				$RequiredModules = ($RequiredModules | Sort-Object -Property ModuleName | Get-Unique -AsString)
				#endregion

				#region ModuleVersion
				$UpdateDate = $($RepoData.updated_at).split("T")[0].split("-")
				$UpdateTime = $($RepoData.updated_at).split("T")[1].split(":")
				$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2].split(`"Z`")[0])"
				#endregion

				#region Function DataGatherer
				$functions = Get-PSTool_functions $source
				$functionDocumentation = @()

				$fncount = 0
				foreach ($fn in $functions) {
					$fncount++
					$fnTemp = [pscustomobject]@{
						Private = [boolean]
						Synopsis = "`n"
						Description = "`n"
						Notes = "`n"
						Example_A = "`n"
						Example_B = "`n"
						Example_C = "`n"
						Example_D = "`n"
					}
					foreach ($parameter in ($fn.parameters.values -as [array])) {
						if ($fn.ResolveParameter("$($parameter.name)").parametersets.values.position -ne -2147483648)
						{
							$paramDescription = "$($parameter.Name) "
							if ($parameter.parametersets.values.ismandatory) { $paramDescription += "is a mandatory parameter" } else { $paramDescription += "is a parameter" }
							$paramDescription += " of type $($parameter.ParameterType)"
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
				New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module" |out-null
				New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)" |out-null
				New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Private" |out-null
				New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Public" |out-null
				New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\en-US" |out-null
				#endregion

                #region export function files
                $filelist=@("$($ModuleName).psd1","$($ModuleName).psm1")
                $functionDocumentation |foreach{
                    $fnDoc=New-functionDoc $_
                    if($_.Private){
                    $fnDoc | out-file "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Private\$($_.name).ps1"
                    }
                    else{
                    $fnDoc | out-file "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Public\$($_.name).ps1"
                    }
                    $filelist+="$($_.name).ps1"
                }
                #endregion

                #region make PSM1
                $psm1File = Get-Content "$($PSScriptRoot)\PSMC_PSM1_template.psm1" 
                $psm1File= $psm1File.Replace("<#{.ModuleName.}#>","$($ModuleName)")
                $psm1File= $psm1File.Replace("<#{.PSVersionREQ.}#>","$($PSVersionTable.PSVersion.Major)")
                 $psm1File |out-file "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\$($ModuleName).psm1" 
                #endregion


				#region Make Module Manifest
				New-ModuleManifest -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\$($ModuleName).psd1" `
 					-RootModule $ModuleName.psm1 `
 					-Description $RepoData.Description `
 					-Author $authors `
 					-ModuleVersion $ModuleVersion `
 					-HelpInfoUri $RepoData.html_url `
 					-PowerShellVersion "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" `
 					-Copyright "(c) $($UpdateDate[0]) $($RepoData.owner.login). All rights reserved." `
 					-CompanyName "$($RepoData.owner.login)" `
 					-RequiredModules $RequiredModules `
 					-FormatsToProcess "$($ModuleName).Format.ps1xml" `
                    -FileList $filelist
                $psd1File = Get-Content "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\$($ModuleName).psd1" 
                $indexOfGeneratedBy=$psd1File.IndexOf("# Generated by: ")
                $psd1File[$indexOfGeneratedBy]= "# Generated by: https://github.com/Mentaleak/PSModuleCreator"
                $GeneratedWipeCount=($indexOfGeneratedBy+1)
                While($psd1File[$GeneratedWipeCount] -ne "#"){
                    #write-host "$GeneratedWipeCount :: $($psd1File[$GeneratedWipeCount])"
                    $psd1File[$GeneratedWipeCount]=""
                    $GeneratedWipeCount++
                }
                $psd1File |Out-File -FilePath "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\$($ModuleName).psd1"

				#endregion
			}
		}
	}
}



function New-functionDoc(){
    param(
        [Parameter(mandatory = $true)]$functionData
    )
    $functionString="function $($functionData.name) () {`n <# `n "
    if($functionData.synopsis -and $functionData.synopsis -ne "`n"){$functionString+=".SYNOPSIS `n $($functionData.synopsis.trim()) `n`n"}
    if($functionData.description -and $functionData.description -ne "`n"){$functionString+=".DESCRIPTION `n $($functionData.description.trim()) `n`n"}
    $parameters = $functiondata |get-member |Where-Object {$_.name -match "Parameter"}
    foreach($param in $parameters)
    {
        $functionString+=".PARAMETER $($param.Name.Split("_")[1]) `n $($parameters.Definition.trim()) `n`n"
    }
    if($functionData.Example_A -ne "`n" -and $functionData.Example_A){$functionString+=".Example `n $($functionData.Example_A.trim()) `n`n"}
    if($functionData.Example_B -ne "`n" -and $functionData.Example_B){$functionString+=".Example `n $($functionData.Example_B.trim()) `n`n"}
    if($functionData.Example_C -ne "`n" -and $functionData.Example_c){$functionString+=".Example `n $($functionData.Example_C.trim()) `n`n"}
    if($functionData.Example_D -ne "`n" -and $functionData.Example_D){$functionString+=".Example `n $($functionData.Example_D.trim()) `n`n"}
    if($functionData.Notes -and $functionData.notes -ne "`n"){$functionString+=".NOTES `n $($functionData.Notes.trim()) `n`n"}
    $functionString+="#>    `n"
    $functionString+=$($functionData.FunctionData.Definition)
    $functionString+="}"

    return $functionString
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
