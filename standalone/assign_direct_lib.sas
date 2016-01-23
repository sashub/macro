/***
  Macro queries metadata to obtain details for configuring a direct
   libname connection (ie not using the META engine)

  @author Allan Bowe @@

  @usage
    %assign_direct_lib(libref=MyLib);
    data x; set mylib.sometable; run;

    %assign_direct_lib(libref=MyDB,open_passthrough=MyAlias);
    create table MyTable as
      select * from connection to MyAlias( select * from DBTable);
    disconnect from MyAlias;
    quit;
  @@
  
  #Library
  #Metadata

***/


%macro assign_direct_lib(
     libref= /* libref to assign from metadata */
    ,debug=  /* set to YES for extra log info */
    ,open_passthrough= /* provide an alias to produce the 
                          CONNECT TO statement for the 
                          relevant external database */
    ,sql_options= /* add any options to add to proc sql statement eg outobs= 
                      (only valid for pass through) */
  );

%put NOTE: Setting up direct (non META engine) connection to &libref library;

%if %upcase(&libref)=WORK %then %do;
  %put NOTE: We already have a direct connection to WORK :-) ;
  %return;
%end;
/* need to determine the library ENGINE first */
data _null_;
  length lib_uri engine $256;
  call missing (of _all_);
  /* get URI for the particular library */
  rc1=metadata_getnobj("omsobj:SASLibrary?@Libref ='&libref'",1,lib_uri);
  /* get the Engine attribute of the previous object */
  rc2=metadata_getattr(lib_uri,'Engine',engine);
  put rc1= lib_uri= rc2= engine=;
  call symputx("liburi",lib_uri,'l');
  call symputx("engine",engine,'l');
run;

/* now obtain engine specific connection details */
%if &engine=BASE %then %do;
  %put NOTE: Retrieving BASE library path;
  data _null_;
    length up_uri $256 path cat_path $1024;
    retain cat_path;
    call missing (of _all_);
    /* get all the filepaths of the UsingPackages association  */
    i=1;
    rc3=metadata_getnasn("&liburi",'UsingPackages',i,up_uri);
  do while (rc3>0);
      /* get the DirectoryName attribute of the previous object */
      rc4=metadata_getattr(up_uri,'DirectoryName',path);
    if i=1 then path = '("'!!trim(path)!!'" ';
    else path =' "'!!trim(path)!!'" ';
    cat_path = trim(cat_path) !! " " !! trim(path) ;
    i+1;
      rc3=metadata_getnasn("&liburi",'UsingPackages',i,up_uri);
  end;
  cat_path = trim(cat_path) !! ");";
  %if &debug=YES %then %do;
    %put NOTE: Getting physical path for &libref library;
    put rc3= up_uri= rc4= cat_path= path=;
  %put NOTE: Libname cmd will be:;
  %put libname &libref &filepath;
  %end;
    call symputx("filepath",cat_path,'l');
  run;

  libname &libref &filepath;

%end;
%else %if &engine=REMOTE %then %do;
  data _null_;
    length rcCon rcProp rc k 3 uriCon uriProp PropertyValue PropertyName 
      Delimiter $256 properties $2048;
    retain properties;
    rcCon = metadata_getnasn("&liburi", "LibraryConnection", 1, uriCon);
    rcProp = metadata_getnasn(uriCon, "Properties", 1, uriProp);
    k = 1;
    rcProp = metadata_getnasn(uriCon, "Properties", k, uriProp);
    do while (rcProp > 0);
      rc = metadata_getattr(uriProp , "DefaultValue",PropertyValue);
      rc = metadata_getattr(uriProp , "PropertyName",PropertyName);
      rc = metadata_getattr(uriProp , "Delimiter",Delimiter);
      properties = trim(properties) !! " " !! trim(PropertyName) 
              !! trim(Delimiter) !! trim(PropertyValue);
      output;
    k+1;
    rcProp = metadata_getnasn(uriCon, "Properties", k, uriProp);
  end;
  %if &debug=YES %then %do;
    %put NOTE: Getting properties for REMOTE SHARE &libref library;
    put _all_;
  %put NOTE: Libname cmd will be:;
  %put libname &libref &engine &properties slibref=&libref;
  %end;
  call symputx ("properties",trim(properties),'l');
  run;

  libname &libref &engine &properties slibref=&libref;

%end;

%else %if &engine=OLEDB %then %do;
  %put NOTE: Retrieving OLEDB connection details;
  data _null_;
    length domain datasource provider properties schema
      connx_uri domain_uri conprop_uri lib_uri schema_uri value $256.;
    call missing (of _all_);
    /* get source connection ID */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,connx_uri);
    /* get connection domain */
    rc1=metadata_getnasn(connx_uri,'Domain',1,domain_uri);
    rc2=metadata_getattr(domain_uri,'Name',domain);
  %if &debug=YES %then %do;
    putlog / 'NOTE: ' // 'NOTE- connection id: ' connx_uri ;
    putlog 'NOTE- domain: ' domain;
  %end;
    /* get DSN and PROVIDER from connection properties */
    i=0;
    do until (rc<0);
      i+1;
      rc=metadata_getnasn(connx_uri,'Properties',i,conprop_uri);
      rc2=metadata_getattr(conprop_uri,'Name',value);
      if value='Connection.OLE.Property.DATASOURCE.Name.xmlKey.txt' then do;
         rc3=metadata_getattr(conprop_uri,'DefaultValue',datasource);
      end;
      else if value='Connection.OLE.Property.PROVIDER.Name.xmlKey.txt' then do;
         rc4=metadata_getattr(conprop_uri,'DefaultValue',provider);
      end;
      else if value='Connection.OLE.Property.PROPERTIES.Name.xmlKey.txt' then do;
         rc5=metadata_getattr(conprop_uri,'DefaultValue',properties);
      end;
    end;
  %if &debug=YES %then %do;
    putlog 'NOTE- dsn/provider/properties: ' datasource provider properties;
    putlog 'NOTE- schema: ' schema // 'NOTE-';
  %end;
    /* get SCHEMA */
    rc6=metadata_getnasn("&liburi",'UsingPackages',1,lib_uri);
    rc7=metadata_getattr(lib_uri,'SchemaName',schema);
    call symputx('SQL_domain',domain,'l');
    call symputx('SQL_dsn',datasource,'l');
    call symputx('SQL_provider',provider,'l');
    call symputx('SQL_properties',properties,'l');
    call symputx('SQL_schema',schema,'l');
  run;

  %if %length(&open_passthrough)>0 %then %do;
    proc sql &sql_options;
    connect to OLEDB as &open_passthrough(INSERT_SQL=YES
      properties=%str(&SQL_properties)
      DATASOURCE=&sql_dsn PROMPT=NO
      PROVIDER=&sql_provider SCHEMA=&sql_schema CONNECTION = GLOBAL);
  %end;
  %else %do;
    LIBNAME &libref OLEDB  PROPERTIES=&sql_properties 
      DATASOURCE=&sql_dsn  PROVIDER=&sql_provider SCHEMA=&sql_schema  
    %if %length(&sql_domain)>0 %then %do;
       authdomain="&sql_domain" 
    %end;
       connection=shared;
  %end;
%end;
%else %if &engine=ODBC %then %do;
  %put NOTE: Retrieving ODBC connection details;
  data _null_;
    length connx_uri conprop_uri value datasource up_uri schema $256.;
    call missing (of _all_);
    /* get source connection ID */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,connx_uri);
    /* get connection properties */
    i=0;
    do until (rc2<0);
      i+1;
      rc2=metadata_getnasn(connx_uri,'Properties',i,conprop_uri);
      rc3=metadata_getattr(conprop_uri,'Name',value);
      if value='Connection.ODBC.Property.DATASRC.Name.xmlKey.txt' then do;
         rc4=metadata_getattr(conprop_uri,'DefaultValue',datasource);
         rc2=-1;
      end;
    end;
    /* get SCHEMA */
    rc6=metadata_getnasn("&liburi",'UsingPackages',1,up_uri);
    rc7=metadata_getattr(up_uri,'SchemaName',schema);
  %if &debug=YES %then %do;
    put rc= connx_uri= rc2= conprop_uri= rc3= value= rc4= datasource=
      rc6= up_uri= rc7= schema=;
  %end;

    call symputx('SQL_schema',schema,'l');
    call symputx('SQL_dsn',datasource,'l');
  run;

  %if %length(&open_passthrough)>0 %then %do;
    proc sql &sql_options;
    connect to ODBC as &open_passthrough
      (INSERT_SQL=YES DATASRC=&sql_dsn. CONNECTION=global);
  %end;
  %else %do;
    libname &libref ODBC DATASRC=&sql_dsn SCHEMA=&sql_schema;
  %end;
%end;
%else %do;
  %put NOTE: Engine &engine is currently unsupported;
  %put NOTE- Please contact SAS Support team.;
  %return;
%end;

%mend;
