Set-StrictMode -Version Latest

Resolve-Path $PSScriptRoot\Source\*.ps1 |
? { -not ($_.ProviderPath.Contains(".Tests.")) } |
% { . $_.ProviderPath }

