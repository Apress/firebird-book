/* The following procedure is a piece of superstitious fun, assuming there is truth in the proverb “Never eat pork when there is an ‘R’ in the month,” it returns an opinion about a given date. For the sake of illustration, it declares one local variable that is used to get a starting condition for a WHILE loop and another to control the number of times the loop will execute: */

SET TERM ^;
CREATE PROCEDURE IS_PORK_SAFE(CHECK_MONTH DATE)
RETURNS (RESPONSE CHAR(3))
AS
DECLARE VARIABLE SMONTH VARCHAR(9);
DECLARE VARIABLE SI SMALLINT;
BEGIN
  SI =0;
  RESPONSE ='NO ';
  SELECT 
    CASE (EXTRACT (MONTH FROM :CHECK_MONTH))
    WHEN 1 THEN 'JANUARY'
    WHEN 2 THEN 'FEBRUARY'
    WHEN 3 THEN 'MARCH'
    WHEN 4 THEN 'APRIL'
    WHEN 5 THEN 'MAY'
    WHEN 6 THEN 'JUNE'
    WHEN 7 THEN 'JULY'
    WHEN 8 THEN 'AUGUST'
    WHEN 9 THEN 'SEPTEMBER'
    WHEN 10 THEN 'OCTOBER'
    WHEN 11 THEN 'NOVEMBER'
    WHEN 12 THEN 'DECEMBER'
    END
  FROM RDB$DATABASE INTO :SMONTH;
  WHILE (SI <9)DO
  BEGIN
    SI =SI +1;
    IF (SUBSTRING(SMONTH FROM 1 FOR 1)='R')THEN
    BEGIN
      RESPONSE ='YES';
      LEAVE;
    END
    SMONTH =SUBSTRING(SMONTH FROM 2);
  END
END ^
COMMIT ^
SET TERM ;^

/* Note also - the practical way to do this test! */ 

  IF (SMONTH CONTAINING 'R') THEN 
    RESPONSE ='YES';
  ELSE 
    RESPONSE ='NO ';


