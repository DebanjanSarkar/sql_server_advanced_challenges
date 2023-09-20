/*
	This script shows the use of Merge statements.
	Use Cases are:-
	1. Using MERGE statement to make the target table exactly same as the source table(all records of target table will contain
	   exactly same data as the source table, with additionally the dates being the current date.

	2. Applying SCD1 loading from source to target table.
	   The target table will have the new data records in the source table inserted.
	   The matching data records will be updated.
	   The records in target table not existing in source table will remain untouched.
	   The dates of updated and inserted records will be the current date.
*/

-- Creating the Schema to hold all our tables
-- CREATE SCHEMA IF NOT EXISTS scd1;
-- GO;

-- Creating Target table in initial state
-- DROP TABLE scd1.customer_target
create table scd1.customer_target
(
	c_mobile bigint primary key,
	c_name nvarchar(30),
	c_dob date,
	c_email nvarchar(100),
	c_insert_dt date,
	c_update_dt date
)

DECLARE @date DATE = '2019-05-24';

insert into scd1.customer_target values (111111111,'Jon Groff','1980-03-10',NULL,@date,@date);
insert into scd1.customer_target values (222222222,'Kenneth Jarrett','1986-08-24',NULL,@date,@date);
insert into scd1.customer_target values (333333333,'Daniel Jensen','1972-08-22',NULL,@date,@date);
insert into scd1.customer_target values (444444444,'Jeffrey Kramer','1987-04-15',NULL,@date,@date);
insert into scd1.customer_target values (555555555,'Pete  Bartels','1989-11-16',NULL,@date,@date);

-- Viewing the target table 
SELECT * FROM scd1.customer_target;


-- Creating the Source Table
-- DROP TABLE scd1.customer_source;
create table scd1.customer_source
(
	c_mobile bigint PRIMARY KEY,
	c_name varchar(30),
	c_dob date,
	c_email varchar(100)
)

insert into scd1.customer_source values (111111111,'Jon Groff','1980-03-10','jon.groff@gmail.com');
insert into scd1.customer_source values (222222222,'Kenneth Jarrett','1986-10-24',NULL);
insert into scd1.customer_source values (333333333,'Daniel Craig','1972-08-22',NULL);
insert into scd1.customer_source values (444444444,'Jeffrey Kramer','1987-04-15',NULL);
insert into scd1.customer_source values (666666666,'John Snow','1982-02-11',NULL);
insert into scd1.customer_source values (777777777,'Arya Stark','1998-05-16',NULL);


-- Viewing the source table
SELECT * FROM scd1.customer_source;


------------------------------------------------------------------------------------------------------------

-- 1st usecase -> will make the target table exactly same as the source table, and dates will be todays date.
MERGE INTO scd1.customer_target t
USING scd1.customer_source s
ON t.c_mobile = s.c_mobile
WHEN MATCHED THEN
	UPDATE SET c_name = s.c_name, c_dob = s.c_dob, c_email = s.c_email
WHEN NOT MATCHED BY TARGET THEN
	INSERT (c_mobile, c_name, c_dob, c_email, c_insert_dt, c_update_dt)
	VALUES (s.c_mobile, s.c_name, s.c_dob, s.c_email, getdate(), getdate())
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

----------------------------------------------------------------------------------------------------------------

-- 2nd usecase -> SCD1 loading of data into Target table using Source table.
--				  New records in source table will be inserted, existing matching records in source table will be updated.
MERGE INTO scd1.customer_target t
USING scd1.customer_source s
ON t.c_mobile = s.c_mobile
WHEN MATCHED THEN 
	UPDATE SET c_name = s.c_name, c_dob=s.c_dob, c_email=s.c_email, c_insert_dt=getdate(), c_update_dt=getdate()
WHEN NOT MATCHED BY TARGET THEN
	INSERT (c_mobile, c_name, c_dob, c_email, c_insert_dt, c_update_dt)
	VALUES (s.c_mobile, s.c_name, s.c_dob, s.c_email, getdate(), getdate());

----------------------------------------------------------------------------------------------------------------