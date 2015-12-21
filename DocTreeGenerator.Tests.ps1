Import-Module .\DocTreeGenerator.psd1 -force

InModuleScope DocTreeGenerator {

$eightSpaces = ' ' * 8

$ErrorActionPreference = 'stop'

Describe 'Convert-HelpToHtmlTree' {

	Context 'Indenting and line breaks' {

		It 'omits break for single words' {
			$text = 'one', 'two', 'three'
			(ApplyIndents $text) -join ' ' |
			Should Be 'one two three'
		}

		It 'omits break for multiple words' {
			$text = 'one word', 'two words', 'three words'
			(ApplyIndents $text) -join ' ' |
			Should Be 'one word two words three words'
		}

		It 'omits break for normal text' {
			$text = 'one word.', 'two words?', 'three words,', 'done'
			(ApplyIndents $text) -join ' ' |
			Should Be 'one word. two words? three words, done'
		}

		It 'omits break for text with less than 4 header characters' {
			$text = 'one word.', 'it -- the green one --', 'is true'
			(ApplyIndents $text) -join ' ' |
			Should Be 'one word. it -- the green one -- is true'
		}

		It 'includes auto-break after header-like text' {
			$text = 'title1 ----', 'title2 ====', 'title3 ####'
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong>title1 ----</strong><br/><strong>title2 ====</strong><br/><strong>title3 ####</strong><br/>'
		}

		It 'includes auto-break after header-like text plus extra whitespace at the end' {
			$text = 'title1---- ', "title2 ====`t", 'plain text'
			(ApplyIndents $text) -join '' |
			Should Be "<br/><strong>title1---- </strong><br/><strong>title2 ====`t</strong><br/>plain text"
		}

		It 'includes auto-break before and after header-like text' {
			$text = '---- title1 ----', '====title2===='
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong>---- title1 ----</strong><br/><strong>====title2====</strong><br/>'
		}

		It 'includes auto-break before header-like text' {
			$text = '---- title1', '==== title2'
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong>---- title1</strong><br/><strong>==== title2</strong><br/>'
		}

		It 'includes auto-break before header-like text plus extra whitespace at the start' {
			$text = ' ---- title1', '  ====== title2', 'plain text'
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong> ---- title1</strong><br/><strong>  ====== title2</strong><br/>plain text'
		}

		It 'uses preformat block for indented lines' {
			$text = ($eightSpaces + 'one'), ($eightSpaces + 'two')
			(ApplyIndents $text) -join '' |
			Should Be '<pre>        one</pre><pre>        two</pre>'
		}

		It 'includes auto-break for list-like text with no preamble' {
			$text = '* item1', '- item2', '+ item3'
			(ApplyIndents $text) -join '' |
			Should Be '<br/>* item1<br/>- item2<br/>+ item3<br/>'
		}

		It 'includes auto-break for list-like text with immediate preamble' {
			$text = 'my list:','* item1', '- item2', '+ item3'
			(ApplyIndents $text) -join '' |
			Should Be 'my list:<br/>* item1<br/>- item2<br/>+ item3<br/>'
		}

		It 'includes auto-break for list-like text with whitespace after preamble' {
			$text = 'my list:','','','* item1', '- item2', '+ item3'
			(ApplyIndents $text) -join '' |
			Should Be 'my list:<br/><br/>* item1<br/>- item2<br/>+ item3<br/>'
		}

		It 'includes auto-break for list-like text plus extra whitespace at start' {
			$text = '    * item1', '      - item2', '      + item3'
			(ApplyIndents $text) -join '' |
			Should Be '<br/>    * item1<br/>      - item2<br/>      + item3<br/>'
		}

		It 'applies double-space for a blank line' {
			$text = 'one','','two'
			(ApplyIndents $text) -join '' |
			Should Be 'one<br/><br/>two'
		}
		It 'applies just one double-space for multiple blank lines' {
			$text = 'one','','','','two'
			(ApplyIndents $text) -join '' |
			Should Be 'one<br/><br/>two'
		}
		It 'applies just one double-space for list item followed by blank line' {
			$text = '* item1', '* item2', '','next para...'
			(ApplyIndents $text) -join '' |
			Should Be '<br/>* item1<br/>* item2<br/><br/>next para...'
		}
		It 'omits break following a pre-formatted item' {
			$text = ($eightSpaces + 'one'), '------ header ----'
			(ApplyIndents $text) -join '' |
			Should Be '<pre>        one</pre><strong>------ header ----</strong><br/>'
		}

	}

	Context 'Template available' {
		Mock Get-Content

		It 'Uses default if parameter not supplied' {
			$script:TemplateName = $null
			Get-Template 'default'
			Assert-MockCalled Get-Content 1 { $Path -eq 'default' } -Scope It
		}

		It 'Uses supplied value when default supplied' {
			$script:TemplateName = 'foo'
			Get-Template 'default'
			Assert-MockCalled Get-Content 1 { $Path -eq 'foo' } -Scope It
		}

		It 'Uses supplied value when default not supplied' {
			$script:TemplateName = 'foo'
			Get-Template
			Assert-MockCalled Get-Content 1 { $Path -eq 'foo' } -Scope It
		}
	}

	Context 'Template not available' {

		It 'Reports error if default template not found' {
			$script:TemplateName = $null
			{ Get-Template 'non-existent-file' } | Should Throw 'Cannot find path'
		}

		It 'Reports error if supplied template not found' {
			$script:TemplateName = 'non-existent-file'
			{ Get-Template } | Should Throw 'Cannot find path'
		}
	}

	Context 'Links' {
		Mock Get-Template { "any" }
		$stdTestCases = @(
			@{ template = '{0}'; description = 'no extra spaces'}
			@{ template = '  {0}'; description = 'extra spaces at start of line'}
			@{ template = '{0} '; description = 'extra spaces at end of line'}
		)

		It 'Generates link for standard cmdlet with <description>' -TestCases $stdTestCases {
			param ($template, $description)
			$url = 'http://any.com'
			$cmdlet = 'Get-ChildItem'
			$inputText = $template -f $cmdlet
			Mock Get-CmdletDocLinks { return @{ $cmdlet = $url } }
			Init-Variables

			Add-Links 'any' $inputText | Should Be "<li><a href='$url'>$cmdlet</a></li>"
		}

		It 'Generates link for "about" topic with <description>' -TestCases $stdTestCases {
			param ($template, $description)
			$url = 'http://any.com'
			$aboutTopic = 'about_Aliases'
			$inputText = $template -f $aboutTopic
			Mock Get-CmdletDocLinks { return @{ $aboutTopic = $url } }
			Init-Variables

			Add-Links 'any' $inputText | Should Be "<li><a href='$url'>$aboutTopic</a></li>"
		}

		It 'Generates link for custom function in same module with <description>' -TestCases $stdTestCases {
			param ($template, $description)
			$currModule = 'myModule'
			$cmd = 'New-Frobdingnab'
			$inputText = $template -f $cmd
			Mock Get-CmdletDocLinks { return @{ } }
			Mock Get-Command `
				-MockWith { return @{
					ModuleName = $currModule
					Module = @{ Path = 'gparent\parent\self'} # any -- not used
				} } `
				-ParameterFilter { $Name -eq $cmd }
			Init-Variables

			Add-Links $currModule $inputText | Should Be "<li><a href='$cmd.html'>$cmd</a></li>"
		}

		It 'Generates link for custom function in different module with <description>' -TestCases $stdTestCases {
			param ($template, $description)
			$someModule = 'someModule'
			$namespace = 'someNS'
			$cmd = 'New-Frobdingnab'
			$inputText = $template -f $cmd
			Mock Get-CmdletDocLinks { return @{ } }
			Mock Get-Command `
				-MockWith { return @{
					ModuleName = $someModule
					Module = @{ Path = "$namespace\$someModule\$someModule.psm1"}
				} } `
				-ParameterFilter { $Name -eq $cmd }
			Init-Variables

			Add-Links 'currentModule' $inputText |
				Should Be "<li><a href='../../$namespace/$someModule/$cmd.html'>$cmd</a></li>"
		}

		It 'Generates no link for plain text with <description>' -TestCases $stdTestCases {
			param ($template, $description)
			$plainText = 'not a cmdlet'
			$inputText = $template -f $plainText
			Mock Get-CmdletDocLinks { return @{ } }
			Init-Variables

			Add-Links 'any' $inputText | Should Be "<li>$plainText</li>"
		}

		$testCases = @(
			@{ template = '[{0}]({1})'; description = 'no extra spaces'}
			@{ template = '[ {0}  ]({1})'; description = 'extra spaces in label'}
			@{ template = '[{0}](  {1} )'; description = 'extra spaces in url'}
			@{ template = '[{0}]  ({1})'; description = 'extra spaces between label and url'}
			@{ template = '[{0}]({1})  '; description = 'extra spaces at end of line'}
			@{ template = '  [{0}]({1})'; description = 'extra spaces at start of line'}
		)
		It 'Generates link for explicit link with label with <description>' -TestCases $testCases {
			param ($template, $description)
			$url = 'http://any.com'
			$label = 'explicit label'
			$inputText = $template -f $label, $url
			Mock Get-CmdletDocLinks { return @{ } }
			Init-Variables

			Add-Links 'any' $inputText | Should Be "<li><a href='$url'>$label</a></li>"
		}

		It 'Generates link for explicit link without label with <description>' -TestCases $stdTestCases {
			param ($template, $description)
			$url = 'http://any.com'
			$inputText = $template -f $url
			Mock Get-CmdletDocLinks { return @{ } }
			Init-Variables

			Add-Links 'any' $inputText | Should Be "<li><a href='$url'>$url</a></li>"
		}
	}

	Context 'Parameters' {
		$8space = '        '
		$stdProperties  = @(
			$8space
			"$($8space)Required?                    false"
			"$($8space)Position?                    3"
			"$($8space)Default value"
			"$($8space)Accept pipeline input?       false"
			"$($8space)Accept wildcard characters?  false"
		)
		$stdDescription = @(
			"$($8space)para one, line one."
			"$($8space)para one, line two."
			$8space
			"$($8space)para two."
		)

		function GenerateText([string]$paramName, [string[]]$description)
		{
			$text = ,"  -$paramName"
			if ($description) {
				$description | % { $text += $_ }
			}
			$stdProperties | % { $text += $_ }
			$text
		}

		It 'Emboldens parameter name by itself' {
			$paramName = 'SomeParam'
			$text = "  -$paramName"
			StylizeParameters $text | Should Be "  -<strong>$paramName</strong>"
		}

		It 'Emboldens parameter name with properties' {
			$paramName = 'SomeParam'
			(StylizeParameters (GenerateText $paramName)) -join '' |
				Should Match "^  -<strong>$paramName</strong>"
		}

		It 'Emboldens parameter name with description and properties' {
			$paramName = 'SomeParam'
			(StylizeParameters (GenerateText $paramName $stdDescription)) -join '' |
				Should Match "^  -<strong>$paramName</strong>"
		}

		It 'Separates parameter name from properties with blank line' {
			$paramName = 'SomeParam'
			$result = StylizeParameters (GenerateText $paramName)
			$result.Count | Should Be ($stdProperties.Count + 1)
			$result[0] | Should Match $paramName
			$result[1] | Should BeNullOrEmpty
			$result[2] | Should Match 'Required'
		}

		It 'Retains leading spaces on properties' {
			$paramName = 'SomeParam'
			(StylizeParameters (GenerateText $paramName)) -join '' |
				Should Match "$($8space)Required.*$($8space)Position.*$($8space)Default.*($8space)Accept pipeline.*($8space)Accept wildcard"
		}

		It 'Strips leading spaces from description but retains spaces on properties' {
			$paramName = 'SomeParam'
			$result = (StylizeParameters (GenerateText $paramName $stdDescription))
			$result.Count | Should Be ($stdProperties.Count + $stdDescription.Count +  1)

			$result[0] | Should Match $paramName

			$startingIndex = 1 # i.e. skip param name
			for ($i = 0; $i -lt $stdDescription.Length; $i++) {
				$result[$i+$startingIndex] |
					Should Be $stdDescription[$i].TrimStart() # i.e. spaces are now gone
			}

			$startingIndex = 1 + $stdDescription.Length # i.e. skip param name & desc

			$result[$startingIndex] | Should BeNullOrEmpty # spaces gone on blank line
			for ($i = 1; $i -lt $stdProperties.Length; $i++) {
				$result[$i+$startingIndex] |
					Should Be $stdProperties[$i] # i.e. spaces still present on non-empties
			}
		}
	}
}
}
