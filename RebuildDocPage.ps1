Set-StrictMode -Version Latest

$stdModuleDir = $env:PSModulePath.split(";") |
	Where-Object { $_ -match "\\$($env:USERNAME)\`$?\\" }

$namespace = 'DocTreeGen'
$namespaceDir = "$stdModuleDir\$namespace"

$moduleName = 'DocTreeGenerator'
$module = "$namespace\$moduleName"
$moduleDir = "$namespaceDir\$moduleName"

$gitRoot = "$Home\Documents\GitHub"
$gitDir = "$gitRoot\$moduleName"
$template = "$gitDir\Templates\DocTreeGenerator_self_template.html"

$docFile = 'Convert-HelpToHtmlTree.html'
$tmpDir = "$Home\Documents\tmp"
$targetDir = "$tmpDir\DocTree"


if (Test-Path $namespaceDir) {
	remove-item $namespaceDir -Recurse -Confirm
}
if (Test-Path $targetDir) {
	remove-item $targetDir -Recurse -Confirm
}

Write-Output "Copying git files to std module dir..."
mkdir $moduleDir | Out-Null
copy-item "$gitDir\Source" $moduleDir -Recurse
copy-item "$gitDir\Doc*.ps*1" $moduleDir

# Make sure to import it from standard module location, not from git dir
Import-Module $module

Write-Output "Generating HTML file for $moduleName..."
Write-Output ('-' * 60)
Convert-HelpToHtmlTree -Namespaces $namespace -TargetDir $targetDir -TemplateName $template
Write-Output ('-' * 60)

Write-Output "Copying HTML file back to git directory..."
copy "$gitDir\$docFile" "$gitDir\$docFile.bak" -force
copy "$targetDir\$module\$docFile" $gitDir

Write-Output "Cleaning up..."
remove-item $namespaceDir -Recurse -Confirm
remove-item $targetDir -Recurse -Confirm
