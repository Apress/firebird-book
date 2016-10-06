/* The EXTRACT( ) function makes it possible to extract the individual elements of date and time types to SMALLINT values. The following trigger extracts the time elements from a dialect 1 DATE column named CAPTURE_DATE and converts them into a CHAR(13), mimicking the Firebird standard time literal 'HH:NN:SS.nnnn': */

SET TERM ^;
CREATE TRIGGER BI_ATABLE FOR ATABLE
ACTIVE BEFORE INSERT POSITION 1
AS
BEGIN
  IF (NEW.CAPTURE_DATE IS NOT NULL) THEN
  BEGIN
    NEW.CAPTURE_TIME =
      CAST(EXTRACT (HOUR FROM NEW.CAPTURE_DATE) AS CHAR(2))||':'||
      CAST(EXTRACT (MINUTE FROM NEW.CAPTURE_DATE) AS CHAR(2))||':'||
      CAST(EXTRACT (SECOND FROM NEW.CAPTURE_DATE) AS CHAR(7)) ||'.0000';
  END
END ^
SET TERM ;^

/* ************************************************************************ 

The CHAR(13) string stored by the trigger in the preceding example does not behave like a dialect 3 TIME type. However, by simple casting, it can be converted directly, in a later upgrade to dialect 3, to a dialect 3 TIME type.
First, we add a temporary new column to the table to store the converted time
string: 
*/
ALTER TABLE ATABLE
ADD TIME_CAPTURE TIME;
COMMIT;

/* Next, populate the temporary column by casting the dialect 1 time string: */

UPDATE ATABLE
SET TIME_CAPTURE = CAST(CAPTURE_TIME AS TIME)
WHERE CAPTURE_TIME IS NOT NULL;
COMMIT;

/* The next thing we need to do is temporarily alter our trigger to remove the reference to the dialect 1 time string. This is needed to prevent dependency problems when we want to change and alter the old time string:
*/
SET TERM ^;
RECREATE TRIGGER BI_ATABLE FOR ATABLE
ACTIVE BEFORE INSERT POSITION 1
AS
BEGIN
/*do nothing */
END ^
SET TERM ;^
COMMIT;

/* Now, we can drop the old CAPTURE_TIME column: */

ALTER TABLE ATABLE 
  DROP CAPTURE_TIME;
COMMIT;

/* Create it again, this time as a TIME type: */

ALTER TABLE ATABLE
  ADD CAPTURE_TIME TIME;
COMMIT;

/* Move the data from the temporary column into the newly added CAPTURE_TIME: */

UPDATE ATABLE
  SET CAPTURE_TIME = TIME_CAPTURE
  WHERE TIME_CAPTURE IS NOT NULL;
COMMIT;

/* Drop the temporary column: */
ALTER TABLE ATABLE 
  DROP TIME_CAPTURE;
COMMIT;

/* Finally, fix up the trigger so that it now writes the CAPTURE_TIME value as a
TIME type: */

SET TERM ^;
RECREATE TRIGGER BI_ATABLE FOR ATABLE
ACTIVE BEFORE INSERT POSITION 1
AS
BEGIN
  IF (NEW.CAPTURE_DATE IS NOT NULL)THEN
  BEGIN
    NEW.CAPTURE_TIME = CAST(NEW.CAPTURE_DATE AS TIME);
  END
END ^
SET TERM ;^
COMMIT;

/* Don't forget to end all scripts with a carriage return!! */

