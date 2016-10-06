
The Firebird/InterBase(R) Employee.fdb database scripts
=======================================================

These scripts will recreate the employee.fdb database 
in dialect 3 with a default character set of ISO8859_1. 

Get into a command shell and move the employee.fdb database
into the /examples directory. 

Note that you may need to edit the scripts if your paths, 
SYSDBA credentials and/or default character set need to 
be different to those in the script. 

cd to the Firebird /bin directory and start isql.

Run the DDL script first.  

   SET NAMES and the default character set for the database 
   are both set up as ISO8859_1.  Change *both* if you need 
   to use a different default character set.

   CREATE DATABASE statements are given for both Linux and
   Win32.  Change the database path, user name and 
   password as and if required. 

   Comment the line containing the Linux path if you are 
   running a Win32, and uncomment the Win32 path. 

   There is a COMMIT statement at the end of the DDL script,
   that is commented out.  Uncomment it if you want the 
   work committed by the script;  otherwise, you may enter a 
   commit statement at the SQL> prompt when the script 
   completes. 

After committing the DDL script, run the DML script. 

   Again, it will be necessary to fix up SET NAMES, the 
   database path, user name and password for your local 
   conditions. 

   Commit the work when the script completes and you will 
   have your own dialect 3, local character set version of
   the abominable employee database! 

Helen Borrie 


