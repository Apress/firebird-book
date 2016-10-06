In the following trivial example, a comma-separated list of strings, each of 20 or fewer characters, is fed in as input. The procedure returns each string to the application as a numbered row:

SET TERM ^;
CREATE PROCEDURE BREAKAPART(
  INPUTLIST VARCHAR(1024))
RETURNS (
  NUMERO SMALLINT,
  ITEM VARCHAR(20)
  )
AS
DECLARE CHARAC CHAR;
DECLARE ISDONE SMALLINT =0;
BEGIN
  NUMERO = 0;
  ITEM ='';
  WHILE (ISDONE = 0) DO
  BEGIN
    CHARAC = SUBSTRING(INPUTLIST FROM 1 FOR 1);
    IF (CHARAC = '')THEN
      ISDONE = 1;
    IF (CHARAC =',' OR CHARAC ='') THEN
    BEGIN
      NUMERO = NUMERO + 1;
      SUSPEND; /*Sends a row to the row buffer */
      ITEM = '';
    END
    ELSE
      ITEM = ITEM || CHARAC;
    INPUTLIST = SUBSTRING(INPUTLIST FROM 2);
  END
END ^

SET TERM ;^
COMMIT;
/**/
SELECT * FROM BREAKAPART('ALPHA, BETA, GAMMA, DELTA');

/* *****************************************************************
/* This script creates the bits and pieces to list out 
   roles, users and privileges.
   The output of the select procedure SP_PRIVILEGES is 
   in no particular order - it's up to you what you want to 
   do with the output. 
   The source issued "as is" under the terms of 
   the Initial Developers' Public Licence (IDPL) v.1.0. 
   Refer to http://www.ibphoenix.com/main.nfs?a=ibphoenix&page=ibp_idpl
   Original author Helen Borrie (c) 2004 Firebird Project
*/

/* Uncomment this if you don't have it declared already */
/* DECLARE EXTERNAL FUNCTION rtrim 
	CSTRING(80)
	RETURNS CSTRING(80) FREE_IT
	ENTRY_POINT 'IB_UDF_rtrim' MODULE_NAME 'ib_udf';
COMMIT;
*/

SET TERM ^;

CREATE PROCEDURE SP_GET_TYPE (IN_TYPE SMALLINT) 
RETURNS (STRING VARCHAR(7))
AS
BEGIN
  STRING = 'Unknown';
  IF (IN_TYPE = 0) THEN STRING = 'Table';
  IF (IN_TYPE = 1) THEN STRING = 'View';
  IF (IN_TYPE = 2) THEN STRING = 'Trigger';
  IF (IN_TYPE = 5) THEN STRING = 'Proc';
  IF (IN_TYPE = 8) THEN STRING = 'User';
  IF (IN_TYPE = 0) THEN STRING = 'Table';
  IF (IN_TYPE = 9) THEN STRING = 'Field';
  IF (IN_TYPE = 13) THEN STRING = 'Role';
END ^

COMMIT ^

CREATE PROCEDURE SP_PRIVILEGES 
RETURNS (
  Q_ROLE_NAME VARCHAR(31),
  ROLE_OWNER VARCHAR(31),
  USER_NAME VARCHAR(31),
  Q_USER_TYPE VARCHAR(7),
  W_GRANT_OPTION CHAR,
  PRIVILEGE CHAR(6),
  GRANTOR VARCHAR(31),
  QUALIFIED_OBJECT VARCHAR(63),
  Q_OBJECT_TYPE VARCHAR(7))
  
AS 
  DECLARE VARIABLE RELATION_NAME VARCHAR(31);
  DECLARE VARIABLE FIELD_NAME VARCHAR(31);
  DECLARE VARIABLE OWNER_NAME VARCHAR(31);
  DECLARE VARIABLE ROLE_NAME VARCHAR(31);
  DECLARE VARIABLE OBJECT_TYPE SMALLINT;
  DECLARE VARIABLE USER_TYPE SMALLINT;
  DECLARE VARIABLE GRANT_OPTION SMALLINT;
  DECLARE VARIABLE IS_ROLE SMALLINT;
  DECLARE VARIABLE IS_VIEW SMALLINT;
BEGIN
FOR SELECT 
  RTRIM(CAST(RDB$USER AS VARCHAR(31))),
  RDB$USER_TYPE,
  RTRIM(CAST(RDB$GRANTOR AS VARCHAR(31))),
  RTRIM(CAST(RDB$RELATION_NAME AS VARCHAR(31))),
  RTRIM(CAST(RDB$FIELD_NAME AS VARCHAR(31))),
  RDB$OBJECT_TYPE,
  RTRIM(CAST(RDB$PRIVILEGE AS VARCHAR(31))),
  RDB$GRANT_OPTION 
  FROM RDB$USER_PRIVILEGES 
  INTO :USER_NAME, :USER_TYPE, :GRANTOR, :RELATION_NAME,
       :FIELD_NAME, :OBJECT_TYPE, :PRIVILEGE, :GRANT_OPTION 
  DO BEGIN
    SELECT 
      RTRIM(CAST(RDB$OWNER_NAME AS VARCHAR(31))), 
      RTRIM(CAST(RDB$ROLE_NAME AS VARCHAR(31)))
      FROM RDB$ROLES
      WHERE RDB$ROLE_NAME = :USER_NAME 
      INTO :ROLE_OWNER, :ROLE_NAME;
    IF (ROLE_NAME IS NOT NULL) THEN
      Q_ROLE_NAME = ROLE_NAME;
    ELSE
    BEGIN
      Q_ROLE_NAME = '-';
      ROLE_OWNER = '-';
    END 
    IF (GRANT_OPTION = 1) THEN 
      W_GRANT_OPTION = 'Y';
    ELSE
      W_GRANT_OPTION = '';    
    IS_ROLE = NULL;
    SELECT 1 FROM RDB$ROLES
      WHERE RDB$ROLE_NAME = :RELATION_NAME 
      INTO :IS_ROLE;
    IF (IS_ROLE = 1) THEN 
      QUALIFIED_OBJECT = '(Role) '||RELATION_NAME;
    ELSE
      BEGIN 
        IF (
          (FIELD_NAME IS NULL)
          OR (RTRIM(FIELD_NAME) = '')) THEN 
          FIELD_NAME = '';
        ELSE
          FIELD_NAME = '.'||FIELD_NAME;
        QUALIFIED_OBJECT = RELATION_NAME||FIELD_NAME;
      END
    IF (OBJECT_TYPE = 0) THEN 
      BEGIN
        IS_VIEW = 0;
        SELECT 1 FROM RDB$RELATIONS 
          WHERE RDB$RELATION_NAME = :RELATION_NAME 
          AND RDB$VIEW_SOURCE IS NOT NULL
        INTO :IS_VIEW;
        IF (IS_VIEW = 1) THEN 
          OBJECT_TYPE = 1;   
      END
      EXECUTE PROCEDURE SP_GET_TYPE(:OBJECT_TYPE) 
      RETURNING_VALUES :Q_OBJECT_TYPE;
      EXECUTE PROCEDURE SP_GET_TYPE (:USER_TYPE) 
      RETURNING_VALUES :Q_USER_TYPE;
    SUSPEND;
  END        
END ^
SET TERM ;^
COMMIT;

/* *******************************************************************
In this procedure, we process records from the SALES table in the EMPLOYEE database.  We keep two running totals: one for each sales representative and one for overall sales.  As inputs we have just a start and end date for the group of sales records we want. 
*/
SET TERM ^;
CREATE PROCEDURE LOG_SALES (
  START_DATE DATE,
  END_DATE DATE) 
RETURNS (
  REP_NAME VARCHAR(37),
  CUST VARCHAR(25),
  ORDDATE TIMESTAMP,
  ITEMTYP VARCHAR(12),
  ORDTOTAL NUMERIC(9,2),
  REPTOTAL NUMERIC(9,2),
  RUNNINGTOTAL NUMERIC(9,2)
  )
AS
DECLARE VARIABLE CUSTNO INTEGER;
DECLARE VARIABLE REP SMALLINT;
DECLARE VARIABLE LASTREP SMALLINT DEFAULT -99;
DECLARE VARIABLE LASTCUSTNO INTEGER DEFAULT -99;

BEGIN
  RUNNINGTOTAL =0.00;
  FOR SELECT
    CUST_NO,
    SALES_REP,
    ORDER_DATE,
    TOTAL_VALUE,
   ITEM_TYPE
  FROM SALES
    WHERE ORDER_DATE BETWEEN :START_DATE AND :END_DATE +1
    ORDER BY 2,3
  INTO :CUSTNO,:REP,:ORDDATE,:ORDTOTAL,:ITEMTYP
  DO
  BEGIN
    IF(REP =LASTREP)THEN
    BEGIN
      REPTOTAL = REPTOTAL +ORDTOTAL;
      REP_NAME = '"';
    END
    ELSE
    BEGIN
      REPTOTAL = ORDTOTAL;
      LASTREP = REP;
      SELECT FULL_NAME FROM EMPLOYEE
        WHERE EMP_NO = :REP
      INTO :REP_NAME;
    END
    IF (CUSTNO <>LASTCUSTNO)THEN
    BEGIN
      SELECT CUSTOMER FROM CUSTOMER
        WHERE CUST_NO = :CUSTNO
      INTO :CUST;
      LASTCUSTNO = CUSTNO;
    END
    RUNNINGTOTAL = RUNNINGTOTAL +ORDTOTAL;
    SUSPEND;
  END
END ^
SET TERM ;^ 

/* 
As is, that procedure, LOG_SALES, that promises to bite us because we overlooked a nullable key. Here is the block that could cause the problems:
CREATE PROCEDURE LOG_SALES (...
...
DO
  BEGIN
    IF(REP =LASTREP)THEN -- will be false if both values are null 
    BEGIN
      REPTOTAL = REPTOTAL + ORDTOTAL;
      REP_NAME ='"';
    END
    ELSE
    BEGIN
      REPTOTAL =ORDTOTAL;
      LASTREP = REP;
      SELECT FULL_NAME FROM EMPLOYEE
        WHERE EMP_NO =:REP
      INTO :REP_NAME; -- will return null if variable REP is null 
    END
    ...
  END ....

We fix the logic to handle nulls (grouped together at the end of the cursor, because the set is ordered by this column) and use CREATE OR ALTER to update the code:

CREATE OR ALTER PROCEDURE LOG_SALES (...
...
DO
  BEGIN
  -- ************* --
  IF ((REP = LASTREP) OR (LASTREP IS NULL)) THEN
  -- ************* --
  BEGIN
    REPTOTAL = REPTOTAL + ORDTOTAL;
    REP_NAME ='"';
  END
  ELSE
  BEGIN
    REPTOTAL = ORDTOTAL;
    LASTREP = REP;
    -- ************* --
    IF (REP IS NOT NULL) THEN
      SELECT FULL_NAME FROM EMPLOYEE
        WHERE EMP_NO =:REP
      INTO :REP_NAME;
    ELSE
      REP_NAME ='Unassigned';
    -- ************* --
  END
...
END ^
COMMIT ^

*/


