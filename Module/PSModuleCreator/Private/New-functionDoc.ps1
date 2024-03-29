<# 
 .SYNOPSIS 
 Returns a string of content for a function file 

.DESCRIPTION 
 Parses functiondata and
Returns a string of content including comments for a function file 

.PARAMETER functionData 
 string Parameter_functionData=functionData is a mandatory parameter of type functiondata object 

.NOTES 
 Author: Mentaleak 

#> 
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
