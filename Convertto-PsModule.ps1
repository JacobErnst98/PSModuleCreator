#builds a PS Module
#requires PSGit
#requires PSTools

function ConvertTo-PSModule(){
    param(
        [Parameter(mandatory=$true)][string]$source
    )
    if(!(Test-GitAuth -nobreak)){	
        connect-github
    }
    if(Test-GitAuth){
        $SourceFile=(Get-Item $source)
        $ProjectPath=(Get-Item $source).Directory.FullName
        $userData=get-gituserdata

        #Write-Host "Test Local"
        if (test-GitLocal -ProjectPath $ProjectPath) {
		#Write-Host "Test remote"
		    if (test-GitRemote -ProjectPath $ProjectPath) {
                $RepoData=get-gitrepo -ProjectPath $ProjectPath

                $ModuleName=$RepoData.name
                


                $authors=($RepoData.contributors_stats |Format-Table -autosize |Out-String)




<# 
# RootModule = ''

# Author of this moduleAuthor = 'User01'

# Description of the functionality provided by this module
# Description = ''

# Version number of this module.ModuleVersion = '1.0'

# HelpInfo URI of this module
# HelpInfoURI = '
#>


# ID used to uniquely identify this moduleGUID = 'd0a9150d-b6a4-4b17-a325-e3a24fed0aa9'
# Company or vendor of this moduleCompanyName = 'Unknown'
# Copyright statement for this moduleCopyright = '(c) 2012 User01. All rights reserved.'
# Minimum version of the PowerShell engine required by this module

# PowerShellVersion = ''
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

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

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








                #make directory for module
                <#
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Private"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Public"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\en-US"

               
                New-ModuleManifest -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\$($ModuleName).psd1" `
                                   -RootModule $ModuleName.psm1 `
                                   -Description $RepoData.Description `
                                   -Author $authors `
                                   -Version $RepoData.updated_at `
                                   -HelpInfoURI $RepoData.html_url `

                                   -PowerShellVersion 3.0 `
                                   -FormatsToProcess "$ModuleName.Format.ps1xml"
               #>
             }
        }                      
    }
}
