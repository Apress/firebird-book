/* The following stored procedure generated the error codes list in Appendix X. It outputs the list to an external table, but you can modify the procedure to suit yourself. */

/*The output file */
CREATE TABLE ERRORCODES
EXTERNAL FILE
'C:\Program Files \Firebird \Firebird_1_5 \MyData \2794app10.txt'
(ListItem CHAR(169))^
COMMIT ^ 

/* If needed,uncomment the section below and declare the ASCII_CHAR()function to get us a carriage return and line feed */

/* DECLARE EXTERNAL FUNCTION ascii_char
INTEGER
RETURNS CSTRING(1)FREE_IT
ENTRY_POINT 'IB_UDF_ascii_char'MODULE_NAME 'ib_udf'^
COMMIT ^
*/

CREATE PROCEDURE OUTPUT_ERRCODES
AS
DECLARE VARIABLE SQC SMALLINT;
DECLARE VARIABLE NUM SMALLINT;
DECLARE VARIABLE FAC SMALLINT;
DECLARE VARIABLE SYM VARCHAR(32);
DECLARE VARIABLE TXT VARCHAR(118);
DECLARE VARIABLE GDC CHAR(9)CHARACTER SET OCTETS;
DECLARE VARIABLE BASE0 INTEGER =335544320;
DECLARE VARIABLE CALCNUM INTEGER;
DECLARE VARIABLE EOL CHAR(2);
BEGIN
  EOL = ASCII_CHAR(13)||ASCII_CHAR(10); /*end-of-line sequence */
  FOR SELECT
    S.SQL_CODE,
    S.NUMBER,
    S.FAC_CODE,
    S.GDS_SYMBOL,
    M.TEXT
  FROM SYSTEM_ERRORS S
  JOIN MESSAGES M
  ON
    M.FAC_CODE =S.FAC_CODE
    AND M.NUMBER =S.NUMBER
    AND M.SYMBOL =S.GDS_SYMBOL
    /* Eliminate some unwanted/unused codes */
    WHERE 
      M.TEXT NOT CONTAINING 'journal'
      AND M.TEXT NOT CONTAINING 'dump'
      AND s.GDS_SYMBOL NOT CONTAINING 'license'
      AND S.GDS_SYMBOL NOT CONTAINING 'wal_'
      AND S.GDS_SYMBOL IS NOT NULL
      AND S.SQL_CODE < 102
    ORDER BY 1 DESC, 2
    INTO :SQC,:NUM,:FAC,:SYM,:TXT
  DO
  BEGIN
  /* The message texts are all in lower case,so we do a little
     jiggery-pokery to uppercase the first letter.*/
    IF (TXT IS NULL) THEN
      TXT ='{Message unknown}';
    ELSE
      TXT = UPPER(SUBSTRING(TXT FROM 1 FOR 1))||SUBSTRING(TXT FROM 2);

    /* Cook and serve the GDSCODE numbers */
    IF (FAC IS NOT NULL AND NUM IS NOT NULL) THEN
      /* We don't want any half-cooked errcodes! */
    BEGIN
      CALCNUM = BASE0 + (FAC * 65535);
      CALCNUM = CALCNUM + NUM + FAC;
      GDC = CAST(CALCNUM AS CHAR(9));
      INSERT INTO ERRORCODES
      VALUES(
        /*all vars go into a single string */
        :SQC||'|'||:GDC||'|'||:SYM||'|'||:TXT||:EOL);
    END
  END
END ^
COMMIT ^

EXECUTE PROCEDURE OUTPUT_ERRCODES ^
COMMIT ^
SET TERM ;^

/* The text file is now ready to go to the word processor for a little tidying, to get rid of all the white space created by the right-padding on the output string. */


