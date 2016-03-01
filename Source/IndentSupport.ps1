Set-StrictMode -Version Latest

function ApplyLineBreaks ([string[]]$text)
{
	$listMarks = '*+-'
	$headerMarks = '=_+*#~-'
	$codeMarker = HtmlEncode 'PS>'
	$blanks = 0; # tracks consecutive blank lines in input
	$breaks = 0; # tracks breaks emitted in output
	$lineBreak = Get-HtmlLineBreak
	$text | % {
		if ($_ -match '^\s*$') {
			if ($blanks++ -eq 0) { EmitBreaksTo 2; $breaks = 2 } # add just one in HTML
		}
		else {
			$blanks = 0
			# Output of Get-Help will have a 4-char lead-in on every line
			if ($_ -match '^\s{4}(?:\s{4}|\t)') {
				Get-HtmlPre $_
				$breaks = 1 # <pre> counts as a break!
			}
			elseif ($_ -match "^\s*[$headerMarks]{4}|[$headerMarks]{4}\s*$") {
				EmitBreaksTo 1
				Get-HtmlBold $_
				$lineBreak
				$breaks = 1
			}
			elseif ($_ -match "^\s{5,}|^\s*[$listMarks]|^\s*$codeMarker") {
				# Lines starting with leading space just get a <br/>, no <pre>.
				# That 5 above is 4 (what PS always adds) plus 1 additional, real space.
				# Works for 1, 2, or 3 real spaces; at 4 the pre-formatted block above kicks in instead.
				EmitBreaksTo 1
				$_
				$breaks = 0
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
	$SEEK_FIRST_DESC_LINE = 2
	$SEEK_FIRST_PROPERTY_LINE = 1
	$SEEK_NEW_PARAM_LINE = 0

	$state = $SEEK_NEW_PARAM_LINE 
	$text | % {
		if ($_ -match '^(\s*-)(.+)') {
			$state = $SEEK_FIRST_DESC_LINE
			$Matches[1] + (Get-HtmlBold $Matches[2]) # add some highlight to parameter name and type
		}
		elseif ($state -ne $SEEK_NEW_PARAM_LINE -and $_ -match '^\s*Required\?') { # Constant after description
			$state = $SEEK_NEW_PARAM_LINE 
			$_ # be sure to emit it, too!
		}
		elseif ($state -ne $SEEK_NEW_PARAM_LINE -and $_ -match '^\s*(.*)') {
			if ($state -eq $SEEK_FIRST_DESC_LINE) {
				$state = $SEEK_FIRST_PROPERTY_LINE
				# Want some leading space on FIRST description line to get a line break.
				# Here we start with 4 to match everything else Get-Help provided, then add 2.
				(' '*6)+$Matches[1]
			}
			else { $Matches[1] } # remove the leading spaces here so it becomes regular, wrapped text in HTML
		}
		else { $_ }
	}
}

function EmitBreaksTo([int]$count)
{
	$lineBreak = Get-HtmlLineBreak
	while ($breaks++ -lt $count) { $lineBreak }
}

