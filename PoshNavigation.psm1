if (Get-Module PoshNavigation) { return }

if (-not (Get-Module Microsoft.Powershell.Utility))
{
	Import-Module Microsoft.Powershell.Utility
}

Push-Location $psScriptRoot
. .\PoshNaviation.ps1
Pop-Location
