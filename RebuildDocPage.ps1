Set-StrictMode -Version Latest

$moduleName = 'DocTreeGenerator'
$projectDir = "$Home\Documents\GitHub\$moduleName"
$configName = Join-Path $projectDir 'DocTreeGenerator-module-doc.conf'
$configData = Get-Content $configName | Out-String | Invoke-Expression
$docDir = $configData.DocDirectory
$namespace = $configData.Namespace

Publish-ModuleDocumentationTree $configName

Write-output ""
Write-output "copying back to GitHub"
copy-item "$docDir\$namespace\$moduleName\*.*" "$projectDir\Docs" -force -recurse
