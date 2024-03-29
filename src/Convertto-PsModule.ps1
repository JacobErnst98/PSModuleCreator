function ConvertTo-PSModule () {
Add-Type -AssemblyName System.Windows.Forms

	param(
		[Parameter(mandatory = $true)] [string]$source,
		[string]$projectPath,
		[switch]$force,
		[switch]$release,
		[switch]$installWhenFinished,
        [switch]$push,
        [switch]$UseExistingDocs,
        [switch]$newGuid
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

                    if(test-path "$($projectPath)\src\AutomatedModuleDocs\MAIN.psd1")
                    {
                        $existingModuleData=Import-PowershellDataFile "$($projectPath)\src\AutomatedModuleDocs\MAIN.psd1"
                    }
                    
                    if($newGuid){
                        $guid=(New-Guid).Guid
                    }
                    elseif($existingModuleData){
                        $guid=$existingModuleData.guid
                    }else{
                        $guid=(New-Guid).Guid
                    }

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
							$functionDocumentation = Update-moduleCode -functionDocumentation $functionDocumentation -Filedependencies $scriptdependencies -SourceDirectory $($SourceFile.Directory.FullName)
                            # -ProjectDirectory $projectPath
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
                        -Guid "$guid" `
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
                    $psd1File | Out-File -FilePath "$($projectPath)\src\AutomatedModuleDocs\MAIN.psd1"
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

function copy-scriptdependencies () {
Add-Type -AssemblyName System.Windows.Forms
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
    Write-Progress -Status "Copying Script Dependencies" -Activity " " -Completed
	return $Filedependencies
}

function Update-moduleCode () {
Add-Type -AssemblyName System.Windows.Forms
	param(
		[Parameter(mandatory = $true)] $functionDocumentation,
		[Parameter(mandatory = $true)] $Filedependencies,
		#[Parameter(mandatory = $true)][string] $ProjectDirectory,
        [Parameter(mandatory = $true)][string] $SourceDirectory

	)
	$suspectedCodeChanges = @()
	foreach ($item in $Filedependencies) {
		foreach ($fn in $functionDocumentation) {
			$linecount = 0
			$fndefarr = $fn.Definition.split("`n")
			foreach ($line in $fndefarr) {
				#LOADING BAR
				Write-Progress -Status "Looking into changing code" -Activity "$($item.name): $($fn.name): $linecount / $(($fndefarr.count)-1)" -PercentComplete (100 * ($linecount / $fndefarr.count))
				$lmatch = $item.FullName.Replace($SourceDirectory,"")
				if ($line -match [regex]::Escape($lmatch)) {
#FIX NOT REPLACING LINES IF SOURCE IS IN SRC FOLDER
					switch ($item.Extension)
					{
						{ @(".dll",".cab",".jar") -contains $_ } {
							$Nline = $line.Replace($($item.FullName.Replace($SourceDirectory,"")),"\..\Lib\$($item.name)")
						}
						{ @(".exe",".msi",".bin",".dat") -contains $_ } {
							$Nline = $line.Replace($($item.FullName.Replace($SourceDirectory,"")),"\..\Bin\$($item.name)")
						}
						default {
							$Nline = $line.Replace($($item.FullName.Replace($SourceDirectory,"")),"\..\Other-Dependencies\$($item.name)")
						}
					}

					$suspectedCodeChanges += [pscustomobject]@{
						FN_Name = $fn.Name
						Item_Name = $item.Name
						O_line = $line
						N_line = $Nline
						line_Num = $linecount
					}
                    Write-Verbose "$line to $nline"
				}
				$linecount++
			}

		}
	}
	if ($suspectedCodeChanges) {

		$Confirmation = [System.Windows.MessageBox]::Show("Please select the lines you would Like updated",'Select Lines to update','ok','Information')
		$CodeChanges = $suspectedCodeChanges | Out-GridView -Title "Select Lines to update, Press cancel for none" -PassThru
		foreach ($CodeChange in $CodeChanges) {
            Write-Verbose "Function $($CodeChange.FN_name): Changing line $($CodeChange.line_Num) "
            Write-Verbose "$($CodeChange.O_line) ::: $($CodeChange.N_line)"
			$fn = ($functionDocumentation | Where-Object { $_.Name -eq "$($CodeChange.FN_name)" })
			$fndef = $fn.Definition.split("`n")
			$fndef[$CodeChange.line_Num] = $Nline
			$fn.Definition = $fndef
		}
	}
    Write-Progress -Status "Looking into changing code" -Activity "$($item.name): $($fn.name): $linecount / $(($fndefarr.count)-1)" -Completed
	return $functionDocumentation
}

function new-Modulefolderstructure () {
Add-Type -AssemblyName System.Windows.Forms
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

function get-functionDocumentation () {
Add-Type -AssemblyName System.Windows.Forms
	param(
		[Parameter(mandatory = $true)][string] $source,
		[string]$DocFolder
	)
	$functions = Get-functions_PSTool $source
	$functionDocumentation = @()

	$fncount = 0
	foreach ($fn in $functions) {
        $ExistingFnDoc=$null
		$fncount++
		Write-Progress -Status "Gathering data on functions" -Activity "$($fn.name) $fncount / $($functions.count)" -PercentComplete (100 * ($fncount / $functions.count))
        if(Test-Path "$($DocFolder)/$($fn.name)_DOC.xml"){

            $ExistingFnDoc = Import-Clixml "$($DocFolder)/$($fn.name)_DOC.xml"
            $fnTemp = [pscustomobject]@{
				Private = $ExistingFnDoc.private
				Synopsis = "$($ExistingFnDoc.synopsis) `n"
				Description = "$($ExistingFnDoc.description) `n"
				Notes = "$($ExistingFnDoc.Notes)`n"
				Example_A = "$($ExistingFnDoc.Example_A)`n"
				Example_B = "$($ExistingFnDoc.Example_B)`n"
				Example_C = "$($ExistingFnDoc.Example_C)`n"
				Example_D = "$($ExistingFnDoc.Example_D)`n"
			}
            foreach ($parameter in ($fn.parameters.values -as [array])) {
			    if (($fn.ResolveParameter("$($parameter.name)").Attributes.TransformNullOptionalParameters -eq "$true") -or ($fn.ResolveParameter("$($parameter.name)").parametersets.values.position -ne -2147483648))
			    {
                Write-Verbose "Investigating Parameter: $($parameter.name)"
				    $paramDescription = ""
				     $paramDoc = $ExistingFnDoc."Parameter_$($parameter.name)"
                        $paramDescription = $paramDoc
					    if ($paramDescription -eq "" -or $paramDescription -eq $null) {  
				    
				     $paramDescription = "$($parameter.Name) "
					    if ($parameter.parametersets.values.ismandatory) { $paramDescription += "is a mandatory parameter" } else { $paramDescription += "is a parameter" }
					    $paramDescription += " of type $($parameter.ParameterType)"
				    }
                    Write-Verbose "Parameter $($parameter.name) Descirption: $($paramDescription)"
				    Add-Member -InputObject $fnTemp -MemberType NoteProperty -Name "Parameter_$($parameter.name)" -Value $paramDescription
			    }


            }
        }
        else{
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
            $ExistingFnDoc=$null
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
        }
        if(!($UseExistingDocs) -or !($ExistingFnDoc)){
		    $fnOBJ = Show-Psgui -Object $fnTemp -Title "$($fn.Name) $($fncount)/$($functions.count)" -showbreak
        }
        else{
            $fnOBJ=$fnTemp
        }
		if ($fnOBJ) {
			Add-Member -InputObject $fnOBJ -MemberType NoteProperty -Name "Name" -Value ($fn.Name)
			Add-Member -InputObject $fnOBJ -MemberType NoteProperty -Name "FunctionData" -Value ($fn)
			Add-Member -InputObject $fnOBJ -MemberType NoteProperty -Name "Definition" -Value ($fn.Definition)
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
			if ($DocFolder) { $fnOBJ | Export-Clixml "$($DocFolder)/$($fnOBJ.name)_DOC.xml" }
			$functionDocumentation += $fnOBJ
		}
}

    Write-Progress -Status "$($fn.name)" -Activity "NO DATA FOUND" -Completed
	return $functionDocumentation
}

function get-ModuleVersion () {
Add-Type -AssemblyName System.Windows.Forms
	#$UpdateDate = $($RepoData.updated_at).split("T")[0].split("-")
	#$UpdateTime = $($RepoData.updated_at).split("T")[1].split(":")
	#$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2].split(`"Z`")[0])"
	$time = (Get-Date)
	$UpdateDate = @("$($time.year.ToString("0000"))","$($time.Month.ToString("00"))","$($time.day.ToString("00"))")
	$UpdateTime = @("$($time.Hour.ToString("00"))","$($time.Minute.ToString("00"))","$($time.second.ToString("00"))")
	$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2])"

	return $moduleVersion
}

function get-requiredmodules () {
Add-Type -AssemblyName System.Windows.Forms
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
    $UniqueModules=$SelectedModules | select -Property module,version |Sort-Object -Property Module | Get-Unique -AsString
	foreach ($module in $UniqueModules) {
		$RequiredModules += @{ ModuleName = "$($module.Module)"
			ModuleVersion = "$($module.Version)"
			GUID = "$((get-module "$($module.Module)").guid)" }
    }
	#$ModuleNames = ($SelectedModules.Module | Sort| Get-Unique -AsString)

	return $RequiredModules
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
	if ($functionData.Example_A -ne "`n" -and $functionData.Example_A -and $functionData.Example_A.trim() -ne "") { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_A.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Example_B -ne "`n" -and $functionData.Example_B -and $functionData.Example_B.trim()  -ne "") { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_B.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Example_C -ne "`n" -and $functionData.Example_C -and $functionData.Example_C.trim()  -ne "") { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_C.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Example_D -ne "`n" -and $functionData.Example_D -and $functionData.Example_D.trim()  -ne "") { $FunctionHelp += ".EXAMPLE `n $(($functionData.Example_D.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	if ($functionData.Notes -and $functionData.Notes -ne "`n") { $FunctionHelp += ".NOTES `n $(($functionData.Notes.trim().split("`n") | where-object { $_ | Where-Object {$_ -match '\S'}}) -join "`n") `n`n" }
	$FunctionHelp += "#> "

	#function Code
	$functionCode = "function $($functionData.name) () {`n "
	$functionCode += $($functionData.Definition)
	$functionCode += "}"

	$functionString = $functionhelp
	$functionString += "`n"
	$functionString += $functionCode

	return $functionString
}

function format-DocumentationReadMeMD () {
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


