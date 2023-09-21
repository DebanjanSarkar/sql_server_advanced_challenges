/*
	Implementing SCD Type 2
	-----------------------
	- In SCD Type 2, the current values as well as the historical values are kept stored in the same table.
	- The new records and the updated records in new table - both are inserted as new records in the original table.
	- There are duplicate keyed records present, as both historical and new records are kept stored.
	- Validity of records are marked by a Flag column, and validity begining and ending date.
	- When a record needs updation, existing record flag is changed to invalid, and inserted record is marked as valid.
	- Fetching data values are complex, and needs use of both Key value and valid flag.
*/


-- Creating Datasets
-------------------------
-- CREATE SCHEMA scd2;


-- DROP TABLE IF EXISTS scd2.employee_main;

-- Creating and inserting initial valued records the main table the will contain all the records.
CREATE TABLE scd2.employee_main (
	empId INT,
	eName NVARCHAR(20),
	salary INT,
	deptNo INT,
	isValid BIT
);

INSERT INTO scd2.employee_main (empId, eName, salary, deptNo, isValid) VALUES
(101, 'Ravi', 5000, 10, 1),
(102, 'Krishna', 4000, 20, 1),
(103, 'Mohan', 6000, 10, 1),
(104, 'Anand', 3000, 30, 1);

-- Viewing the main table
SELECT * FROM scd2.employee_main;

---------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS scd2.employee_updates;

-- Creating the table containing updated records 
CREATE TABLE scd2.employee_updates (
	empId INT,
	eName NVARCHAR(20),
	salary INT,
	deptNo INT
);

INSERT INTO scd2.employee_updates (empId, eName, salary, deptNo) VALUES
(102, 'Krishna', 7000, 20),
(105, 'Praveen', 4000, 30),
(103, 'Mohan', 6000, 20);


-- Viewing the table coontaing updated and new records
SELECT * FROM scd2.employee_updates;

---------------------------------------------------------------------------------------------------
-- APPROACH 1
--------------
-- Applying SCD Type 2 loading of data from Updates Table to the Main Table using CURSOR
DECLARE @id INT, @name NVARCHAR(20), @salary INT, @deptno INT;

DECLARE scd2_cursor CURSOR FOR
SELECT empId, eName, salary, deptNo FROM scd2.employee_updates;

OPEN scd2_cursor;

FETCH NEXT FROM scd2_cursor INTO @id, @name, @salary, @deptno;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	UPDATE scd2.employee_main SET isValid = 0 WHERE empId = @id;

	INSERT INTO scd2.employee_main (empId, eName, salary, deptNo, isValid) VALUES
	(@id, @name, @salary, @deptno, 1);

	FETCH NEXT FROM scd2_cursor INTO @id, @name, @salary, @deptno;
END

CLOSE scd2_cursor;

DEALLOCATE scd2_cursor;

-----------------------------------------------------------------------------------------------

-- APPROACH 2
--------------
-- Using MERGE and INSERT SCD Type 2 loading of data from Updates Table to the Main Table.
-- a. At first, using MERGE statement too set the isValid flag of matching records to 0
-- b. Then, using INSERT SELECT statement to insert all the records of updates table to main table.

-- This approach results in faster execution.

MERGE INTO scd2.employee_main t
USING scd2.employee_updates s
ON t.empId = s.empId
WHEN MATCHED AND isValid=1 THEN
	UPDATE SET isValid = 0;

INSERT INTO scd2.employee_main (empId, eName, salary, deptNo, isValid)
SELECT empId, eName, salary, deptNo, 1 FROM scd2.employee_updates;

-------------------------------------------------------------------------------------

/*
	As a STANDARD PROCESS OF SCD TYPE 2 loading of data on regular basis, following are the best practices:-
	- Only 1 main(all-data containing) table, and 1 staging table(table containing updates to be applied).
	- Each time SCD Type 2 loading occurs, after that, the staging table should be truncated using TRUNCATE TABLE statement.
	- Avoid creating multiple staging tables each time, instead, truncating table before it gets fresh updates data is preffered.
*/
