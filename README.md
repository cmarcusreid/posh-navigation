# posh-navigation

posh-navigation exports functions for quickly jumping between enlistments and projects.

## Exported functions

### Get-Enlistment

Retrieves the current enlistment based on current location.

	C:\repositories\git-status-cache\src\GitStatusCache> Get-Enlistment
	
	Alias ProjectsTemplate Root
	----- ---------------- ----
	gsc   gitstatuscache   C:\repositories\git-status-cache

### Set-Enlistment

Navigates to the specified enlistment.

	C:\repositories\git-status-cache\src\GitStatusCache\ide> Set-Enlistment gscpc
	C:\repositories\git-status-cache-posh-client> Set-Enlistment gsc
	C:\repositories\git-status-cache>

### Resolve-ProjectRoot

Returns the root path for the specified project in the current enlistment. Useful helper for scripts that operate on projects shared in multiple enlistments (ex. building, running tests, etc.).

	C:\repositories\git-status-cache> Resolve-ProjectRoot rj
	C:\repositories\git-status-cache\ext\rapidjson
	C:\repositories\git-status-cache> Resolve-ProjectRoot rdc
	C:\repositories\git-status-cache\ext\ReadDirectoryChanges

### Set-Project

Navigates to the specified project.
	
	C:\repositories\git-status-cache> Set-Project gsc
	C:\repositories\git-status-cache\src\GitStatusCache> Set-Project rj
	C:\repositories\git-status-cache\ext\rapidjson>

## Installation

posh-navigation will automatically create a sample JSON configuration file and add an import for the module in your PowerShell $PROFILE.

1. Launch PowerShell and navigate to posh-navigation's root.
2. Run Install.ps1.
3. Reload your shell or call ". $profile" to reload PowerShell with posh-navigation.

After installation you can customize your environment by modifying the JSON configuration file. 

	PS C:\Repositories\posh-navigation> .\install.ps1
	Creating sample config file at "C:\repositories\posh-navigation\bin\machineName.json".
	Adding posh-navigation to profile.
	posh-navigation successfully installed!
	Please reload your profile for the changes to take effect:
		. $PROFILE

## Configuration

After installation define your enlistments and projects by modifying the JSON configuration file.

Enlistments may specify a ProjectsTemplate that contains aliases and paths to specific projects within the enlistment. The same ProjectsTemplate may be referenced by multiple enlistments.

	{
	    "Enlistments":
	    [
	        {
	            "Alias": "1",
	            "ProjectsTemplate": "mario",
	            "Root": "E:\\ws\\1"
	        },
	        {
	            "Alias": "2",
	            "ProjectsTemplate": "mario",
	            "Root": "E:\\ws\\2"
	        },
	        {
	            "Alias": "e",
	            "Root": "D:\\environment"
	        },
	        {
	            "Alias": "ta",
	            "Root": "D:\\text-adventure"
	        }
	    ],
	    "ProjectsTemplates":
	    [
	        {
	            "Name": "mario",
	            "Projects":
	            [
	                {
	                    "Alias": "k",
	                    "Root": "\\Products\\Kart"
	                },
	                {
	                    "Alias": "p",
	                    "Root": "\\Products\\Party"
	                }
	            ]
	        }
	    ]
	}

The following switches to enlistment 2 and navigates to the Kart project.

	Set-Enlistment 2
	Set-Project k