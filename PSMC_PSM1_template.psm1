<#{.ModuleName.}#>
<#{.PSVersionREQ.}#>

param([switch]$NoVersionCheck)

#Is module loaded; if not load
if (!(Get-Module <#{.ModuleName.}#>)){ 
    $psv = $PSVersionTable.PSVersion

    #verify PS Version
    if ($psv.Major -lt <#{.PSVersionREQ.}#> -and !$NoVersionWarn) {
        Write-Warning ("<#{.ModuleName.}#> is listed as requiring <#{.PSVersionREQ.}#>; you have version $($psv).`n" +
        "Visit Microsoft to download the latest Windows Management Framework `n" +
        "To suppress this warning, change your include to 'Import-Module <#{.ModuleName.}#> -NoVersionCheck `$true'.")
    }
    else{
        #get functions
        $PrivateFunctions =Get-childItem -path "$($PSScriptRoot)\Private" -Filter "*.ps1"
        $PublicFunctions =Get-childItem -path "$($PSScriptRoot)\Public" -Filter "*.ps1"
        foreach($PrivateFunction in $PrivateFunctions)
        {
            . $PrivateFunction.FullName
        }
        foreach($PublicFunction in $PublicFunctions)
        {
            . $PublicFunction.FullName
            Export-ModuleMember $PublicFunction.Name
        }

    }
}