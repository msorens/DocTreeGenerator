DocTreeGenerator
=======

PowerShell's Get-Help gives you documentation for one cmdlet at a time but it does not provide any means to document your API in its entirety.
DocTreeGenerator fills that niche.
Once you have instrumented your modules with doc-comments to satisfy Get-Help,
you need surprisingly little extra work for DocTreeGenerator
to produce a comprehensive, hyperlinked documentation tree (in the form of a collection of web pages).

When you create your library code, whether it is in PowerShell or in C#, you need
to add documentation comments (doc-comments for short)
that may then be automatically extracted and formatted to generate some documentation.
If you are writing in PowerShell, those doc-comments are processed directly
by PowerShell when you invoke Get-Help on your cmdlet.
If you are writing in C#, you need to use a third party tool to pre-process
your doc-comments into a form that Get-Help can use--I highly recommend
XmlDoc2CmdletDoc for this purpose.
It reduces what used to be a tedious and difficult task of documenting C# cmdlet
libraries to the same effort needed for documenting PowerShell cmdlets--just
add appropriate doc-comments in your C# code.

Beyond those standard doc-comments instrumenting your code, for DocTreeGenerator
to do its job you need to provide just a few summary files as well
and perhaps tweak the HTML or CSS in the template to get the look and feel you want.


Installation
----------
1. Unzip DocTreeGenerator-master.zip into your PowerShell Modules directory ($env:UserProfile\Documents\WindowsPowerShell\Modules) and drop the "-master" suffix on the extracted folder.
2. Import the module in your profile or import it manually: `Import-Module DocTreeGenerator`

Usage
----------
See extensive help available from the single cmdlet in the module itself: `Get-Help Convert-HelpToHtmlTree`
Also see some practical examples and detailed notes on how to use it
on Simple-Talk.com: [How To Document Your PowerShell Library](https://www.simple-talk.com/sysadmin/powershell/how-to-document-your-powershell-library/)

You can see a real-world example of its use on my open source website, showing a tree complete with an index to all functions and modules:
[CleanCode PowerShell Libraries](http://cleancode.sourceforge.net/api/powershell/)
And adjacent to this "readme" file is a rendering of the help for Convert-HelpToHtmlTree itself (Convert-HelpToHtmlTree.html).

Notes
----------
DocTreeGenerator uses the output of Get-Help as its input; some of the vagaries of Get-Help can be compensated for, but not always. Known issues are itemized below. The designation [PS] applies to cmdlets written in PowerShell, while [C#] applies to cmdlets written in C#.

Other issues in this section are things to watch out for that might cause undo consternation.

1. [PS] You cannot have a preformatted block immediately following an example (a tab or 4+ leading spaces signals a preformatted line). If you do, the first line--in this example the column headers--will not be preformatted.
(You can observe this problem if you just run Get-Help for your cmdlet on the command-line.)

============ EXCERPT FROM A PS DOC-COMMENT SECTION ============================
.EXAMPLE
PS> Show-Packages .\default.proj
	Name              DependsOnTargets        CallTarget
	----              ----------------        ----------
	All                                       Clean;RestorePackages;Build
	Test              UnitTest;IntegrationTest
	Analyze
===============================================================================

Remedy:
Add a regular text paragraph between the line of code and the start of the preformatted block:
============ EXCERPT FROM A PS DOC-COMMENT SECTION ============================
.EXAMPLE
PS> Show-Packages .\default.proj
This line could say anything; mainly it is to fix Get-Help's formatting issue!
	Name              DependsOnTargets        CallTarget
	----              ----------------        ----------
	All                                       Clean;RestorePackages;Build
	Test              UnitTest;IntegrationTest
	Analyze
===============================================================================

2. [PS,C#] If you start a line with an asterisk, plus, or minus, you are asking to force a line break. (Presumably you are enumerating items in a list.) But watch out that you do not do this inadvertantly. (If, for example, you are talking about code you might mention a "-Force" option--just make sure that is not the first thing on the line, otherwise it will end the paragraph prematurely at that point.)

3. [PS,C#] If you start a line with a space, this also forces a line break. This is very useful, for example, if you want example code to span multiple lines in the HTML rendered output. Use a couple leading spaces on each line after the first that you want to start on a new line. (But do NOT use more than 3--otherwise you trigger generating a pre-formatted block, which is likely not what you want.)

4. [PS,C#] Also useful for code examples: start a line with "PS>", i.e. a canonical PowerShell prompt, and this also forces a line break. Thus, if you want to show multiple separate commands, start each line with "PS>". (Contrast that with if you want to show multiple piped commands, just use a leading space or two on each line per the previous point above.
