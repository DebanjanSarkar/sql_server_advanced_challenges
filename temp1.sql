DECLARE @query NVARCHAR(200), @table NVARCHAR(50);
SET @table = 'employee_main';

SET @query = ' SELECT * FROM scd2.' + @table + ' WHERE eName=''Mohan''; '

EXECUTE sp_executesql @query;