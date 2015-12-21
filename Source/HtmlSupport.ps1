Set-StrictMode -Version Latest

function Join-HtmlPath([String[]]$path)
{
	$path -join "/"
}

function Get-HtmlLink($href, $value)
{
	"<a href='{0}'>{1}</a>" -f $href, $value
}

function Get-HtmlCell([String]$text, [int]$columnCount)
{
	if ($columnCount) {
		"     <td colspan='{0}' bgcolor='#CCCCCC'>{1}</td>" -f $columnCount, $text
	}
	else { "    <td>{0}</td>" -f $text }
}

function Get-HtmlRow([String[]]$items, [int]$columnCount)
{
	$cells = $items | % { Get-HtmlCell $_ $columnCount } | Out-String
	"  <tr>`n{0}  </tr>`n" -f $cells
}

function Get-HtmlTable([String[]]$items)
{
	"`n<table border='1'>`n{0}</table>`n" -f ($items | Out-String)
}

function Get-HtmlDiv([string[]]$text, $class)
{
	if ($class) { $class = (" class='{0}'" -f $class) }
	"<div{1}>`n{0}</div>`n" -f [string]::join("`n", $text), $class
}

function Get-HtmlSpan($text, $class)
{
	if ($class) { $class = (" class='{0}'" -f $class) }
	"<span{1}>{0}</span>" -f [string]::join("`n", $text), $class
}

function Get-HtmlPara([string[]]$text, $class)
{
	if ($class) { $class = (" class='{0}'" -f $class) }
	"<p{1}>{0}</p>`n" -f [string]::join("`n", $text), $class
}

function Get-HtmlPre($text)
{
	# allow for possible array with join
	"<pre>{0}</pre>" -f [string]::join("`n", $text)
}

function Get-HtmlBold([string]$text)
{
	"<strong>{0}</strong>" -f $text
}


function Get-HtmlHead($text, $level)
{
	"<h{0}>{1}</h{0}>`n" -f $level, $text
}

function Get-HtmlLineBreak()
{
	"<br/>"
}

function Get-HtmlBreadCrumbs([String[]] $items)
{
	$items -join " &raquo; "
}

function Get-HtmlListItem($text)
{
	"<li>{0}</li>" -f $text
}

function Get-HtmlList($list)
{
	if ($list) {
	"<ul>`n{0}`n</ul>" -f [string]::join("`n", $list) }
}

function HtmlEncode($text)
{
	# The full [System.Web.HttpUtility]::HtmlEncode() method would do too much,
	# eradicating newlines in particular. This is sufficient here.
	$text -replace "<", "&lt;" -replace ">", "&gt;" 
}

function HtmlEncodeAndStylizeSyntax($text)
{
	$text -replace '<(.*?)>','<i>&lt;$1&gt;</i>' `
		-replace '^\s*(\S+)','<b>$1</b>'
}

