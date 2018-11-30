<# 
 .SYNOPSIS 
 Changes code to work in module layout 

.DESCRIPTION 
 Changes code to work in module layout, by editing file paths for dependencies 

.PARAMETER Filedependencies 
 string Parameter_Filedependencies=Filedependencies is a mandatory parameter of type Array of file objects 

.PARAMETER functionDocumentation 
 string Parameter_functionDocumentation=functionDocumentation is a mandatory parameter of type array of functiondocumentation objects 

.PARAMETER ProjectDirectory 
 string Parameter_ProjectDirectory=ProjectDirectory is a mandatory parameter of type String, path to project directory 

.NOTES 
 Author: Mentaleak. 

#> 
function Update-moduleCode () {
 
	param(
		[Parameter(mandatory = $true)] $functionDocumentation,
		[Parameter(mandatory = $true)] $Filedependencies,
		[Parameter(mandatory = $true)][string] $ProjectDirectory

	)
	$suspectedCodeChanges = @()
	foreach ($item in $Filedependencies) {
		foreach ($fn in $functionDocumentation) {
			$linecount = 0
			$fndefarr = $fn.Definition.split("`n")
			foreach ($line in $fndefarr) {
				#LOADING BAR
				Write-Progress -Status "Looking into changing code" -Activity "$($item.name): $($fn.name): $linecount / $($fndefarr.count)" -PercentComplete (100 * ($linecount / $fndefarr.count))
				$lmatch = $item.FullName.Replace($ProjectDirectory,"")
				if ($line -match [regex]::Escape($lmatch)) {
					switch ($item.Extension)
					{
						{ @(".dll",".cab",".jar") -contains $_ } {
							$Nline = $line.Replace($($item.FullName.Replace($ProjectDirectory,"")),"Lib\$($item.name)")
						}
						{ @(".exe",".msi",".bin",".dat") -contains $_ } {
							$Nline = $line.Replace($($item.FullName.Replace($ProjectDirectory,"")),"Bin\$($item.name)")
						}
						default {
							$Nline = $line.Replace($($item.FullName.Replace($ProjectDirectory,"")),"\Other-Dependencies\$($item.name)")
						}
					}

					$suspectedCodeChanges += [pscustomobject]@{
						FN_Name = $fn.Name
						Item_Name = $item.Name
						O_line = $line
						N_line = $Nline
						line_Num = $linecount
					}
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
	return $functionDocumentation
}
