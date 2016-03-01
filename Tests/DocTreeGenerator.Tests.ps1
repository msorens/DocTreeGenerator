Import-Module "$PSScriptRoot\..\DocTreeGenerator.psd1" -force

InModuleScope DocTreeGenerator {

$2space = ' ' * 2
$4space = ' ' * 4
$8space = ' ' * 8

function Stringify([string[]]$text, [switch]$stripHtml)
{
	 $result = $text -join '' -replace "`r" -replace "`n"
	 if ($stripHtml) { $result -replace '<.*?>' }
	 else { $result }
}

function StripLineBreaks([string]$text)
{
	$text -replace "`r`n"
}

function SplitToArray([string]$text)
{
	$text -split "`r`n"
}

Describe 'Convert-HelpToHtmlTree' {

	Context 'Body/links' {

		Mock Write-Host
		Mock Get-CmdletDocLinks
		Mock Get-Template { "any" }
		Init-Variables

		BeforeEach {
			$stdSections  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				'RELATED LINKS' = ''
			}
			$stdSectionOrder = @(
				'NAME'
				'SYNOPSIS'
				'SYNTAX'
				'DESCRIPTION'
				'PARAMETERS'
				'INPUTS'
				'OUTPUTS'
				'EXAMPLES'
				'RELATED LINKS'
			)
		}

		It 'Reports no links if no links present' {
			$result = Stringify (ConvertTo-Body $stdSections $stdSectionOrder 'any') -stripHtml
			$result | Should Match 'RELATED LINKS-none-'
		}

		It 'Reports one link if link present' {
			$stdSections['RELATED LINKS'] = 'foo'
			$result = Stringify (ConvertTo-Body $stdSections $stdSectionOrder 'any')
			$result | Should Match ('RELATED LINKS.*' + (Get-HtmlListItem 'foo'))
		}

		It 'Reports multiple links if links present' {
			$stdSections['RELATED LINKS'] = 'foo','bar'
			$result = Stringify (ConvertTo-Body $stdSections $stdSectionOrder 'any') 
			$result | Should Match ('RELATED LINKS.*' + (Get-HtmlListItem 'foo') + (Get-HtmlListItem 'bar'))
		}

		It 'Reports description present when present' {
			$stdSections.DESCRIPTION = 'my description here'
			$result = Stringify (ConvertTo-Body $stdSections $stdSectionOrder 'any') 
			$result | Should Match ("DESCRIPTION.*" + (Stringify (Get-HtmlDiv $stdSections.DESCRIPTION)))
		}

		It 'Reports description missing when missing' {
			$source = 'mySource'
			$stdSections.Remove('DESCRIPTION')
			$stdSections.NAME[0] = $source
			$stdSectionOrder = $stdSectionOrder | ? { $_ -ne 'DESCRIPTION' }
			$result = Stringify (ConvertTo-Body $stdSections $stdSectionOrder 'any') 
			$result | Should Match "DESCRIPTION.*missing description.*$source"
		}
	}

	Context 'Body/examples' {

		Mock Write-Host
		Mock Get-CmdletDocLinks
		Mock Get-Template { "any" }
		Init-Variables

		$cmd = 'Get-Foobar'
		$cmdStyle = $CSS_PS_CMD
		$docStyle = $CSS_PS_DOC_SECTION 
		$exampleHeader = '<h2>EXAMPLES</h2>'

		$stdExample1 = '    -------------------------- EXAMPLE 1 --------------------------',
   			'',
		    "    $cmd",
			'',
			'',
		    '    This gets the foobar for the current shebang.'

		$stdExample2 = '    -------------------------- EXAMPLE 2 --------------------------',
			'',
		    '    Get-SomethingElse',
			'',
			'',
		    '    This gets the foobar for the current shebang.'

		$multiLineToSingleLine = '    -------------------------- EXAMPLE 1 --------------------------',
			'',
		    '    Get-Something1 |',
		    '    Get-Something2',
			'',
			'',
		    '    This gets the foobar for the current shebang.'

		# Add a crucial leading space (at least one, less than four, in front of second line)
		$multilineToMultiLine = '    -------------------------- EXAMPLE 1 --------------------------',
			'',
		    '    Get-Something1 |',
		    '     Get-Something2',
			'',
			'',
		    '    This gets the foobar for the current shebang.'

		$multilineWithPrompts = '    -------------------------- EXAMPLE 1 --------------------------',
			'',
		    '    Get-Something1 | Got-Something',
		    '    PS> Get-Something2',
			'',
			'',
		    '    This gets the foobar for the current shebang.'

		It 'Adds example header in front of first example when just one example' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $stdExample1
			}
			$expected = @"
<div class=['"]$docStyle['"]>
\s*$exampleHeader
\s*<div>
\s*<br/>
\s*\S+\s*----+ EXAMPLE 1 ----+
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'Adds example header in front of first example with multiple examples' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $stdExample1,'','',$stdExample2
			}
			$expected = @"
<div class=['"]$docStyle['"]>
\s*$exampleHeader
\s*<div>
\s*<br/>
\s*\S+\s*----+ EXAMPLE 1 ----+
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'Wraps command in span element' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $stdExample1
			}
			$expected = @"
<span class=['"]$cmdStyle['"]>$cmd</span>
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'Adds 2 breaks after the example header before the command' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $stdExample1
			}
			$expected = @"
----+ EXAMPLE 1 ----+\S+
\s*<br/>
\s*<br/>
\s*.*$cmd
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'Adds 2 breaks after the command before the description' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $stdExample1
			}
			$expected = @"
$cmd\S+
\s*<br/>
\s*<br/>
\s*This gets the foobar for the current shebang.
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'treats multiple standard lines as a single paragraph (like a browser would)' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $multiLineToSingleLine
			}
			$expected = @"
<span class=['"]$cmdStyle['"]>\s*Get-Something1 \|\s*Get-Something2\s*</span>
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'Wraps multi-line command in span element' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $multiLineToMultiLine
			}
			$expected = @"
<span class=['"]$cmdStyle['"]>\s*Get-Something1 \|\s*<br/>\s*Get-Something2\s*</span>
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

		It 'treats multiple lines with ps prompt as multiple paragraphs' {
			$examples  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				EXAMPLES = $multilineWithPrompts
			}
			$expected = @"
<span class=['"]$cmdStyle['"]>\s*Get-Something1 \| Got-Something<br/>\s*PS&gt; Get-Something2\s*</span>
"@
			$result = Stringify (ConvertTo-Body $examples EXAMPLES 'any')

			$result | Should Match (StripLineBreaks $expected)
		}

	}

	Context 'Body/parameters' {

		Mock Write-Host
		Mock Get-CmdletDocLinks
		Mock Get-Template { "any" }
		Init-Variables

		BeforeEach {
			$stdSections  = @{
				NAME = @('any')
				DESCRIPTION = 'any'
				PARAMETERS = '    -Param1 <PSObject[]>',
					'        List of project items ',
					'        used by the project`',
					'        in the course of its work.',
					'        ',
					'        Required?                    false',
					'        Position?                    1',
					'        Default value                $auditItems',
					'        Accept pipeline input?       false',
					'        Accept wildcard characters?  false',
					'        ',
					'    -TestFilter <String>',
					'        This parameter is not used here.',
					'        ',
					'        Required?                    false',
					'        Position?                    2',
					'        Default value                ',
					'        Accept pipeline input?       false',
					'        Accept wildcard characters?  false',
					'        ',
					'    <CommonParameters>',
					'        This cmdlet supports the common parameters: Verbose, Debug,',
					'        ErrorAction, ErrorVariable, WarningAction, WarningVariable,',
					'        OutBuffer, PipelineVariable, and OutVariable. For more information, see ',
					'        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).',
					'        '
			}
			$stdSectionOrder = @(
				'NAME'
				'SYNOPSIS'
				'SYNTAX'
				'DESCRIPTION'
				'PARAMETERS'
				'INPUTS'
				'OUTPUTS'
				'EXAMPLES'
				'RELATED LINKS'
			)
		}
		$expected = (@('<h2>PARAMETERS</h2>',
			'<div>',
			'<br/>',
			'    -<strong>Param1 &lt;PSObject[]&gt;</strong>',
			'<br/>',
			'      List of project items ',
			'used by the project`',
			'in the course of its work.',
			'<br/>',
			'<br/>',
			'<pre>        Required?                    false</pre>',
			'<pre>        Position?                    1</pre>',
			'<pre>        Default value                $auditItems</pre>',
			'<pre>        Accept pipeline input?       false</pre>',
			'<pre>        Accept wildcard characters?  false</pre>',
			'<br/>',
			'    -<strong>TestFilter &lt;String&gt;</strong>',
			'<br/>',
			'      This parameter is not used here.',
			'<br/>',
			'<br/>',
			'<pre>        Required?                    false</pre>',
			'<pre>        Position?                    2</pre>',
			'<pre>        Default value                </pre>',
			'<pre>        Accept pipeline input?       false</pre>',
			'<pre>        Accept wildcard characters?  false</pre>',
			'<br/>',
			'    &lt;CommonParameters&gt;',
			'<pre>        This cmdlet supports the common parameters: Verbose, Debug,</pre>',
			'<pre>        ErrorAction, ErrorVariable, WarningAction, WarningVariable,</pre>'
			'<pre>        OutBuffer, PipelineVariable, and OutVariable. For more information, see </pre>',
			'<pre>        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).</pre>',
			'<br/></div>'
		) -join '') -replace '[$[+*?()\\.]','\$&'

		It 'xxx' {
			$result = Stringify (ConvertTo-Body $stdSections $stdSectionOrder 'any')

			$result | Should Match $expected
		}
	}

	Context 'Indenting and line breaks' {

		It 'omits break for single words' {
			$text = 'one', 'two', 'three'
			(ApplyLineBreaks $text) -join ' ' |
			Should Be 'one two three'
		}

		It 'omits break for multiple words' {
			$text = 'one word', 'two words', 'three words'
			(ApplyLineBreaks $text) -join ' ' |
			Should Be 'one word two words three words'
		}

		It 'omits break for normal text' {
			$text = 'one word.', 'two words?', 'three words,', 'done'
			(ApplyLineBreaks $text) -join ' ' |
			Should Be 'one word. two words? three words, done'
		}

		It 'omits break for text with less than 4 header characters' {
			$text = 'one word.', 'it -- the green one --', 'is true'
			(ApplyLineBreaks $text) -join ' ' |
			Should Be 'one word. it -- the green one -- is true'
		}

		It 'includes auto-break after header-like text' {
			$text = 'title1 ----', 'title2 ====', 'title3 ####'
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/><strong>title1 ----</strong><br/><strong>title2 ====</strong><br/><strong>title3 ####</strong><br/>'
		}

		It 'includes auto-break after header-like text plus extra whitespace at the end' {
			$text = 'title1---- ', "title2 ====`t", 'plain text'
			(ApplyLineBreaks $text) -join '' |
			Should Be "<br/><strong>title1---- </strong><br/><strong>title2 ====`t</strong><br/>plain text"
		}

		It 'includes auto-break before and after header-like text' {
			$text = '---- title1 ----', '====title2===='
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/><strong>---- title1 ----</strong><br/><strong>====title2====</strong><br/>'
		}

		It 'includes auto-break before header-like text' {
			$text = '---- title1', '==== title2'
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/><strong>---- title1</strong><br/><strong>==== title2</strong><br/>'
		}

		It 'includes auto-break before header-like text plus extra whitespace at the start' {
			$text = ' ---- title1', '  ====== title2', 'plain text'
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/><strong> ---- title1</strong><br/><strong>  ====== title2</strong><br/>plain text'
		}

		It 'uses preformat block for single indented line' {
			$text = ($8space + 'one'), ($4space + 'two')
			(ApplyLineBreaks $text) -join '' |
			Should Be '<pre>        one</pre>    two'
		}

		It 'uses preformat block for multiple indented lines' {
			$text = ($8space + 'one'), ($8space + 'two')
			(ApplyLineBreaks $text) -join '' |
			Should Be '<pre>        one</pre><pre>        two</pre>'
		}

		It 'includes auto-break for list-like text with no preamble' {
			$text = '* item1', '- item2', '+ item3'
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/>* item1<br/>- item2<br/>+ item3'
		}

		It 'includes auto-break for list-like text with immediate preamble' {
			$text = 'my list:','* item1', '- item2', '+ item3'
			(ApplyLineBreaks $text) -join '' |
			Should Be 'my list:<br/>* item1<br/>- item2<br/>+ item3'
		}

		It 'includes auto-break for list-like text with whitespace after preamble' {
			$text = 'my list:','','','* item1', '- item2', '+ item3'
			(ApplyLineBreaks $text) -join '' |
			Should Be 'my list:<br/><br/>* item1<br/>- item2<br/>+ item3'
		}

		It 'includes auto-break for list-like text plus extra whitespace at start' {
			$text = '    * item1', '      - item2', '      + item3'
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/>    * item1<br/>      - item2<br/>      + item3'
		}

		It 'no line breaks with standard 4-space indent produced by Get-Help' {
			$text = ($4space+'line one'), ($4space+'line two'), ($4space+'line three')
			(ApplyLineBreaks $text) -join '' |
			Should Be '    line one    line two    line three'
		}

		$testCases = @(
			@{ spaces = ' '; description = '1' }
			@{ spaces = '  '; description = '2' }
			@{ spaces = '   '; description = '3' }
		)
		It 'includes auto-break for <description> leading spaces beyond standard 4-space indent' -testcases $testCases {
			param ($spaces)
			$text = ($4space+'line one'), ($4space+$spaces+'line two'), ($4space+'line three')
			(ApplyLineBreaks $text) -join '' |
			Should Be "${4space}line one<br/>${4space}${spaces}line two${4space}line three"
		}

		It 'includes auto-break for ps prompt on second line' {
			$text = '    cmdlet1', '    PS&gt; cmdlet2'
			(ApplyLineBreaks $text) -join '' |
			Should Be "${4space}cmdlet1<br/>${4space}PS&gt; cmdlet2"
		}

		It 'applies double-space for a blank line' {
			$text = 'one','','two'
			(ApplyLineBreaks $text) -join '' |
			Should Be 'one<br/><br/>two'
		}
		It 'applies just one double-space for multiple blank lines' {
			$text = 'one','','','','two'
			(ApplyLineBreaks $text) -join '' |
			Should Be 'one<br/><br/>two'
		}
		It 'applies just one double-space for list item followed by blank line' {
			$text = '* item1', '* item2', '','next para...'
			(ApplyLineBreaks $text) -join '' |
			Should Be '<br/>* item1<br/>* item2<br/><br/>next para...'
		}
		It 'omits break following a pre-formatted item' {
			$text = ($8space + 'one'), '------ header ----'
			(ApplyLineBreaks $text) -join '' |
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
			@{ inputText = 'not a cmdlet'; description = 'multiple words'}
			@{ inputText = 'one_word'; description = 'single word'}
			@{ inputText = '!#$@'; description = 'stray characters'}
		)
		It 'Generates no link for plain text with <description>' -TestCases $testCases {
			param ($inputText, $description)
			Mock Get-CmdletDocLinks { return @{ } }
			Init-Variables

			Add-Links 'any' $inputText | Should Be "<li>$inputText</li>"
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
			CorrectParamIndents $text | Should Be "  -<strong>$paramName</strong>"
		}

		It 'Emboldens parameter name with properties' {
			$paramName = 'SomeParam'
			(CorrectParamIndents (GenerateText $paramName)) -join '' |
				Should Match "^  -<strong>$paramName</strong>"
		}

		It 'Emboldens parameter name with description and properties' {
			$paramName = 'SomeParam'
			(CorrectParamIndents (GenerateText $paramName $stdDescription)) -join '' |
				Should Match "^  -<strong>$paramName</strong>"
		}

		It 'Separates parameter name from properties with blank line' {
			$paramName = 'SomeParam'
			$result = CorrectParamIndents (GenerateText $paramName)
			$result.Count | Should Be ($stdProperties.Count + 1)
			$result[0] | Should Match $paramName
			$result[1] | Should Match '^\s*$'
			$result[2] | Should Match 'Required'
		}

		It 'Does not separate parameter name from description with blank line' {
			$paramName = 'SomeParam'
			$result = CorrectParamIndents (GenerateText $paramName $stdDescription)
			$result.Count | Should Be ($stdProperties.Count + 1 + $stdDescription.Count)
			$result[0] | Should Match $paramName
			$result[1] | Should Match ($stdDescription[0] -replace $8space)
		}

		It 'Separates description from properties with blank line' {
			$descCount = $stdDescription.Count
			$paramName = 'SomeParam'
			$result = CorrectParamIndents (GenerateText $paramName $stdDescription)
			$result[$descCount] | Should Be ($stdDescription[$descCount-1] -replace $8space)
			$result[$descCount+1] | Should BeNullOrEmpty
			$result[$descCount+2] | Should Match 'Required'
		}

		It 'Removes leading spaces on description except for the first line' {
			$descCount = $stdDescription.Count
			$paramName = 'SomeParam'
			$result = CorrectParamIndents (GenerateText $paramName $stdDescription)
			$result[1] | Should Be ($stdDescription[0] -replace $8space, "${4space}${2space}")
			2..$descCount | % { $result[$_] | Should be ($stdDescription[$_-1] -replace $8space) }
		}

		It 'Retains leading spaces on properties when no description' {
			$paramName = 'SomeParam'
			(CorrectParamIndents (GenerateText $paramName)) -join '' |
				Should Match "$($8space)Required.*$($8space)Position.*$($8space)Default.*($8space)Accept pipeline.*($8space)Accept wildcard"
		}

		It 'Retains leading spaces on properties when description present' {
			$descCount = $stdDescription.Count
			$paramName = 'SomeParam'
			$result = CorrectParamIndents (GenerateText $paramName $stdDescription)
			1..($stdProperties.Length-1) | % {
				$result[$descCount+1+$_] | Should Be $stdProperties[$_]
			}
		}
	}
}

}
