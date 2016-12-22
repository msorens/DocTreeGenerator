Set-StrictMode -Version Latest

<#

.SYNOPSIS
Generates HTML documentation for PowerShell modules using the DocTreeGenerator engine.

.DESCRIPTION
This is a wrapper around Convert-HelpToHtmlTree that provides more flexibility.
Convert-HelpToHtmlTree requires all the modules you are documenting to be siblings
in a file tree, but Publish-ModuleDocumentationTree lets you specify modules
from different areas of your source tree.
The modules are copied (according to their manifests) to a temporary directory
in the appropriate structure, then Convert-HelpToHtmlTree is invoked.
Specify the modules and other parameters in a configuration file,
which you pass to this cmdlet.

A sample configuration file (module-doc.conf.SAMPLE) comes with this module.

.PARAMETER ConfigFilePath
Full path of configuration file; if not supplied, uses module-doc.conf
in the current directory.

.INPUTS
None. You cannot pipe objects to Publish-ModuleDocumentationTree.

.OUTPUTS
None. Publish-ModuleDocumentationTree does not generate any output.

.LINK
Convert-HelpToHtmlTree
.LINK
about_Comment_Based_Help
.LINK
[About Help Topics] (http://technet.microsoft.com/en-us/library/dd347616.aspx)
.LINK
[Cmdlet Help Topics] (http://technet.microsoft.com/en-us/library/dd347701.aspx)
.LINK
[How To Document Your PowerShell Library with Convert-HelpToHtmlTree](https://www.simple-talk.com/sysadmin/powershell/how-to-document-your-powershell-library/)
.LINK
[Documenting Your PowerShell Binary Cmdlets](https://www.simple-talk.com/dotnet/software-tools/documenting-your-powershell-binary-cmdlets/)
.LINK
[Unified Approach to Generating Documentation for PowerShell Cmdlets](https://www.simple-talk.com/sysadmin/powershell/unified-approach-to-generating-documentation-for-powershell-cmdlets/)

#>

function Publish-ModuleDocumentationTree
{
	[CmdletBinding()]
	param(
		[string]$ConfigFilePath
	)
	if (!$ConfigFilePath) { $ConfigFilePath = '.\module-doc.conf' }
	$config = GetConfigData $ConfigFilePath
	$root = "$($env:temp)\DocGeneratorTemp"
	$tmpInstallDir = "$root\$($config.Namespace)"
	$script:proceed = $true

	Push-Location
	PrepModules
	Pop-Location
	if ($proceed) { GenerateDocs }
}

function GetConfigData($name)
{
	Get-Content $name | Out-String | Invoke-Expression
}

function WriteSection($header)
{
	Write-Output "================================================="
	Write-Output $header
	Write-Output "================================================="
}

function PrepModules()
{
	WriteSection "Prepping $($config.Modules.length) modules..."

	if (Test-Path $tmpInstallDir) {
		Remove-Item $tmpInstallDir -Force -Recurse -ErrorAction SilentlyContinue
	}
	if (Test-Path $tmpInstallDir) {
		Write-Warning 'Modules may be in use; try a fresh PowerShell session.'
		$script:proceed = $false
		return
	}

	New-Item -Path $tmpInstallDir -ItemType directory | Out-Null
	if ($config.ContainsKey('NamespaceOverviewPath') -and
			$config.NamespaceOverviewPath.Trim()) {
		$namespacePath = Join-Path $config.ProjectRoot $config.NamespaceOverviewPath
		Copy-Item "$namespacePath\namespace_overview.html" $tmpInstallDir
	}

	$config.Modules | ForEach-Object {
		Write-Output ('    ' + $_.Name)
		cd (Join-Path $config.ProjectRoot $_.BinPath)
		$targetPath = "$tmpInstallDir\$($_.Name)"
		Copy-Module -Name $_.Name -Destination $targetPath
		$moduleFile = '{0}\{1}\{2}\module_overview.html' -f $config.ProjectRoot, $_.SourcePath, $_.Name
		Copy-Item $moduleFile $targetPath
	}
}

function GenerateDocs()
{
	WriteSection 'Generating docs...'
	$docDir = $config.DocPath
	if (Test-Path "$docDir-bak") {
		Remove-Item "$docDir-bak" -Force -Recurse
	}
	if (Test-Path $docDir) {
		Rename-Item $docDir "$docDir-bak"
	}

	$params = @{
		Namespaces   = $config.Namespace
		SourceDir    = $root
		TargetDir    = $config.DocPath
		Copyright    = $config.CopyrightYear
		RevisionDate = $config.RevisionDate
		Template     = Join-Path $config.ProjectRoot $config.TemplatePath
		DocTitle     = $config.DocTitle
	}
	
	Convert-HelpToHtmlTree @params
}

Export-ModuleMember Publish-ModuleDocumentationTree
