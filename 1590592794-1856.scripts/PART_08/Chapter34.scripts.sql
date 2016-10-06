/* Allowing Users to Change Their Own Passwords
The easiest and best-known modification is to grant update permissions to give non-SYSDBA users access, GRANT UPDATE ON USERS TO PUBLIC, and add a trigger to prevent any user except SYSDBA from modifying somebody else’s password.

Copyright Ivan Prenosil 2002-2004 */

CONNECT 'C:\Program Files \Firebird \Firebird_1_5 \security.fdb'
  USER 'SYSDBA'
  PASSWORD 'masterkey';
CREATE EXCEPTION E_NO_RIGHT 'You have no rights to modify this user.';
COMMIT;

SET TERM !!;
CREATE TRIGGER user_name_bu FOR USERS BEFORE UPDATE
AS
BEGIN
  IF (NOT (USER='SYSDBA'OR USER=OLD.USER_NAME))THEN
    EXCEPTION E_NO_RIGHT;
END !!
SET TERM ;!!

/** Grants**/
GRANT UPDATE(PASSWD,GROUP_NAME,UID,GID,FIRST_NAME,MIDDLE_NAME,LAST_NAME)
ON USERS TO PUBLIC; 

/* *****************************************************************
How to Hide the Users/Passwords List
If you rename the USERS table and re-create USERS as view of the renamed table, you can have the best of both worlds. Users will be able to modify their own passwords, and the full list of users and passwords can be hidden from PUBLIC. Each non-SYSDBA user will see only one record in security.fdb (or isc4.gdb, if your server is v.1.0.x). The new structures in security.fdb will be more like the following schema: 
*/
/* Copyright Ivan Prenosil 2002-2004 */

CONNECT 'C:\Program Files\Firebird \Firebird_1_5 \security.fdb'
  USER 'SYSDBA'
  PASSWORD 'masterkey';

/* Rename existing USERS table to USERS2. */

CREATE TABLE USERS2 (
  USER_NAME USER_NAME,
  SYS_USER_NAME USER_NAME,
  GROUP_NAME USER_NAME,
  UID UID,
  GID GID,
  PASSWD PASSWD,
  PRIVILEGE PRIVILEGE,
  COMMENT COMMENT,
  FIRST_NAME NAME_PART,
  MIDDLE_NAME NAME_PART,
  LAST_NAME NAME_PART,
  FULL_NAME COMPUTED BY 
    (first_name ||_UNICODE_FSS ''||middle_name ||_UNICODE_FSS ''||last_name ));
COMMIT;

INSERT INTO USERS2
  (USER_NAME,SYS_USER_NAME,GROUP_NAME,
   UID,GID,PASSWD,PRIVILEGE,COMMENT,
   FIRST_NAME,MIDDLE_NAME,LAST_NAME)
SELECT
  USER_NAME,SYS_USER_NAME,GROUP_NAME,
  UID,GID,PASSWD,PRIVILEGE,COMMENT,
  FIRST_NAME,MIDDLE_NAME,LAST_NAME
FROM USERS;
COMMIT;
/**/
DROP TABLE USERS;
/**/

CREATE UNIQUE INDEX USER_NAME_INDEX2 ON USERS2(USER_NAME);

/**Create the view that will be used instead of original USERS table.**/
CREATE VIEW USERS AS
SELECT * FROM USERS2
WHERE 
  USER =''
  OR USER = 'SYSDBA'
  OR USER = USER_NAME;

/**Permissions **/
GRANT SELECT ON USERS TO PUBLIC;
GRANT UPDATE(PASSWD,GROUP_NAME,UID,GID,FIRST_NAME,MIDDLE_NAME,LAST_NAME)
  ON USERS
  TO PUBLIC; 

/* The Log Table */
CREATE TABLE log_table
EXTERNAL FILE 'C:\Program Files \Firebird \Firebird_1_5 \security.log'
  (
    tstamp TIMESTAMP,
    uname CHAR(31));

/* The Logging Procedure */
SET TERM !!;
CREATE PROCEDURE log_proc
  (un VARCHAR(31))
RETURNS
  (x CHAR(1))
AS
BEGIN
  IF (USER = '') THEN
    INSERT INTO log_table (TSTAMP,UNAME)
    VALUES (CURRENT_TIMESTAMP,:un);

  IF (USER = '' 
  OR USER = 'SYSDBA' 
  OR USER =:un) THEN
    SUSPEND;
END !!
SET TERM ;!!

/* Implementing the New Setup
We need to drop the view that is being used in our restructured security database and create a new version that calls the stored procedure: 
*/
CREATE VIEW USERS (USER_NAME) 
AS
  SELECT * FROM users2
  WHERE EXISTS (SELECT * FROM log_proc(users2.user_name));

/* Reinstate the permissions that were lost when the view was dropped: */
GRANT SELECT ON USERS TO PUBLIC;
/**/
GRANT UPDATE(PASSWD,GROUP_NAME,UID,GID,FIRST_NAME,MIDDLE_NAME,LAST_NAME)
  ON USERS
  TO PUBLIC;

Permissions relating to the stored procedure: */
GRANT INSERT
  ON log_table
  TO PROCEDURE log_proc;
GRANT EXECUTE
  ON PROCEDURE log_proc
  TO PUBLIC;

COMMIT;

/* Carriage return! */
