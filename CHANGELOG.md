## Next Release

FEATURES:

IMPROVEMENTS:

BUG FIXES:


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

