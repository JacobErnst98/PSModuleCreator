<# 
 .SYNOPSIS 
 Changes code to work in module layout 

.DESCRIPTION 
 Changes code to work in module layout, by editing file paths for dependencies 

.NOTES 
 Author: Mentaleak. 

#> 
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
