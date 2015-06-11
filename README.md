# SAS Macro Library

This is an open-source repository for SAS Macros.  All files conform to the published standards.

STANDARDS
 - All macros should use keyword (not positional) parameters.  This allows for easier extension of functionality.
 - Lines should be kept within 80 characters.  
 - Files should have unix (LF) endings.   Unix files will open in Windows, but not vice-versa.
 - One macro per file, the filename should be the same as the macro name.
 - All filenames should be in lowercase.
 - If changed (and appropriate), system options should be returned to original settings
 - All local macro variables should be local in scope (%local)
 - All requirements in the DOCUMENTATION section should be followed
 
FOLDERS
Macros are categorised as follows:
 - function:  No SAS code is actually generated

DOCUMENTATION
 - Follows javadoc syntax
 - Should list any dependencies on non-sas macros
 - Should list the earliest version of SAS that it is compatible with (@version)
