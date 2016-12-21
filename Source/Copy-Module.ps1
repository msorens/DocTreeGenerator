Set-StrictMode -Version Latest

<#

.SYNOPSIS
Copies a PowerShell module to a different location on the file system.

.DESCRIPTION
Copies a PowerShell module either to the standard system repository location
or copies it to a custom location.
Using the standard system repository (the default action)
makes cmdlets automatically available in a PowerShell session,
as well as making the cmdlets available for explicit import with just the name
of the module, e.g. "Import-Module Your.PowerShell.Module.

* The module manifest (.psd1) specifies which files will be installed.
* All files required by the module must sit in the same directory
  as the module manifest and DLL (if a compiled module).
* The module directory must be the same name as the module manifest base name.

.PARAMETER Name
Name of the PowerShell module.

.PARAMETER Destination
Specifies the path to the new location if supplied. Otherwise,
uses the standard system location.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
PS> Copy-Module NextIT.AgentAdmin.PowerShell
Installs Alme core module

.EXAMPLE
PS> Copy-Module -Name NextIT.ResponseManagerAdmin.PowerShell
Installs Alme Response Manager module

#>

function Copy-Module
{
	[CmdletBinding()]
	param(
		[parameter(Mandatory)] [string]$Name,
		[string]$Destination
	)

	$myVerbose = $VerbosePreference -ne 'SilentlyContinue'

	$manifestFile = ".\$Name.psd1"
    $stdDestination = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\$Name"
	$psDir = if ($Destination) { $Destination } else { $stdDestination }

	if (!(Test-Path $manifestFile)) {
		Write-Warning "Please run from your Alme bin directory"
		return
	}
	$manifest = Get-Content $manifestFile -Raw | Invoke-Expression

	if (Test-Path $psDir) {
		Write-Verbose "Removing $psDir."
		rmdir $psDir -recurse
	}
	Write-Verbose "Creating $psDir."
	mkdir $psDir | Out-Null 

	Copy-Item -path $manifestFile -dest $psDir -force -Verbose:$myVerbose

	Write-Verbose 'Copying these files from manifest:'
	$manifest.FileList | ForEach-Object {
		$target = Join-Path $psDir $_
		Write-Verbose $_
		New-Item -ItemType File -Path $target -Force | Out-Null  # touch to auto-create directory if needed   
		Copy-Item -path $_ -dest $target -force
	}

	Write-Verbose 'Done.'
}

Export-ModuleMember Copy-Module
