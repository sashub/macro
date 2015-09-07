/***
  Batch macro to be called on STP entry / exit
  see:  http://support.sas.com/kb/39/250.html
  Should not be called otherwise..
  
  @author Allan Bowe@@
  @version 9.2@@
  
  @USAGE
    %stp_logger(status_cd=SrvExit);
    @@
    
  @dependencies
    assign_lib.sas
  @@

  $!  requires a base table, preferably non SAS (to avoid locks), in the
        following format:
        
     CREATE TABLE [dbo].[STP_LOGGER](
          [PROCESSED_DTTM] [datetime2](3) NOT NULL,
	  [STATUS_CD] [char](8) NOT NULL,
	  [_PROGRAM] [char] (500) NOT NULL,
          [_METAPERSON] [char] (100) NOT NULL,
          [SYSJOBID] [char] (12) NOT NULL,
          [_SESSIONID] [char] (50) NULL,
          [GLOB_VARS] [char] (2000) NULL
          
   !$

***/



%macro stp_logger(status_cd= /* $8. values such as SrvEnter or PgmEnter */
      );
  %local global_vars;
  proc sql noprint;
  select cats(name,'=',value)
    into: global_vars
    separated by '|'
    from  dictionary.macros
    where scope = 'GLOBAL'
      and substr(name,1,3) not in('SYS', 'SQL','SAS')
      and substr(name,1,1) ne '_';

  %assign_lib(libref=web);
  proc datasets library=work; delete append; run;
  data append /view=append;
    if 0 then set web.stp_logger;
    PROCESSED_DTTM=%sysfunc(datetime());
    STATUS_CD="&status_cd";
    _PROGRAM="&_program";
    _METAPERSON="&_metaperson";
    SYSJOBID="&sysjobid";
  %if not %symexist(_SESSIONID) %then %do;
    /* session id is stored in the replay variable but needs to be extracted */
    _replay=symget('_replay');
    _replay=subpad(_replay,index(_replay,'_sessionid=')+11,length(_replay));
    index=index(_replay,'&')-1;
    if index=-1 then index=length(_replay);
    _replay=substr(_replay,1,index);
    _SESSIONID=_replay;
    drop _replay index;
  %end;
  %else %do;
    /* explicitly created sessions are automatically available */
    _SESSIONID=symget('_SESSIONID');
  %end;
    GLOB_VARS=symget('global_vars');
    output;
    stop;
  run;

  proc append base=web.stp_logger data=append;run;
  proc sql; drop view append;

%mend stp_logger;
