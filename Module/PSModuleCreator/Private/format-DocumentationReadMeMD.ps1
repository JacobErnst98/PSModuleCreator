<# 
 .SYNOPSIS 
 Converts documentation to README.MD doc format string 

.DESCRIPTION 
 Converts documentation to README.MD doc format string 

.PARAMETER functiondocumentation 
 string Parameter_functiondocumentation=functiondocumentation is a mandatory parameter of type System.Object, must be a pscustomdocumentation object 

.NOTES 
 Author: Mentaleak 

#> 
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
