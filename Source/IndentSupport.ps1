Set-StrictMode -Version Latest

function ApplyLineBreaks ([string[]]$text)
{
	$listMarks = '*+-'
	$headerMarks = '=_+*#~-'
	$blanks = 0; # tracks consecutive blank lines in input
	$breaks = 0; # tracks breaks emitted in output
	$lineBreak = Get-HtmlLineBreak
	$text | % {
		if ($_ -match '^\s*$') {
			if ($blanks++ -eq 0) { EmitBreaksTo 2; $breaks = 2 } # add just one in HTML
		}
		else {
			$blanks = 0
			# Most lines (output of Get-Help) will have a 4-char indent 
			if ($_ -match '^\s{4}(?:\s{4}|\t)') { # <pre> counts as a break!
				Get-HtmlPre $_
				$breaks = 1
			}
			elseif ($_ -match "^\s*[$headerMarks]{4}|[$headerMarks]{4}\s*$") {
				EmitBreaksTo 1
				Get-HtmlBold $_
				$lineBreak
				$breaks = 1
			}
			elseif ($_ -match "^\s*[$listMarks]") {
				EmitBreaksTo 1
				$_
				$lineBreak
				$breaks = 1
			}
			else  {
				$_
			   	$breaks = 0
			}
		}
	}
}

function CorrectParamIndents([string[]]$text)
{
	$inParamDescription = $false
	$text | % {
		if ($_ -match '^(\s*-)(.+)') {
			$inParamDescription = $true
			$Matches[1] + (Get-HtmlBold $Matches[2]) # add some highlight
		}
		elseif ($inParamDescription -and $_ -match '^\s*Required\?') { # Constant after description
			$inParamDescription = $false
			$_ # be sure to emit it, too!
		}
		elseif ($inParamDescription -and $_ -match '^\s*(.*)') {
		   	$Matches[1] # remove the leading spaces here so it becomes regular, wrapped text
		}
		else { $_ }
	}
}

function EmitBreaksTo([int]$count)
{
	$lineBreak = Get-HtmlLineBreak
	while ($breaks++ -lt $count) { $lineBreak }
}

