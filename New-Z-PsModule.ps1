﻿#builds a PS Module
function New-Z-PSModule(){
    param(
        [Parameter(mandatory=$true)][string]$source,
        [Parameter(mandatory=$true)][string]$OutPath,
        [Parameter(mandatory=$true)][string]$ModuleName,
        [Parameter(mandatory=$true)][String]$Author,
        [Parameter(mandatory=$true)][string]$description
    )

mkdir $Path\$ModuleName
mkdir $Path\$ModuleName\Private
mkdir $Path\$ModuleName\Public
mkdir $Path\$ModuleName\en-US # For about_Help files
mkdir $Path\Tests



}

function New-GitRepo(){
    param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][string]$name,
    )
 curl https://api.github.com/user/repos?access_token=$token -d '{"name":"$name"}'

}
