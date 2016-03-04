/***
  This macro generates a table containing the metadata IDs for all the 
    tables in a particular library (or all tables if library left blank).

  @usage  
    %get_metadata_library_tables(libref=WEB, outds=MYWEBDS)
  @@

  @version 9.2 @@
  @author Allan Bowe @@
  #metadata
  
***/

%macro get_metadata_library_tables(
    libref= /* supply a libref here if filtering for a single library.
                Leaving this blank will return ALL tables */
    ,outds= metadata_tables /* name of output dataset to create */ 
  );

%local nobj_statement;
%if %length(&libref)=0 %then %let nobj_statement=
  %str( metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",n,uri) );
%else %let nobj_statement=
  %str( metadata_getnobj("omsobj:SASLibrary?@Libref='&libref'",n,uri) );

data &outds;
  length uri serveruri conn_uri domainuri libname ServerContext AuthDomain 
    path_schema usingpkguri type tableuri coluri $256 id $17
    desc $200 libref engine $8 isDBMS $1 
    table $50 /* metadata table names can be longer than $32 */
    ;
  keep libname desc libref engine ServerContext path_schema AuthDomain tableuri 
    table IsPreassigned IsDBMSLibname id;
  nobj=.;
  n=1;
  uri='';
  serveruri='';
  conn_uri='';
  domainuri='';

  /***Determine if library/ies exist ***/
  nobj=&nobj_statement;

  /***Retrieve the attributes for all libraries, if there are any***/
  if n>0 then do n=1 to nobj;
    libname='';
    ServerContext='';
    AuthDomain='';
    desc='';
    libref='';
    engine='';
    isDBMS='';
    IsPreassigned='';
    IsDBMSLibname='';
    path_schema='';
    usingpkguri='';
    type='';
    id='';
    nobj=&nobj_statement;
    rc= metadata_getattr(uri, "Name", libname);
    rc= metadata_getattr(uri, "Desc", desc);
    rc= metadata_getattr(uri, "Libref", libref);
    rc= metadata_getattr(uri, "Engine", engine);
    rc= metadata_getattr(uri, "IsDBMSLibname", isDBMS);
    rc= metadata_getattr(uri, "IsDBMSLibname", IsDBMSLibname); 
    rc= metadata_getattr(uri, "IsPreassigned", IsPreassigned); 
    rc= metadata_getattr(uri, "Id", Id);

    /*** Get associated ServerContext ***/
    i=1;
    rc= metadata_getnasn(uri, "DeployedComponents", i, serveruri);
    if rc > 0 then rc2= metadata_getattr(serveruri, "Name", ServerContext);
    else ServerContext='';

    /*** If the library is a DBMS library, get the Authentication Domain
         associated with the DBMS connection credentials ***/
    if isDBMS="1" then do;
      i=1; 
      rc= metadata_getnasn(uri, "LibraryConnection", i, conn_uri);
      if rc > 0 then do;
        rc2= metadata_getnasn(conn_uri, "Domain", i, domainuri);
        if rc2 > 0 then rc3= metadata_getattr(domainuri, "Name", AuthDomain);
      end;
    end;

    /*** Get the path/database schema for this library ***/
    rc=metadata_getnasn(uri, "UsingPackages", 1, usingpkguri);
    if rc>0 then do;
      rc=metadata_resolve(usingpkguri,type,id);  
      if type='Directory' then 
        rc=metadata_getattr(usingpkguri, "DirectoryName", path_schema);
      else if type='DatabaseSchema' then 
        rc=metadata_getattr(usingpkguri, "Name", path_schema);
      else path_schema="unknown";
    end;

    /*** Get the tables associated with this library ***/
    /*** If DBMS, tables are associated with DatabaseSchema ***/
    if type='DatabaseSchema' then do;
      t=1;
      ntab=metadata_getnasn(usingpkguri, "Tables", t, tableuri);
      if ntab>0 then do t=1 to ntab;
        tableuri='';
        table='';
        ntab=metadata_getnasn(usingpkguri, "Tables", t, tableuri);
        tabrc= metadata_getattr(tableuri, "Name", table);
        output;
      end;
      else put 'Library ' libname ' has no tables registered';
    end;
    else if type in ('Directory','SASLibrary') then do;
      t=1;
      ntab=metadata_getnasn(uri, "Tables", t, tableuri);
      if ntab>0 then do t=1 to ntab;
        tableuri='';
        table='';
        ntab=metadata_getnasn(uri, "Tables", t, tableuri);
        tabrc= metadata_getattr(tableuri, "Name", table);
        output;  
      end;
      else put 'Library ' libname ' has no tables registered'; 
    end;
  end;
  /***If there aren't any libraries, write a message to the log***/
  else put 'There are no libraries defined in this metadata repository.'; 
 run;

 /*Find full metadata paths for input objects*/
data &outds;
  set &syslast;
  length tree_path $500 tree_uri parent_uri parent_name $200;
  call missing(tree_path,tree_uri,parent_uri,parent_name);
  drop tree_uri parent_uri parent_name rc rc_tree;
  
  rc=metadata_getnasn(tableuri,"Trees",1,tree_uri);
  rc=metadata_getattr(tree_uri,"Name",tree_path);

  rc_tree=1;
  do while (rc_tree>0);
    rc_tree=metadata_getnasn(tree_uri,"ParentTree",1,parent_uri);
    if rc_tree>0 then do;
      rc=metadata_getattr(parent_uri,"Name",parent_name);
      tree_path=strip(parent_name)||'/'||strip(tree_path);
      tree_uri=parent_uri;
    end;
  end;
  tree_path='/'||strip(tree_path);
run;

%mend;


