$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent

if((Test-Path $PROFILE) -and ((Get-Content $profile) -ne $null))
{
    Write-Host -ForegroundColor Green 'Removing posh-navigation from $PROFILE.'
    $firstProfileLine = '# Import posh-navigation'
    $secondProfileLine = [RegEx]::Escape("Import-Module '$scriptDirectory\PoshNavigation.psm1'")
    Get-Content $profile | Where-Object { ($_ -notmatch $firstProfileLine) -and ($_ -notmatch "^$secondProfileLine") } | Set-Content "$profile.temp"
    Move-Item "$profile.temp" $profile -Force
}

Write-Host -ForegroundColor Green 'Removed posh-navigation.'
Write-Host -ForegroundColor Green 'Please reload your profile for the changes to take effect:'
Write-Host -ForegroundColor Green '    . $PROFILE'