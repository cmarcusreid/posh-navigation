$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
Import-Module "$scriptDirectory\PoshNavigation.psm1"

if(-not (Test-Path $PROFILE))
{
    Write-Host -ForegroundColor Green "Creating PowerShell profile.`n$PROFILE"
    New-Item $PROFILE -Force -Type File -ErrorAction Stop
}

$profileLine = "Import-Module '$scriptDirectory\PoshNavigation.psm1'"
if(Select-String -Path $PROFILE -Pattern $profileLine -Quiet -SimpleMatch)
{
    Write-Host -ForegroundColor Green 'Found existing posh-navigation import in $PROFILE.'
    Write-Host -ForegroundColor Green 'posh-navigation successfully installed!'
    return
}

# Adapted from http://www.west-wind.com/Weblog/posts/197245.aspx
function Get-FileEncoding($Path)
{
    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

    if(!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}

Write-Host -ForegroundColor Green "Adding posh-navigation to profile."
@"

# Import posh-navigation
$profileLine

"@ | Out-File $PROFILE -Append -Encoding (Get-FileEncoding $PROFILE)

Write-Host -ForegroundColor Green 'posh-navigation successfully installed!'
Write-Host -ForegroundColor Green 'Please reload your profile for the changes to take effect:'
Write-Host -ForegroundColor Green '    . $PROFILE'