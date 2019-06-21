#
# Module manifest for module 'PSModuleCreator'
#
# Generated by: https://github.com/Mentaleak/PSModuleCreator







#
# Generated on: 6/21/2019
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSModuleCreator.psm1'

# Version number of this module.
ModuleVersion = '201906.21.1539.56'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '14db743e-bc21-470b-a469-ba116e6af90a'

# Author of this module
Author = '
AuthorType  Author       Changes Adds Deletes Commits
----------  ------       ------- ---- ------- -------
Contributor Mentaleak       1191  847     344     130
Owner       JacobErnst98      37   35       2       3


'

# Company or vendor of this module
CompanyName = 'JacobErnst98'

# Copyright statement for this module
Copyright = '(c) 2019 JacobErnst98. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Takes the path of a script in a local git Repo and builds a PSmodule from it and the Repo data'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'psgit'; GUID = 'f8c0276c-3997-4c27-8f10-2ed351c68ba8'; ModuleVersion = '201812.3.1405.0'; }, 
               @{ModuleName = 'PSTools'; GUID = 'daf6cce7-8931-4e18-9b20-04a4a9393a62'; ModuleVersion = '201812.7.1335.29'; }, 
               @{ModuleName = 'show-psgui'; GUID = '68cea6f1-21c8-4f79-ba44-9160c57d89fc'; ModuleVersion = '201812.3.1326.15'; })

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'ConvertTo-PSModule'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = 'PSModuleCreator.psd1', 'PSModuleCreator.psm1', 
               'ConvertTo-PSModule.ps1', 'copy-scriptdependencies.ps1', 
               'format-DocumentationReadMeMD.ps1', 'get-functionDocumentation.ps1', 
               'get-ModuleVersion.ps1', 'get-requiredmodules.ps1', 
               'New-functionDoc.ps1', 'new-Modulefolderstructure.ps1', 
               'Update-moduleCode.ps1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/JacobErnst98/PSModuleCreator'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

