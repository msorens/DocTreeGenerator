## Next Release

## 2.0.08 (June 10, 2017)

IMPROVEMENTS:
  - Updated module manifest to latest PS5 template (from New-ModuleManifest)
  - Centralized exported functions list to manifest for PSGallery compatibility
  - Filled in manifest to support release to PSGallery


## 2.0.07 (December 22, 2016)

IMPROVEMENTS:
  - Added Publish-ModuleDocumentationTree for more easily automating
    documentation generation for several modules under a single namespace.
  - Added Copy-Module cmdlet to support above.


## 2.0.06 (June 14, 2016)

IMPROVEMENTS:
  - Report more specific errors when no namespaces are found.
  - Added -SourceDir parameter to allow  modules located in an arbitrary
    directory. [#4](https://github.com/msorens/DocTreeGenerator/issues/4)


BUG FIXES:
  - If custom function listed as a related link was not found, it previously
    generated an invalid URL on the hyperlink for it.
	Changed to just emit the custom function name as plain text.


## 2.0.05 (April 19, 2016)

IMPROVEMENTS:
  - Report more specific errors when problems with an overview file are encountered.
  - Added template and script for regenerating self-documentation (i.e. DocTreeGenerator itself).

BUG FIXES:
  - Overview files were not returning valid results with a DocType definition (DTD) present. [#3](https://github.com/msorens/DocTreeGenerator/issues/3)



## 2.0.04 (March 1, 2016)

IMPROVEMENTS:
  - In conjunction with fixing multi-line code examples (below),
    changed list items (beginning with plus, minus, asterisk) to still
	emit a <br> before the line but removed emitting one after the line.
  - Also for code examples, added emitting a <br> before a canonical
    PowerShell prompt (PS>).

BUG FIXES:
  - Module properties used in template might appear with multiple values
    if module being documented was already loaded in the PowerShell host.
  - Code examples with more than one line of code had several HTML generation
    issues. 


## 2.0.03 (January 31, 2016)

ADMINISTRATIVE:
  - Corrected encoding for manifest (changed from Unicode to ASCII).
  - Removed stray formatting character from read me interfering with a URL.
  - Updated version in the manifest to reflect the release number.

BUG FIXES:
  - Check for missing module description was failing intermittently.


## 2.0.02 (January 5, 2016)

IMPROVEMENTS:
  - Report missing cmdlet documentation (proxied by missing Description section).
  - Add support for build systems/continuous integration with -EnableExit.

BUG FIXES:
  - Corrected link resolver to treat single words as plain text rather than a cmdlet name.
  - Correct rendering of HTML-special characters in syntax section.
  - Resynced link to DocTreeGenerator in template to new GitHub location.
  - Resynced template path after file reorganization.



## 2.0.01 (December 21, 2015)

Migrated from http://cleancode.sourceforge.net/

IMPROVEMENTS:
  - Add support for documenting binary cmdlets (those written in C#)
  - Stylize syntax section (embolden cmdlet name, italicize parameter types)
  - Improve support for text layout:
    > recognize lists and add line breaks
	> recognize headers and add line breaks and apply style tag.
	> recognize code segments and apply style tag.
	> flow and wrap body text for description and for parameters.
  - Add unit tests.
  - Update license.

