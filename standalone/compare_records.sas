/*** 
  Occasionally an SCD2 type load will show that two seemingly identical
    records are in fact different.  This macro will compare two records
    and convert each field to a binary value for exact comparison.

  @author Allan Bowe@@
  @version 9.2 @@
  
***/

%macro compare_records(ds1=, ds2=);
  proc transpose data=&ds1(obs=1) out=ds1a (drop=_label_ rename=(col1=&ds1._orig));
  run;

  proc transpose data=&ds2(obs=1) out=ds2a (drop=_label_ rename=(col1=&ds2._orig));
  run;

  proc sort data=ds1a;by _all_; run;
  proc sort data=ds2a;by _all_; run;

  data test;
    merge ds1a ds2a;
    by _name_;
    if upcase(_name_) not in ('TECH_FROM_DTTM','TECH_TO_DTTM','PROCESSED_DTTM');
    &ds1._hex=put(md5(&ds1._orig),binary64.);
    &ds2._hex=put(md5(&ds2._orig),binary64.);
    if &ds1._hex ne &ds2._hex then flag=1;
  run;

%mend;
