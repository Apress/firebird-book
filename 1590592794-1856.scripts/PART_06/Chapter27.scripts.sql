/* The following example illustrates how savepoints work: */

CREATE TABLE SAVEPOINT_TEST (ID INTEGER);
COMMIT;
INSERT INTO SAVEPOINT_TEST
VALUES(99);
COMMIT;
INSERT INTO SAVEPOINT_TEST
VALUES(100);
/**/
SAVEPOINT SP1;
/**/
DELETE FROM SAVEPOINT_TEST;
SELECT *FROM SAVEPOINT_TEST; /*returns nothing */
/**/
ROLLBACK TO SP1;
/**/
SELECT *FROM SAVEPOINT_TEST; /*returns 2 rows */
ROLLBACK;
/**/
SELECT *FROM SAVEPOINT_TEST; /*returns the one committed row */

/* Carriage return! */
