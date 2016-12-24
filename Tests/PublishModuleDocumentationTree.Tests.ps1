Import-Module "$PSScriptRoot\..\DocTreeGenerator.psd1" -force

InModuleScope DocTreeGenerator {

	Describe 'Publish-ModuleDocumentationTree' {

		Mock Write-Output
		Mock Remove-Item
		Mock Rename-Item
		Mock New-Item
		Mock Copy-Item
		Mock Copy-Module
		Mock Set-Location
		Mock Test-Path -MockWith { $true } `
			-ParameterFilter { $Path -match [regex]::Escape($config.DocPath) }
		Mock Test-Path -MockWith { $false } `
			-ParameterFilter { $Path -match [regex]::Escape($env:temp) }
		Mock Rename-Item -MockWith { $script:calls += 'rename to backup' } `
			-ParameterFilter { $NewName -eq "$($config.DocPath)-bak" }
		Mock Remove-Item -MockWith { $script:calls += 'remove backup' } `
			-ParameterFilter { $Path -eq "$($config.DocPath)-bak" }
		Mock Convert-HelpToHtmlTree  -MockWith { $script:calls += 'regenerate' }
		Mock GetConfigData { return $configData }

		BeforeEach {
			$script:calls = @()
			$configData = @{
				Namespace = 'myNamespace'
				ProjectRoot = 'my\Project\Root'
				NamespaceOverviewPath = 'ns\path\here'
				DocPath = 'doc\path\here'
				DocTitle = 'My API'
				TemplatePath = 'template\path\here'
				CopyrightYear = '2016'
				RevisionDate = '2016.12.05'
				Modules = @(
					@{
				   		Name = 'name1'
						SourcePath = 'some\srcpath1'
						BinPath = 'some\binpath1'
					},
					@{
				   		Name = 'name2'
						SourcePath = 'some\srcpath2'
						BinPath = 'some\binpath2'
					}
				)
			}
		}

		It 'uses the supplied config file name' {
			Publish-ModuleDocumentationTree 'myConfig.conf'
			Assert-MockCalled GetConfigData 1 { $name -eq 'myConfig.conf'}
		}

		It 'uses a default config file name if none supplied' {
			Publish-ModuleDocumentationTree
			Assert-MockCalled GetConfigData 1 { $name -eq '.\module-doc.conf'}
		}

		It 'copies a single namespace overview for the entire project' {
			Publish-ModuleDocumentationTree "any"
			Assert-MockCalled Copy-Item -Exactly 1 -Scope It `
			-ParameterFilter { $Destination -match $configData.Namespace -and
				$Path -match "$([regex]::Escape($configData.NamespaceOverviewPath)).*namespace_overview"
			}
		}

		It 'does not copy namespace overview if NamespaceOverviewPath is not supplied' {
			$configData.Remove('NamespaceOverviewPath')

			Publish-ModuleDocumentationTree

			Assert-MockCalled Copy-Item -Exactly 0 -Scope It `
			-ParameterFilter { $Path -match "namespace_overview" }
		}

		It 'does not copy namespace overview if NamespaceOverviewPath is whitespace' {
			$configData.NamespaceOverviewPath = ' '

			Publish-ModuleDocumentationTree

			Assert-MockCalled Copy-Item -Exactly 0 -Scope It `
			-ParameterFilter { $Path -match "namespace_overview" }
		}

		It 'copies each module in the config file' {
			Publish-ModuleDocumentationTree "any"
			Assert-MockCalled Copy-Module -Exactly $configData.Modules.Length -Scope It
			$configData.Modules | ForEach-Object {
				Assert-MockCalled Copy-Module -Exactly 1 -Scope It `
				-ParameterFilter { $Name -eq $_.Name -and $Destination -match $_.Name }
			}
		}

		It 'copies a module overview for each module in the config file' {
			Publish-ModuleDocumentationTree "any"
			$configData.Modules | ForEach-Object {
				Assert-MockCalled Copy-Item -Exactly 1 -Scope It `
				-ParameterFilter { $Path -match "module_overview" -and
					$Destination -match $_.Name }
			}
		}

		It 'gets module overview for each module from the module source directory' {
			Publish-ModuleDocumentationTree "any"
			$configData.Modules | ForEach-Object {
				Assert-MockCalled Copy-Item -Exactly 1 -Scope It `
			   	-ParameterFilter { $Path -match [regex]::Escape($_.SourcePath) -and
			   		$Path -match [regex]::Escape($configData.ProjectRoot) }
			}
		}

		It 'removes existing backup directory if present before renaming new dir to backup' {
			Publish-ModuleDocumentationTree "any"
			$calls.length | Should Be 3
			$calls[0] | Should Be 'remove backup'
			$calls[1] | Should Be 'rename to backup'
		}

		It 'backs up generated directory before re-generating' {
			Publish-ModuleDocumentationTree "any"
			$calls.length | Should Be 3
			$calls[1] | Should Be 'rename to backup'
			$calls[2] | Should Be 'regenerate'
		}

		It 'invokes Convert-HelpToHtmlTree with expected parameters' {
			Publish-ModuleDocumentationTree "any"
			Assert-MockCalled Convert-HelpToHtmlTree -Exactly 1 -Scope It `
			-ParameterFilter { $Namespaces -eq $configData.Namespace -and
				$TargetDir -eq $configData.DocPath -and
				$Copyright -eq $configData.CopyrightYear -and
				$RevisionDate -eq $configData.RevisionDate -and
				$DocTitle -eq $configData.DocTitle -and
				$TemplateName -match ('{0}.*{1}' -f `
					[regex]::Escape($configData.ProjectRoot), [regex]::Escape($configData.TemplatePath))
			}
		}
	}
}
