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
![CleanCode PowerShell Libraries](http://cleancode.sourceforge.net/api/powershell/)
And adjacent to this "readme" file is a rendering of the help for Convert-HelpToHtmlTree itself:
![DocTreeGenerator API](https://github.com/msorens/DocTreeGenerator/Convert-HelpToHtmlTree.html)

