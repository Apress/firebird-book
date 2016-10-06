/* Procedure permscript
Listing 35-1  Procedure to generate permissions script
  (c) Helen Borrie 2004, free for use and modification
       under the Initial Developer's Public License */
SET TERM ^;
CREATE PROCEDURE PERMSCRIPT (
   CMD VARCHAR(6),                              /* enter 'G' or 'R' */
   PRIV CHAR(10),                 /* a privilege, or 'ALL' or 'ANY' */
   USR VARCHAR(31),                                   /* a username */
   ROLENAME VARCHAR(31),                 /* a role, existing or not */
   GRANTOPT SMALLINT,          /* 1 for 'WITH GRANT [ADMIN] OPTION' */
   CREATE_ROLE SMALLINT)           /* 1 to create new role ROLENAME */
RETURNS (PERM VARCHAR(80)) /* a permission statement, theoretically */
AS
  DECLARE VARIABLE RELNAME VARCHAR(31); /* for a table or view name */
  DECLARE VARIABLE STRING VARCHAR(80) = '';         /* used in proc */
  DECLARE VARIABLE STUB VARCHAR(60) = '';           /* used in proc */
  DECLARE VARIABLE VUSR VARCHAR(31); /* username for 'TO' or 'FROM' */
  DECLARE VARIABLE COMMENTS CHAR(20) = '/*                */';
BEGIN
    /* Necessary for some UI editors */
    IF (ROLENAME = '') THEN ROLENAME = NULL;
    IF (USR = '') THEN USR = NULL;
    IF (PRIV = '') THEN PRIV = NULL;
    /* Not enough data to do anything with */
    IF ((PRIV IS NULL AND ROLENAME IS NULL) OR USR IS NULL) THEN EXIT;

    /* If there's a rolename, we'll do stuff with it */
    IF (ROLENAME IS NOT NULL) THEN
    BEGIN
      /* If a role name is supplied, create the role if requested */
      IF (CREATE_ROLE = 1) THEN
      BEGIN
        PERM = 'CREATE ROLE '||ROLENAME||';';
        SUSPEND;
        PERM = 'COMMIT;';
        SUSPEND;
        PERM = COMMENTS;
        SUSPEND;
      END
      VUSR = ROLENAME;
    END
    /* If there's a rolename, we'll apply the permissions to the role
       and grant the role to the supplied user */
    ELSE
      /* We are not interested in the role: permissions are just for user */
      VUSR = USR;
    /* Decide whether it's a GRANT or a REVOKE script */
    IF (CMD STARTING WITH 'G') THEN
      STUB = 'GRANT ';
    ELSE
      STUB = 'REVOKE ';
    IF (ROLENAME IS NOT NULL) THEN
    BEGIN
      IF (STUB = 'GRANT') THEN
      BEGIN
        /* Grant the role to the user */
        STRING = STUB||ROLENAME||' TO '||USR;
        IF (GRANTOPT = 1) THEN
          STRING = STRING||'  WITH ADMIN OPTION ;';
      END
      ELSE
        STRING = STUB||ROLENAME||' FROM '||USR||';';
      PERM = STRING;
      SUSPEND;
      PERM = COMMENTS;
      SUSPEND;
    END
    /* If ANY was passed in as privilege, create all perms separately */
    IF (PRIV = 'ANY') THEN
      STUB = STUB||'SELECT,DELETE,INSERT,UPDATE,REFERENCES ON ';
    ELSE
      STUB = STUB||PRIV||' ON ';
    /* Cycle through the table and view names and create a statement for each */
    FOR SELECT RDB$RELATION_NAME FROM RDB$RELATIONS
    WHERE RDB$RELATION_NAME NOT STARTING WITH 'RDB$'
    INTO :RELNAME DO
    BEGIN
      STRING = STUB||:RELNAME||' ';
      IF (CMD STARTING WITH 'G') THEN
        STRING = STRING||'TO ';
      ELSE
        STRING = STRING||'FROM ';
      STRING = STRING||VUSR;
      IF (CMD STARTING WITH 'G'
          AND GRANTOPT = 1 AND ROLENAME IS NULL) THEN
        STRING = STRING||'  WITH GRANT OPTION ;';
      ELSE
        STRING = STRING||' ;';
      PERM = STRING;
      SUSPEND;
    END
    PERM = COMMENTS;
    SUSPEND;
END ^
SET TERM ;^

/* Procedure grant_perms
Listing 35-2  Permissions procedure
 (c) Helen Borrie 2004, free for use and modification
       under the Initial Developer's Public License */
SET TERM ^;
CREATE PROCEDURE GRANT_PERMS
  (CMD VARCHAR(6),
   PRIV CHAR(10),
   USR VARCHAR(31),
   ROLENAME VARCHAR(31),
   GRANTOPT SMALLINT)
AS
  DECLARE VARIABLE RELNAME VARCHAR(31);
  DECLARE VARIABLE EXESTRING VARCHAR(1024) = '';
  DECLARE VARIABLE EXESTUB VARCHAR(1024) = '';
BEGIN
    IF (ROLENAME = '') THEN ROLENAME = NULL;
    IF (USR = '') THEN USR = NULL;
    IF (PRIV = '') THEN PRIV = NULL;
    IF ((PRIV IS NULL AND ROLENAME IS NULL) OR USR IS NULL) THEN EXIT;
    IF (CMD STARTING WITH 'G') THEN
      EXESTUB = 'GRANT ';
    ELSE
      EXESTUB = 'REVOKE ';
    IF (ROLENAME IS NOT NULL) THEN
    BEGIN
      IF (EXESTUB = 'GRANT') THEN
      BEGIN
        EXESTUB = EXESTUB||ROLENAME||' TO '||USR;
        IF (GRANTOPT = 1) THEN
          EXESTUB = EXESTUB||' WITH ADMIN OPTION';
      END
      ELSE
        EXESTUB = EXESTUB||ROLENAME||' FROM '||USR;
      EXECUTE STATEMENT EXESTUB;
    END
    ELSE
    BEGIN
      IF (PRIV = 'ANY') THEN
        EXESTUB = EXESTUB||'SELECT,DELETE,INSERT,UPDATE,REFERENCES ON ';
      ELSE
        EXESTUB = EXESTUB||PRIV||' ON ';
      FOR SELECT RDB$RELATION_NAME FROM RDB$RELATIONS
      WHERE RDB$RELATION_NAME NOT STARTING WITH 'RDB$'
      INTO :RELNAME DO
      BEGIN
        EXESTRING = EXESTUB||:RELNAME||' ';
        IF (CMD STARTING WITH 'G') THEN
          EXESTRING = EXESTRING||'TO ';
        ELSE
          EXESTRING = EXESTRING||'FROM ';
        EXESTRING = EXESTRING||USR;
        IF (GRANTOPT = 1) THEN
          EXESTRING = EXESTRING||' WITH GRANT OPTION';
        EXECUTE STATEMENT EXESTRING;
      END
    END
END ^
SET TERM ;^

/* Carriage return! */
