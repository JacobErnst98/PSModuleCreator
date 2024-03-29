param([switch]$NoVersionCheck)

#Is module loaded; if not load
if ((Get-Module PSModuleCreator)){return}
    $psv = $PSVersionTable.PSVersion

    #verify PS Version
    if ($psv.Major -lt 5 -and !$NoVersionWarn) {
        Write-Warning ("PSModuleCreator is listed as requiring 5; you have version $($psv).`n" +
        "Visit Microsoft to download the latest Windows Management Framework `n" +
        "To suppress this warning, change your include to 'Import-Module PSModuleCreator -NoVersionCheck `$true'.")
        return
    }
. $PSScriptRoot\public\ConvertTo-PSModule.ps1
. $PSScriptRoot\private\copy-scriptdependencies.ps1
. $PSScriptRoot\private\format-DocumentationReadMeMD.ps1
. $PSScriptRoot\private\get-functionDocumentation.ps1
. $PSScriptRoot\private\get-ModuleVersion.ps1
. $PSScriptRoot\private\get-requiredmodules.ps1
. $PSScriptRoot\private\New-functionDoc.ps1
. $PSScriptRoot\private\new-Modulefolderstructure.ps1
. $PSScriptRoot\private\Update-moduleCode.ps1
Export-ModuleMember ConvertTo-PSModule
Export-ModuleMember copy-scriptdependencies
Export-ModuleMember format-DocumentationReadMeMD
Export-ModuleMember get-functionDocumentation
Export-ModuleMember get-ModuleVersion
Export-ModuleMember get-requiredmodules
Export-ModuleMember New-functionDoc
Export-ModuleMember new-Modulefolderstructure
Export-ModuleMember Update-moduleCode
