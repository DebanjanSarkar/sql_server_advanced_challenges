/*
Q.1. Create a stored procedure to get the number of hours between two dates having a DateTime format. You should exclude all 
Sundays and 1st and 2nd Saturdays if it comes within the date range.

If either of the input dates are Sunday or the 1st or 2nd Saturday, then INCLUDE that particular date too. 

Stored procedure will have two input parameters - Start_Date and End_Date. 
Execute your stored procedure only for the below dates and store the result in a table named COUNTWORKINGHOURS in the below 
format (Sample Output). (Tag: Create Procedure, Date Functions)

Please keep object name as follows: Procedure Name -> SP_COUNTWORKINGHOURS 
Execute SP for below dates: 

START_DATE			END_DATE 
----------------    ----------------
2023-07-01 00:00	2023-07-17 00:00 
2023-05-22 00:00	2023-06-04 00:00 
2023-07-07 00:00	2023-07-08 23:00 
2023-03-05 00:00	2023-03-26 00:00 
2023-07-12 00:00	2023-07-13 00:00
*/

CREATE PROCEDURE SP_COUNTWORKINGHOURS
@start_date DATETIME,
@end_date DATETIME,
@working_hours BIGINT OUTPUT
AS
BEGIN
	DECLARE @current_date DATETIME = @start_date;
	SET @working_hours = 0;
	-- IF @start_date is Sunday or 1st or second saturday, then 24 hours will be counted.
	IF ( DATEDIFF(HOUR,@start_date, @end_date ) >= 24 )
	BEGIN
		IF ( DATENAME(WEEKDAY, @start_date) = 'Sunday' )
		BEGIN
			SET @working_hours += 24;
		END
		IF ( DATENAME(WEEKDAY, @start_date) = 'Saturday' ) AND ( DATENAME(DAY, @start_date) <= 14 )
		BEGIN
			SET @working_hours += 24;
		END
	END
	----------------------------------------------------------------------------------------------


	-- Main loop counting the number of hours for each progressive day.
	-- If difference between current datetime and end datetime is more than equal to 24 hours then this logic should be executed.
	WHILE ( DATEDIFF(HOUR,@current_date, @end_date ) >= 24 )
	BEGIN
		--If current day is Sunday, then it will be skipped and simply not counted.
		IF ( DATENAME(WEEKDAY, @current_date) <> 'Sunday' )
		BEGIN
			-- If the date is not Sunday and not Saturday, 24 hours will be counted.
			IF ( DATENAME(WEEKDAY, @current_date) <> 'Saturday' )
			BEGIN
				SET @working_hours += 24;
			END
			-- If the date is Saturday, and day of month is greater than 14, then 24 hours will be counted.
			ELSE IF ( DATENAME(WEEKDAY, @current_date) = 'Saturday' ) AND ( DATENAME(DAY, @current_date) > 14 )
			BEGIN
				SET @working_hours += 24;
			END
		END

		SET @current_date = DATEADD(DAY, 1, @current_date);
	END

	/*
	IF the hours of @start_date and @end_date do not match, there will be difference in time between @current_date and 
	@end_date after termination of the above while loop.
	Thus, that remaining hours should be added to the working hours.

	This logic is controlled separately, as the last day partial hours should be included for every day(no weekend for last date)
	*/
	IF ( DATEDIFF(HOUR, @current_date, @end_date) > 0 )
	BEGIN
		SET @working_hours += DATEDIFF(HOUR, @current_date, @end_date);
	END
END


-- Testing the output of the above stored procedure.
DECLARE @inp1 DATETIME, @inp2 DATETIME, @op BIGINT;
SET @inp1 = '2023-07-01 00:00:00.000';
SET @inp2 = '2023-07-17 00:00:00.000';

--SET @inp1 = '2023-07-07 00:00';
--SET @inp2 = '2023-07-08 23:00';
--PRINT DATEDIFF(HOUR,@inp1, @inp2 )
EXEC SP_COUNTWORKINGHOURS @inp1, @inp2, @op OUTPUT;
PRINT 'No. of working hours: ' + CAST( @op AS NVARCHAR );


-----------------------------------------------------------------------------------------------------------------
/*
	Driver Script
	This script will run above stored procedure for the given dates provided, and store the output in the COUNTWORKINGHOURS table

*/

CREATE TABLE COUNTWORKINGHOURS (
	START_DATE DATETIME NOT NULL,
	END_DATE DATETIME NOT NULL,
	NO_OF_HOURS BIGINT
);

/*
START_DATE			END_DATE 
----------------    ----------------
2023-07-01 00:00	2023-07-17 00:00 
2023-05-22 00:00	2023-06-04 00:00 
2023-07-07 00:00	2023-07-08 23:00 
2023-03-05 00:00	2023-03-26 00:00 
2023-07-12 00:00	2023-07-13 00:00
*/

DECLARE @st_dt DATETIME, @end_dt DATETIME, @hrs BIGINT;
--SET @st_dt = '2023-07-01 00:00';
--SET @end_dt = '2023-07-17 00:00';

SET @st_dt = '2023-07-12 00:00';
SET @end_dt = '2023-07-13 00:00';

EXECUTE SP_COUNTWORKINGHOURS @st_dt, @end_dt, @hrs OUTPUT;

INSERT INTO COUNTWORKINGHOURS ( START_DATE, END_DATE, NO_OF_HOURS ) VALUES
(@st_dt, @end_dt, @hrs);


----------------------------------------------------------------------------------------------------
-- Checking the table where the results are stored
SELECT * FROM COUNTWORKINGHOURS;
