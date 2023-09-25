/* 
Q.6. 
Create a stored procedure named sp_prob2_scd_2 to load data from source to target table using SCD Type 2 method. 
Data from all source tables should be loaded to their respective target tables as mentioned in the lookup table named TBLLOOKUP. 
Use Dynamic SQL to implement the same.
Create the target tables (shown in Sample Output below) that maintains all the historical, changed and new data if any in the source data.Maintain a Active flag column (Y/N) in the target table to show if its current or historical data. 
Create a trigger on emp_data table and create a table named EMP_LOGTBL (schema same as emp_data table) to log all the data that are newly inserted into emp_data table. 
Trigger should be invoked whenever a new record is inserted into the emp_data table. 
Once Stored proc and trigger is created,Execute the SP once and full load data from source to target. 
Once that is done, Insert and Update the below records manually in the mentioned source tables: 
(Refer the source tables in TBLLOOKUP table for the data and schema.) 


---------
INPUT::: |
---------

INSERT below records into source tables:
-----------------------------------------

Table_Name	eid		ename		esal	edept 
emp_data	E206	Rebecca		48000	10 
emp_data	E207	Mark		62000	10 


Table_Name		Cust_ID		cust_name	loc		membership 
Customer_src	30016		Danish		Delhi	Yes 
Customer_src	30017		Akhil		Mumbai	No 


Update below records in source tables:
---------------------------------------

Table_Name		eid		ename	esal	edept 
emp_data		E202	Preeta	52000	20 
emp_data		E205	Danny	71000	30


Table_Name		Cust_ID		cust_name	loc			membership 
Customer_src	30014		Celina		Bangalore	Yes 
Customer_src	30012		Thomas		Chennai		Yes 

Above records should be automatically inserted/updated in the target tables in SCD type 2 method after running the stored procedure. 

-----------
OUTPUT::: |
-----------
Sample Target records in Target tables: 


Emp_target table: 
-----------------
eid		ename	esal	edept	Active 
E201	David	40000	10		N 
E201	David	40000	30		Y 


Customer_trg table: 
-------------------
Cust_ID		cust_name	loc			membership	Active 
30014		Celina		Mumbai		Yes			N 
30014		Celina		Bangalore	Yes			Y 


Please keep object names and column names exactly same as mentioned in the question. 
(Tags: Dynamic SQL, Temp tables, Triggers , SCD type2) 

*/
-----------------------------------------------------------------------------------------------------------------


-- Creating Parent Schema
CREATE SCHEMA scd2;


--Creating Source Tables
-------------------------

-- emp_data table:
CREATE TABLE scd2.emp_data (
	eid NVARCHAR(10),
	ename NVARCHAR(20),
	esal INT,
	edept INT
);

-- customer_src table:
CREATE TABLE scd2.customer_src (
	cust_id INT,
	cust_name NVARCHAR(20),
	loc NVARCHAR(20),
	membership NVARCHAR(5)
);


-- Creating Employee Log Table, that will track INSERTED records, based upon Trigger:
--------------------------------------------------------------------------------------
CREATE TABLE scd2.EMP_LOGTBL (
	eid NVARCHAR(10),
	ename NVARCHAR(20),
	esal INT,
	edept INT
);



--Creating Target Tables:
--------------------------

-- emp_target Table:
CREATE TABLE scd2.emp_target (
	eid NVARCHAR(10),
	ename NVARCHAR(20),
	esal INT,
	edept INT,
	active NVARCHAR(1)
);

-- customer_trg Table:
CREATE TABLE scd2.customer_trg (
	cust_id INT,
	cust_name NVARCHAR(20),
	loc NVARCHAR(20),
	membership NVARCHAR(5),
	active NVARCHAR(1)
);


-- Creating Lookup Table scd2.TBLLOOKUP

CREATE TABLE scd2.TBLLOOKUP (
	src_schema NVARCHAR(20),
	src_table NVARCHAR(20),
	trg_schema NVARCHAR(20),
	trg_table NVARCHAR(20)
);

----------------------------------------------------------------------------------------------

-- Inserting the names of Source Tables annd Target Tables into the scd2.TBLLOOKUP table:
INSERT INTO scd2.TBLLOOKUP (src_schema, src_table, trg_schema, trg_table) VALUES
('scd2','emp_data','scd2','emp_target'),
('scd2','customer_src','scd2','customer_trg');

-- Viewing the Lookup Table:
SELECT * FROM scd2.TBLLOOKUP;
-----------------------------------------------------------------------------------------------------------------------------

-- Viewing the column names of individual tables, using query:
--------------------------------------------------------------
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='emp_data';
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='customer_src';
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='emp_target';
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='customer_trg';


------------------------------------------------------------------------------------------------------------------------------

-- INSERTING INITIAL DATA INTO source tables:
----------------------------------------------
-- Clearing the Employee Log Table for fresh running of this script
TRUNCATE TABLE scd2.EMP_LOGTBL;

-- Into Employee Source Table:
INSERT INTO scd2.emp_data (eid, ename, esal, edept) VALUES
('E201', 'David', 40000, 10),
('E206', 'Rebecca', 48000, 10),
('E207', 'Mark', 62000, 10);


-- Into Customer Source Table:
INSERT INTO scd2.customer_src (cust_id, cust_name, loc, membership) VALUES
(30014, 'Celina', 'Mumbai', 'Yes'),
(30016, 'Danish', 'Delhi', 'Yes'),
(30017, 'Akhil', 'Mumbai', 'No');


------------------------------
--Viewing The Source Tables:-|
------------------------------

SELECT * FROM scd2.emp_data;
SELECT * FROM scd2.customer_src;


-- INSERTING UPDATED DATA INTO source tables:
----------------------------------------------

-- Into Employee Source Table:
TRUNCATE TABLE scd2.emp_data;		-- clears all the existsing records such that we can perform fresh data loading

INSERT INTO scd2.emp_data (eid, ename, esal, edept) VALUES
('E201', 'David', 40000, 30),
('E202', 'Preeta', 52000, 20),
('E205', 'Danny', 71000, 30),
('E207', 'Mark', 75000, 10);


-- Into Customer Source Table:
TRUNCATE TABLE scd2.customer_src;

INSERT INTO scd2.customer_src (cust_id, cust_name, loc, membership) VALUES
(30014, 'Celina', 'Bangalore', 'Yes'),
(30012, 'Thomas', 'Chennai', 'Yes'),
(30017, 'Akhil', 'Durgapur', 'No'),
(30011, 'Elon', 'Kolkata', 'No');


-------------------------------------------------------------------------------------------------------

-- Viewing the Log Table:-
SELECT * FROM scd2.EMP_LOGTBL;

-- Defining the insert trigger for the Employee Source Table
DROP TRIGGER scd2.trigger_insert_emp_log;

CREATE TRIGGER trigger_insert_emp_log
ON scd2.emp_data
FOR INSERT
AS
BEGIN
	INSERT INTO scd2.EMP_LOGTBL (eid, ename, esal, edept)
	SELECT eid, ename, esal, edept FROM INSERTED;
END


---------------------------------------------------------------------------------------------------------
/*
	CREATING THE STORED PROCEDURE:- sp_prob2_scd_2
	-----------------------------------------------

	This stored procedure, upon execution, will load all the data from source table to target table using SCD2.
*/

CREATE PROCEDURE sp_prob2_scd_2
AS
BEGIN
	DECLARE @source_schema NVARCHAR(20), @source_table NVARCHAR(20), @target_schema NVARCHAR(20), @target_table NVARCHAR(20);

	DECLARE scd2_cursor CURSOR FOR
	SELECT src_schema, src_table, trg_schema, trg_table FROM scd2.TBLLOOKUP;

	OPEN scd2_cursor;

	FETCH NEXT FROM scd2_cursor INTO @source_schema, @source_table, @target_schema, @target_table;

	DECLARE @sql_query1 NVARCHAR(1000), @sql_query2 NVARCHAR(1000);
	SET @sql_query1 = '';
	SET @sql_query2 = '';

	WHILE (@@FETCH_STATUS=0)
	BEGIN
		-- SCD loading of data into emp_target table:
		IF @source_table = 'emp_data'
		BEGIN
			--SELECT * FROM scd2.emp_data;
			SET @sql_query1 = 'MERGE INTO ' + @target_schema + '.' + @target_table + ' t
			USING ' + @source_schema + '.' + @source_table + ' s
			ON t.eid = s.eid
			WHEN MATCHED AND active = ''Y'' THEN
				UPDATE SET active = ''N'' ; '

			SET @sql_query2 = ' INSERT INTO ' + @target_schema + '.' + @target_table + ' (eid, ename, esal, edept, active)
			SELECT eid, ename, esal, edept, ''Y'' FROM ' + @source_schema + '.' + @source_table + '; '

		END


		-- SCD loading of data into customer_trg table:
		IF @source_table = 'customer_src'
		BEGIN
			-- SELECT * FROM scd2.customer_src;

			SET @sql_query1 = 'MERGE INTO ' + @target_schema + '.' + @target_table + ' t
			USING ' + @source_schema + '.' + @source_table + ' s
			ON t.cust_id = s.cust_id
			WHEN MATCHED AND active = ''Y'' THEN
				UPDATE SET active = ''N''; '

			SET @sql_query2 = 'INSERT INTO ' + @target_schema + '.' + @target_table + ' (cust_id, cust_name, loc, membership, active)
			SELECT cust_id, cust_name, loc, membership, ''Y'' FROM ' + @source_schema + '.' + @source_table + '; '

		END

		-- Printing the Dynamic SQL queries for debugging purpose:
		PRINT @sql_query1;
		PRINT @sql_query2;
		

		--Executing the Dynamic SQL queries set above:
		EXEC sp_executesql @sql_query1;
		EXEC sp_executesql @sql_query2;

		FETCH NEXT FROM scd2_cursor INTO @source_schema, @source_table, @target_schema, @target_table;
	END


	-- Closing the Cursor, and freeing up the resources consumed by it.
	CLOSE scd2_cursor;
	DEALLOCATE scd2_cursor;

END


------------------------------------------------------------------------------------------------------------
-- Testing the created Stored Procedure / Execution of the Stored Procedure:
EXEC sp_prob2_scd_2;

-- CLEAR THE TARGET TABLES for fresh running of stored procedure.
TRUNCATE TABLE scd2.emp_target;
TRUNCATE TABLE scd2.customer_trg;

SELECT * FROM scd2.TBLLOOKUP;
SELECT * FROM scd2.emp_data;
SELECT * FROM scd2.emp_target;
SELECT * FROM scd2.customer_src;
SELECT * FROM scd2.customer_trg;

/*
	To use single quote inside string in SQL that is to escape sequence the single quote, simply double the single quote.
	That is, put single quote twice without space, to get that printed.
*/
