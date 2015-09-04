param($configJsonPath)

if (Get-Module PoshNavigation) { return }

if (-not (Get-Module Microsoft.Powershell.Utility))
{
	Import-Module Microsoft.Powershell.Utility
}

Push-Location $psScriptRoot
. .\PoshNavigation.ps1
Pop-Location

Export-ModuleMember -Function @('Add-SampleConfiguration')
Export-ModuleMember -Function @('Initialize-Navigation')
Export-ModuleMember -Function @('Get-Enlistment')
Export-ModuleMember -Function @('Resolve-ProjectRoot')
Export-ModuleMember -Function @('Set-Enlistment')
Export-ModuleMember -Function @('Set-Project')

if (-not ([String]::IsNullOrEmpty($configJsonPath)) -and (Test-Path $configJsonPath))
{
	Initialize-Navigation $configJsonPath
}
