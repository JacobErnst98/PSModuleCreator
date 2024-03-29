<# 
 .SYNOPSIS 
 Gets functions, asks user to document it 

.DESCRIPTION 
 Gets functions, loops through all known things about functions and generates and presents users with forms to fill in data.
Returns an array of functiondocumentation objects 

.NOTES 
 Author: Mentaleak 

#> 
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
