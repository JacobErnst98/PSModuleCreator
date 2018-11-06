#builds a PS Module
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
    # https://github.com/settings/tokens/new
 curl https://api.github.com/user/repos?access_token=$token -d '{"name":"$name"}'

}

function Get-functions(){
   [Parameter(mandatory=$true)][string]$file
    $oldarray= Get-ChildItem function:\
    import-module $file
    $newarray= Get-ChildItem function:\
    return ($newarray | where {$oldarray -notcontains $_}).name
}


function New-GitToken() {
 [Parameter(mandatory=$true)][string]$user
  [Parameter(mandatory=$true)][string]$pass

$pair = "${user}:${pass}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue}
$postparams = @{scopes = "repo";note = "ZPSMODULE" }
Invoke-WebRequest -uri "https://api.github.com/authorizations" -Headers $headers -Method POST -body $postparams

#curl -u '$username'  -d '{"scopes":["repo"],"note":"ZPSMODULE"}' https://api.github.com/authorizations
#Curl -u does not exsist in powershell we will have to find a way to do this with invoke-webrequest
}
