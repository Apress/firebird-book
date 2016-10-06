/* For a listing by character set name, including the name of the default collate sequence in each case, execute this query: */

SELECT
  RDB$CHARACTER_SET_NAME,
  RDB$DEFAULT_COLLATE_NAME,
  RDB$BYTES_PER_CHARACTER
FROM RDB$CHARACTER_SETS
  ORDER BY 1 ;

/* To see all of the aliases that are set up at database-creation time, run this query, filtering RDB$TYPES to see just the enumerated set of character set names: */

SELECT
  C.RDB$CHARACTER_SET_NAME,
  T.RDB$TYPE_NAME
FROM RDB$TYPES T
  JOIN RDB$CHARACTER_SETS C
    ON C.RDB$CHARACTER_SET_ID =T.RDB$TYPE
    WHERE T.RDB$FIELD_NAME ='RDB$CHARACTER_SET_NAME'
  ORDER BY 1 ;

/* How can you deal with a bunch of character data that you have stored using the wrong character set? The “trick” is to use character set OCTETS as a “staging post” between the wrong and the right encoding. Because OCTETS is a special character set that blindly stores only what you poke into it—without transliteration—it is ideal for making the character codes neutral with respect to code page.

For example, suppose your problem table has a column COL_ORIGINAL that you
accidentally created in character set NONE, when you meant it to be CHARACTER SET ISO8859_2. You have been loading this column with Hungarian data but, every time you try to select from it, you get that darned transliteration error.

Here’s what you can do: */

ALTER TABLE TABLEA
  ADD COL_IS08859_2 VARCHAR(30)CHARACTER SET IS08859_2;
COMMIT;

UPDATE TABLEA
SET COL_IS08859_2 = CAST(COL_ORIGINAL AS CHAR(30)CHARACTER SET OCTETS);
COMMIT;

/* Now you have a temporary column designed to store Hungarian text—and it is
storing all of your “lost” text from the unusable COL_ORIGINAL. You can proceed to drop COL_ORIGINAL, and then add a new COL_ORIGINAL having the correct character set. Simply copy the data from the temporary column and, after committing, drop the temporary column: 
*/

ALTER TABLE TABLEA
  DROP COL_ORIGINAL;
COMMIT;
ALTER TABLE TABLEA
  ADD COL_ORIGINAL VARCHAR(30)CHARACTER SET IS08859_2;
COMMIT;
UPDATE TABLEA
  SET COL_ORIGINAL =COL_ISO8859_2;
COMMIT;

/*It would be wise to view your data now!*/

ALTER TABLE TABLEA
  DROP COL_ISO8859_2;
COMMIT;

/* ************************************************************************
Suppose you want to add an alias for the character set ISO8859_1 that your OS
recognizes by the literal “LC_ISO88591”. First, get the character set ID by querying RDB$CHARACTER_SETS using isql or another interactive query tool:
*/

SELECT RDB$CHARACTER_SET_ID
  FROM RDB$CHARACTER_SETS
  WHERE RDB$CHARACTER_SET_NAME ='ISO8859_1';

/* Example statement to add your own alias to RDB$TYPES: */

INSERT INTO RDB$TYPES (
  RDB$FIELD_NAME,RDB$TYPE,RDB$TYPE_NAME )
VALUES ('RDB$CHARACTER_SET_NAME',21,'LC_ISO88591');

/* Carriage return! */
