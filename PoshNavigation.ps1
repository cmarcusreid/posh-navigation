function Get-BinPath
{
    $scriptDirectory = Split-Path $PSCommandPath -Parent
    return Join-Path $scriptDirectory "bin"
}

function Get-SamplesPath
{
    $scriptDirectory = Split-Path $PSCommandPath -Parent
    return Join-Path $scriptDirectory "samples"
}

function Add-SampleConfiguration
{
    $computerName = $env:COMPUTERNAME.ToLower()
    $configPath = Get-BinPath
    $configFilePath = Join-Path $configPath "$computerName.json"

    if (-not (Test-Path $configFilePath))
    {
        $samplesPath = Get-SamplesPath
        $sampleFilePath = Join-Path $samplesPath "SampleConfig.json"
        Write-Host -ForegroundColor Green "Creating sample config file at ""$configFilePath""."
        New-Item $configFilePath -Force -Type File -ErrorAction Stop | Out-Null
        Copy-Item $sampleFilePath $configFilePath -Force -ErrorAction Stop | Out-Null
    }

    return $configFilePath
}

$script:configPath = $null

function Initialize-Navigation($configJsonPath)
{
    if ([String]::IsNullOrEmpty($configJsonPath) -or -not (Test-Path($configJsonPath)))
    {
        Write-Error "Initialize-Navigation requires path to config json. $configJsonPath is not a valid path."
        return
    }

    if (-not [System.IO.Path]::IsPathRooted($configJsonPath))
    {
        $configJsonPath = Join-Path (pwd) $configJsonPath
        $configJsonPath = [System.IO.Path]::GetFullPath($configJsonPath) 
    }

    $script:configPath = $configJsonPath
}

function Get-NavigationConfig
{
    if ($script:configPath -eq $null)
    {
        Write-Error "Initialize-Navigation must be called with path to config json."
        return $null
    }

    $config = (Get-Content $script:configPath) -join "`n" | ConvertFrom-Json
    foreach ($enlistment in $config.Enlistments)
    {
        if ([String]::IsNullOrEmpty($enlistment.Alias))
        {
            Write-Error "Null or empty Alias."
            return $null
        }

        $enlistmentRoot = [System.Environment]::ExpandEnvironmentVariables($enlistment.Root)
        if ([String]::IsNullOrEmpty($enlistmentRoot))
        {
            Write-Error "Enlistment ($($enlistment.Alias)) has null or empty Root."
            return $null
        }

        if (-not (Test-Path($enlistmentRoot)))
        {
            Write-Error "Enlistment ($($enlistment.Alias)) Root ($enlistmentRoot) is not a valid path."
            return $null
        }

        if (-not ([String]::IsNullOrEmpty($enlistment.ProjectsTemplate)))
        {
            $projectsTemplate = $null
            foreach ($template in $config.ProjectsTemplates)
            {
                if ($template.Name -eq $enlistment.ProjectsTemplate)
                {
                    $projectsTemplate = $template
                }
            }

            if ($projectsTemplate -eq $null)
            {
                Write-Error "Enlistment ($($enlistment.Alias)) references invalid ProjectsTemplate ($($enlistment.ProjectsTemplate))"
                return $null
            }

            foreach ($project in $projectsTemplate.Projects)
            {
                if ([String]::IsNullOrEmpty($project.Alias))
                {
                    Write-Error "ProjectsTemplate ($($projectsTemplate.Name)) contains Project with null or empty Alias."
                    return $null
                }

                if (-not ([String]::IsNullOrEmpty($project.Root)))
                {
                    $projectRoot = [System.Environment]::ExpandEnvironmentVariables($project.Root)
                    $projectRootPath = Join-Path -Path $enlistmentRoot -ChildPath $projectRoot
                    if (-not (Test-Path($projectRootPath)))
                    {
                        Write-Error "Enlistment ($($enlistment.Alias)) references ProjectsTemplate ($($projectsTemplate.Name)) which contains Project ($($project.Alias)) with a Root that does not resolve to a valid path in the enlistment."
                        return $null
                    }
                }
            }
        }
    }

    return $config
}

function global:Set-Enlistment($alias)
{
    $config = Get-NavigationConfig
    foreach ($enlistment in $config.Enlistments | where { $_.Alias -eq $alias })
    {
        $root = [System.Environment]::ExpandEnvironmentVariables($enlistment.Root)
        Set-Location $root
        return
    }

    Write-Error "Could not find ""$alias"" enlistment alias."
}

function global:Get-Enlistment()
{
    $config = Get-NavigationConfig

    $currentLocation = Get-Location
    $currentPath = $currentLocation.Path

    $bestMatch = ""
    $bestEnlistment = $null
    foreach ($enlistment in $config.Enlistments)
    {
        $root = [System.Environment]::ExpandEnvironmentVariables($enlistment.Root)
        if ($currentPath.StartsWith($root) -and $root.Length -gt $bestMatch.Length)
        {
            $bestMatch = $root
            $bestEnlistment = $enlistment
        }
    }

    if (-not ($bestEnlistment -eq $null))
    {
        return $bestEnlistment
    }

    Write-Error "Current location is not within a defined enlistment."
}

function global:Get-ProjectsTemplate($enlistment)
{
    $config = Get-NavigationConfig

    if ($enlistment -eq $null)
    {
        Write-Error "Enlistment is null."
        return
    }

    if ([String]::IsNullOrEmpty($enlistment.ProjectsTemplate))
    {
        Write-Error "Enlistment ""$($enlistment.Alias)"" does not have a ProjectsTemplate."
        return
    }

    foreach ($projectsTemplate in $config.ProjectsTemplates)
    {
        if ($projectsTemplate.Name -eq $enlistment.ProjectsTemplate)
        {
            return $projectsTemplate
        }
    }

    Write-Error "Could not find ProjectsTemplate ""$($enlistment.ProjectsTemplate)"""
}

function global:Resolve-ProjectRoot($alias)
{
    if ([String]::IsNullOrEmpty($alias))
    {
        Write-Error "Alias is null or empty."
        return
    }

    $enlistment = Get-Enlistment
    if ($enlistment -eq $null)
    {
        Write-Error "Failed to retrieve current enlistment."
        return
    }

    $projectsTemplate = Get-ProjectsTemplate($enlistment)
    if ($projectsTemplate -eq $null)
    {
        Write-Error "Failed to retrieve projects template for current enlistment."
        return
    }

    foreach ($project in $projectsTemplate.Projects | where { $_.Alias -eq $alias })
    {
        $projectRoot = [System.Environment]::ExpandEnvironmentVariables($project.Root)
        if ([String]::IsNullOrEmpty($projectRoot))
        {
            Write-Error "Project ""$($project.Alias)"" does not contain Root."
            return
        }

        $enlistmentRoot = [System.Environment]::ExpandEnvironmentVariables($enlistment.Root)
        $path = Join-Path -Path $enlistmentRoot -ChildPath $projectRoot
        if (-not (Test-Path $path))
        {
            Write-Error "Project root resolved to invalid path ""$path""."
            return
        }

        return $path
    }

    Write-Error "Failed to find project with alias ""$alias"" in enlistment ""$($enlistment.Alias)""."
}

function global:Set-Project($alias)
{
    $projectRoot = Resolve-ProjectRoot($alias)
    if ([String]::IsNullOrEmpty($projectRoot))
    {
        Write-Error "Failed to resolve project root for alias ""$alias""."
        return
    }

    Set-Location $projectRoot
}