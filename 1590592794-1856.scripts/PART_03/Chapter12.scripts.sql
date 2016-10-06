/* Simple demonstration of how a DSQL application can get limited read access to an array slice through a stored procedure: */

SET TERM ^;
create procedure getcharslice(
  low_elem smallint,
  high_elem smallint)
returns ( 
  id integer,
  list varchar(50))
as
declare variable i smallint;
declare variable string varchar(10);

begin
  for select a1.ID from ARRAYS a1 
  into :id do
  begin
    i=low_elem;
    list ='';
    while (i <=high_elem) do
    begin
      select a2.CHARARRAY [:i ] from arrays a2
        where a2.ID =:id
        into :string;
      list =list||string;
      if (i <high_elem) then
        list =list||',';
      i =i +1;
    end
    suspend;
  end
end ^ 
SET TERM ;^

/* cARRIAGE RETURN! */


