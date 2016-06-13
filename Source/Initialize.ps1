Set-StrictMode -Version Latest

function Init-Variables()
{
	$script:fileCount        = 0
	$script:functionCount    = 0
	$script:moduleCount      = 0
	$script:namespaceCount   = 0
	$script:noModulesFlagged = $false
	$script:itemList         = @()
	$script:failedCount      = 0

	$script:PAGE_HOME        = "home"
	$script:PAGE_CONTENTS    = "contents"
	$script:PAGE_MODULE      = "module"
	$script:PAGE_FUNCTION    = "function"
	$script:PAGE_LIST = $PAGE_HOME, $PAGE_CONTENTS, $PAGE_MODULE, $PAGE_FUNCTION

	$script:CSS_ERR_MSG        = "errMsg"
	$script:CSS_PS_CMD         = "pscmd"
	$script:CSS_PS_DOC_SECTION = "PowerShellDoc"

	$script:CMDLET_TYPES       ='Function','Filter','Cmdlet'

	$script:namespace_overview_filename = "namespace_overview.html"
	$script:module_overview_filename    = "module_overview.html"
	$script:default_template            = "$PSScriptRoot\..\Templates\psdoc_template.html"

	$script:moduleRoot = Get-UserPsModulePath

	# Get the name of *this* module because it requires special handling.
	if ($script:MyInvocation.MyCommand.Path -match "\\([^\\]*)\\\w*.psm1")
	{ $script:thisModule = $Matches[1] }
	else { $script:thisModule = "" }

	$script:msdnIndex = Get-CmdletDocLinks
	
	$script:SYNTAX_SECTION = 'SYNTAX'
	$script:DESCRIPTION_SECTION = 'DESCRIPTION'
	$script:PARAMETERS_SECTION = 'PARAMETERS'
	$script:EXAMPLES_SECTION = 'EXAMPLES'
	$script:LINKS_SECTION = 'RELATED LINKS'

	$script:template = Get-Template $default_template
	Init-ModuleProperties
}

# Get just the user path out of the env var containing both the user path
# and the system path, by searching for the user name component of a path,
# optionally followed by a dollar sign (indicating home folder share).
function Get-UserPsModulePath()
{
	$env:PSModulePath.split(";") | ? { $_ -match "\\$($env:USERNAME)\`$?\\" }
}

function Get-Template([string]$defaultTemplate)
{
	$templateName = $TemplateName
	if (!$templateName) {
		$templateName = $defaultTemplate
	}
	Get-Content $templateName -ErrorAction Stop
}

function Init-ModuleProperties()
{
	$allModuleProperties =
		Get-Module |
		Get-Member |
		? { $_.MemberType -eq "Property" } |
		% { $_.Name }
	# Hmmm... should work without Out-String but causes $matches to be empty!
	$tstring = $template | Out-String
	$script:modulePropertiesInTemplate = @()
	$allModuleProperties | % {
		$property = $_
		if ($tstring -match "\{module.($property)\}") {
			$script:modulePropertiesInTemplate += $matches[1] } 
	}
	if ($script:modulePropertiesInTemplate.count -eq 0) {
		$script:modulePropertiesInTemplate = $null
	}
#	This essentially serves as a boolean indicating presence of any.
#	$script:modulePropertiesInTemplate = 
#		$template | Select-String ( $moduleProperties | % { "{module.$_}"} )
}

