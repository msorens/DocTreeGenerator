Import-Module .\DocTreeGenerator.psd1 -force

InModuleScope DocTreeGenerator {

$eightSpaces = ' ' * 8

$ErrorActionPreference = 'stop'

Describe "Convert-HelpToHtmlTree" {

	Context "Indenting and line breaks" {

		It "omits break for single words" {
			$text = 'one', 'two', 'three'
			(ApplyIndents $text) -join ' ' | Should Be 'one two three'
		}

		It "omits break for multiple words" {
			$text = 'one word', 'two words', 'three words'
			(ApplyIndents $text) -join ' ' | Should Be 'one word two words three words'
		}

		It "omits break for normal text" {
			$text = 'one word.', 'two words?', 'three words,', 'done'
			(ApplyIndents $text) -join ' ' | Should Be 'one word. two words? three words, done'
		}

		It "includes auto-break after header-like text" {
			$text = 'title1 ---', 'title2 =', 'title3 ###'
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong>title1 ---</strong><br/><strong>title2 =</strong><br/><strong>title3 ###</strong><br/>'
		}

		It "includes auto-break after header-like text plus extra whitespace at the end" {
			$text = 'title1 - ', "title2 ==`t", 'plain text'
			(ApplyIndents $text) -join '' |
			Should Be "<br/><strong>title1 - </strong><br/><strong>title2 ==`t</strong><br/>plain text"
		}

		It "includes auto-break before and after header-like text" {
			$text = '--- title1 ---', '==title2=='
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong>--- title1 ---</strong><br/><strong>==title2==</strong><br/>'
		}

		It "includes auto-break before header-like text" {
			$text = '--- title1', '= title2'
			(ApplyIndents $text) -join '' |
			Should Be '<br/><strong>--- title1</strong><br/><strong>= title2</strong><br/>'
		}

		It "includes auto-break before header-like text plus extra whitespace at the start" {
			$text = ' ---- title1', '  == title2', 'plain text'
			(ApplyIndents $text) -join '' |
			Should Be "<br/><strong> ---- title1</strong><br/><strong>  == title2</strong><br/>plain text"
		}

		It "uses preformat block for indented lines" {
			$text = ($eightSpaces + 'one'), ($eightSpaces + 'two')
			(ApplyIndents $text) -join '' | Should Be '<pre>        one</pre><pre>        two</pre>'
		}

		It "includes auto-break for list-like text with no preamble" {
			$text = '* item1', '- item2', '+ item3'
			(ApplyIndents $text) -join '' | Should Be '<br/>* item1<br/>- item2<br/>+ item3<br/>'
		}

		It "includes auto-break for list-like text with immediate preamble" {
			$text = 'my list:','* item1', '- item2', '+ item3'
			(ApplyIndents $text) -join '' | Should Be 'my list:<br/>* item1<br/>- item2<br/>+ item3<br/>'
		}

		It "includes auto-break for list-like text with whitespace after preamble" {
			$text = 'my list:','','','* item1', '- item2', '+ item3'
			(ApplyIndents $text) -join '' |
			Should Be 'my list:<br/><br/>* item1<br/>- item2<br/>+ item3<br/>'
		}

		It "includes auto-break for list-like text plus extra whitespace at start" {
			$text = '    * item1', '      - item2', '      + item3'
			(ApplyIndents $text) -join '' |
			Should Be '<br/>    * item1<br/>      - item2<br/>      + item3<br/>'
		}

		It "applies double-space for a blank line" {
			$text = 'one','','two'
			(ApplyIndents $text) -join '' | Should Be 'one<br/><br/>two'
		}
		It "applies just one double-space for multiple blank lines" {
			$text = 'one','','','','two'
			(ApplyIndents $text) -join '' | Should Be 'one<br/><br/>two'
		}
		It "applies just one double-space for list item followed by blank line" {
			$text = '* item1', '* item2', '','next para...'
			(ApplyIndents $text) -join '' | Should Be '<br/>* item1<br/>* item2<br/><br/>next para...'
		}
		It "omits break following a pre-formatted item" {
			$text = ($eightSpaces + 'one'), '--- header ---'
			(ApplyIndents $text) -join '' |
			Should Be '<pre>        one</pre><strong>--- header ---</strong><br/>'
		}

	}

	Context "Template available" {
		Mock Get-Content

		It "Uses default if none supplied" {
			Get-Template $null 'default'
			Assert-MockCalled Get-Content 1 { $Path -eq 'default' } -Scope It
		}

		It "Uses supplied value when default supplied" {
			Get-Template 'foo' 'default'
			Assert-MockCalled Get-Content 1 { $Path -eq 'foo' } -Scope It
		}

		It "Uses supplied value when default not supplied" {
			Get-Template 'foo'
			Assert-MockCalled Get-Content 1 { $Path -eq 'foo' } -Scope It
		}
	}

	Context "Template not available" {
		It "Reports error if template not found" {
			{ Get-Template 'any' } | Should Throw 'Cannot find path'
		}
	}

}
}
