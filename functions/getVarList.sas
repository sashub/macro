/***
  Macro to get a list of variables directly from a dataset.
  WAY faster than dictionary tables or sas views, and can 
    also be called in macro logic (is pure macro).
  Default is to have space delimited variable names in &MyGlobalVar.
    
  @author Allan Bowe @@
  @version 9.2 @@
  @usage
    %put %getVarList(libds=sashelp.class);
  @@ 

  #macrofunction

***/

%macro getVarList(libds=sashelp.class /* two level name */
      ,dlm=%str( ) /* provide delimeter (eg comma or space) to separate vars */
    );
  /* declare local vars */
  %local outvar dsid nvars x rc dlm;

  /* open dataset in macro */
  %let dsid=%sysfunc(open(&libds));

  %if &dsid %then %do;
    %let nvars=%sysfunc(attrn(&dsid,NVARS));
    %if &nvars>0 %then %do;
      /* add first dataset variable to global macro variable */
      %let outvar=%sysfunc(varname(&dsid,1));
      /* add remaining variables with supplied delimeter */
      %do x=2 %to &nvars;
        %let outvar=&outvar.&dlm%sysfunc(varname(&dsid,&x));
      %end;
    %End;
    %let rc=%sysfunc(close(&dsid));
  %end;
  %else %do;
    %put unable to open &libds (rc=&dsid);
    %let rc=%sysfunc(close(&dsid));
  %end;
  /* return the value */
  &outvar
%mend;
