#builds a PS Module
#requires PSGit

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



                #make directory for module
                <#
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Private"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\Public"
                New-Item -ItemType directory -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\en-US"

               
                New-ModuleManifest -Path "$($SourceFile.Directory.FullName)\Module\$($ModuleName)\$($ModuleName).psd1" `
                                   -RootModule $ModuleName.psm1 `
                                   -Description $Description `
                                   -PowerShellVersion 3.0 `
                                   -Author $Author `
                                   -FormatsToProcess "$ModuleName.Format.ps1xml"
               #>
             }
        }                      
    }
}
