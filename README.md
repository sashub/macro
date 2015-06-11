# SAS Macro Library

This is an open-source repository for SAS Macros.  All files conform to the published standards.

STANDARDS
 - All macros should use keyword (not positional) parameters.  This allows for easier extension of functionality.
 - Lines should be kept within 90 characters.  
 - Files should have unix (LF) endings.   Unix files will open in Windows, but not vice-versa.
 - One macro per file, the filename should be the same as the macro name.
 - All filenames should be in lowercase.
 - If changed (and appropriate), system options should be returned to original settings
 - All local macro variables should be local in scope
