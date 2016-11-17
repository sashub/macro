/***

   Assigns a library from metadata, using the libref.
   To connect to the library, the library NAME is required.
   Assumes that a connection to metadata already exists..

  @author Allan Bowe @@
  
  $! Assumes that library exists in metadata! !$

***/

%macro assign_lib(libref=/* libref that needs to be assigned */
  );
%if %sysfunc(libref(&libref)) %then %do;
  data _null_;
    length lib_uri LibName $200;
    call missing(of _all_);
    nobj=metadata_getnobj("omsobj:SASLibrary?@Libref='&libref'",1,lib_uri);
    if nobj=1 then do;
       rc=metadata_getattr(lib_uri,"Name",LibName);
       call symputx('LIB',libname,'L');
    end;
    else if nobj>1 then putlog "ERROR: More than one library with libref='&libref'";
    else putlog "ERROR: Library '&libref' not found in metadata";
  run;

  libname &libref meta library="&lib";
  %if %sysfunc(libref(&libref)) %then 
    %put ERROR: assign_lib macro could not assign &libref;
%end;
%else %put NOTE: Library &libref is already assigned;
%mend;
