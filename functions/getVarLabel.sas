/***

  This function returns the label of a variable

  @author  Allan Bowe @@
  @version  9.3 @@

  @Usage
      data test;
         label str='My String' num='My Number' ;
         format str $1.  num datetime19. x 8.;
         stop;
      run;
      %put %getVarLabel(ds=test, var=str);
      %put %getVarLabel(ds=work.test, var=num);
      %put %getVarLabel(ds=test, var=x);
      %put %getVarLabel(ds=test, var=renegade);
  @@

  #macrofunction

***/


%macro getVarLabel(ds=sashelp.class /* two level ds name */
      , var= /* variable name for which to return the label */
    );
  %local dsid vnum vlabel rc;
  /* Open dataset */
  %let dsid = %sysfunc(open(&ds));
  %if &dsid > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    %if(&vnum. > 0) %then
       /* Variable exists, so get label */
       %let vlabel = %sysfunc(varlabel(&dsid, &vnum));
    %else %do;
       %put NOTE: Variable &var does not exist in &ds;
       %let vlabel = %str();
    %end;
  %end;
  %else %put dataset &ds not opened! (rc=&dsid);

  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));
  /* Return variable label */
  &vlabel
%mend;