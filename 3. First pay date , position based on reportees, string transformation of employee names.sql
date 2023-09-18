/*

Q.4. Refer the tables Employee and Department. 
Emps hired on or before 15th of any month are paid on the last Friday of that month. 
Those hired after 15th are paid on the first Friday of the following month. 

Create a view to display all details of employees with their hire date and their first pay date. 
Display one column called NEW_NAME which will show first 50% part of the name in lower case and remaining part of the name in upper case. 
Display one more column called EMP_JOB showing first name of employee with his/her job (job in bracket). 
E.g., David (Shopkeeper). 

Display another column called EMP_POSITION. 
An employee who has at least 2 reportees reporting to him, mark his postion as SUPER SENIOR whereas mark others as SENIOR 
(Tag: Views, String functions, Date functions, Union, Joins) 

Please keep object name as follows: View Name --> VW_EMP_DETAILS Sample Output :- 

(Please keep same column names as below) 

empid	name			salary	hiredate		paydate		deptid		New_Name		Emp_job					Emp_Position 
1001	Rahul P Roy		55000	2020-01-21		2020-02-07	D001		rahul P ROY		Rahul (Accounting)		Senior 
1004	Riya Sharma		45500	2021-03-13		2021-03-26	D003		riya SHARMA		Riya (IT)				Super Senior 
1009	Jeena			12000	2018-11-17		2018-12-07	D004		jeENA			Jeena (Sales)			Senior

*/

DROP TABLE Employees;
DROP TABLE Department;

CREATE TABLE Employees (
	empid INT,
	name NVARCHAR(50),
	deptid NVARCHAR(5),
	salary INT,
	hiredate DATE,
	reports_to_id INT
);

CREATE TABLE Department (
	deptid NVARCHAR(5),
	deptname NVARCHAR(50)
);

INSERT INTO Employees (empid, name, deptid,	salary,	hiredate, reports_to_id) VALUES
(1001, 'Rahul P Roy', 'D001', 55000, '2020-01-21', 1004),
(1004, 'Riya Sharma', 'D003', 45500, '2021-03-13', NULL),
(1009, 'Jeena', 'D004', 12000, '2018-11-17', 1004);

INSERT INTO Department (deptid, deptname) VALUES
('D001', 'Accounting'),
('D003', 'IT'),
('D004', 'Sales');

SELECT * FROM Employees;
SELECT * FROM Department;

-------------------------------------------------------------------------------------------------
-- We here create a function, that will take hiredate, and will return the paydate.

CREATE FUNCTION udf_getFirstPayDate(@hiredate DATE)
RETURNS DATE
AS
BEGIN
/*
	Logic:-
	- We will initialise the @paydate with the first day of the next month of the @hiredate month
	- If the @hiredate is less than equal to 15 of the month, we will keep descreasing @paydate by one day, while searching for 
	  Friday. When Friday is encountered, we will return that date.
	- If the @hiredate is greater than 15 of that month, we will keep incrementing @paydate day-by-day, and when Friday is found,
	  will return that date.
*/
	DECLARE @paydate DATE;
	SET @paydate = CAST(DATEPART(YEAR,@hiredate) AS NVARCHAR) + '-' + CAST( (DATEPART(MONTH,@hiredate)+1) AS NVARCHAR) + '-01';

	IF (DATEPART(DAY, @hiredate) > 15)
	BEGIN
		WHILE ( DATENAME(WEEKDAY, @paydate) <> 'Friday' )
		BEGIN
			SET @paydate = DATEADD( DAY, 1, @paydate );
		END

		RETURN @paydate;
	END
	ELSE
	BEGIN
		-- Decreasing 1 day before the loop, such that in case 1st day is already a friday, loop do run to find the last friday
		-- of the previous month.
		SET @paydate = DATEADD( DAY, -1, @paydate );
		WHILE ( DATENAME(WEEKDAY, @paydate) <> 'Friday' )
		BEGIN
			SET @paydate = DATEADD( DAY, -1, @paydate );
		END

		RETURN @paydate;
	END

	RETURN @paydate;
END


-- Testing the Function created above
SELECT dbo.udf_getFirstPayDate('2023-08-08');
SELECT dbo.udf_getFirstPayDate('2023-08-18');

--------------------------------------------------------------------------------------------------------

-- Creating the main view:-
CREATE VIEW VW_EMP_DETAILS
AS
SELECT 
	empid,
	name,
	salary,
	hiredate,
	dbo.udf_getFirstPayDate(hiredate) AS paydate,
	e.deptid,
	LOWER(LEFT(name, LEN(name)/2)) + UPPER( RIGHT( name, LEN(name) - ( LEN(name)/2 ) ) ) AS New_Name,
	CASE 
		WHEN CHARINDEX(' ', RTRIM(name) ) > 0
		THEN LEFT(name,CHARINDEX(' ', name)) + '(' + deptname + ')'
		ELSE name + '(' + deptname + ')'
	END Emp_job,
	CASE 
		WHEN ( SELECT COUNT(reports_to_id) FROM Employees inr_e WHERE inr_e.reports_to_id = e.empid ) >= 2
		THEN 'Super Senior'
		ELSE 'Senior'
	END AS Emp_Position
	--( SELECT COUNT(reports_to_id) FROM Employees inr_e WHERE inr_e.reports_to_id = e.empid ) Reportees_count,
	--reports_to_id,
	--deptname
FROM Employees e
JOIN Department d
ON e.deptid = d.deptid;


---------------------------------------------------------------------------------------------------------------
-- Testing the View
SELECT * FROM VW_EMP_DETAILS;

---------------------------------------------------------------------------------------------------------------

-- Syntax of some functions used above ( for reference ):-
SELECT CASE WHEN 'Saturday' =DATENAME(weekday, '2023-09-23') THEN 1 ELSE 0 END;

DECLARE @DATE1 DATETIME, @DATE2 DATETIME;
SET @DATE1='2023-09-16';
SET @DATE2='2023-09-23';
DECLARE @paydate DATE, @hiredate DATE;

SET @hiredate = '2020-01-21';
SELECT DATEPART(DAY, @hiredate);

SET @paydate = CAST(DATEPART(YEAR,@hiredate) AS NVARCHAR) + '-' + CAST( (DATEPART(MONTH,@hiredate)+1) AS NVARCHAR) + '-01';

SELECT DATEADD(day,5,@paydate);


SELECT FLOOR(11.0/2), CEILING(11.0/2), ROUND(11.0/2,1), 11/2;


DECLARE @str NVARCHAR(20) = 'Fantabulous';
SELECT LEFT(@str,5), RIGHT(@str,5), CHARINDEX('t', @str, 3), SUBSTRING(@str, 3, 5);
------------------------------------------------------------------------------------------------------------------------------
