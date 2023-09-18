/*
Stored procedure to take 2 datetime values as i/p  parameters, and return number of working days in between as o/p parameter
Leaving Saturdays and Sundays, all the days are working days ( no holiday assumed ).
Both the start_date and end_date (input parameters) will be included in the duration.

NOTE:-
The DATEDIFF() function counts number of weeks by counting the number of full-set of Saturdays and Sundays between the dates provided.
If the start_date is a Sunday, and end_date is next sunday to friday, it will be counted as only 1 week as 1-complete-set weekend occurs in b/w.
Similaryly, if end_date is a Saturday, generally the number of weeks will be 1 lesser than expected due to the above reason.
*/

CREATE PROCEDURE num_of_working_days
@start_date DATETIME,
@end_date DATETIME,
@working_days INT OUTPUT
AS
BEGIN
	SELECT @working_days = (
		DATEDIFF(DAY, @start_date, @end_date) + 1 --adding 1 since the start_date should be included in counting of working days.
		-
		( DATEDIFF(WEEK,@start_date,@end_date) * 2 ) --every week will have 2 holidays, thus subtracting 2*no of weeks in between.
		-
		(CASE WHEN DATENAME(WEEKDAY, @start_date) = 'Sunday' THEN 1 ELSE 0 END)
		-
		(CASE WHEN DATENAME(WEEKDAY, @end_date) = 'Saturday' THEN 1 ELSE 0 END)
		)
END

DECLARE @OUTPUT INT, @DAY1 DATETIME, @DAY2 DATETIME;
SET @DAY1 = '2015-01-08';
SET @DAY2 = '2015-01-10';
EXEC num_of_working_days @DAY1, @DAY2, @OUTPUT OUTPUT;
PRINT @OUTPUT;


/*
Some functions used above, are tested with syntax below:-

SELECT CASE WHEN 'Saturday' =DATENAME(weekday, '2023-09-23') THEN 1 ELSE 0 END;

DECLARE @DATE1 DATETIME, @DATE2 DATETIME;
SET @DATE1='2023-09-16';
SET @DATE2='2023-09-23';
SELECT DATEDIFF(WEEK, @DATE1, @DATE2);

SELECT DATENAME(WEEKDAY, '2023-09-16');
SELECT DATENAME(MONTH, '2023-09-16');
SELECT DATEPART(month, '2023-09-16');

SELECT DATEDIFF(DAY, '2023-09-16','2023-09-18');
*/