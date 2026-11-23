-- ПЗ4. Варіант 1 (9 mod 4 = 1): відновлення на T_stop
-- (після Log1, до зміни 2). STOPAT вказано в обох RESTORE LOG.
USE master;
GO

ALTER DATABASE PharmacyCopy
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE PharmacyCopy;
GO

DECLARE @t DATETIME = (SELECT t FROM tempdb.dbo.pz4_points
                        WHERE point = 'T_stop');

RESTORE DATABASE PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Full1.bak'
    WITH NORECOVERY;

-- T_stop пізніше кінця Log1: Log1 застосовується повністю
RESTORE LOG PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log1.trn'
    WITH NORECOVERY, STOPAT = @t;
SELECT DATABASEPROPERTYEX('PharmacyCopy', 'Status') AS status;

RESTORE LOG PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log2.trn'
    WITH RECOVERY, STOPAT = @t;
SELECT DATABASEPROPERTYEX('PharmacyCopy', 'Status') AS status;
GO

SELECT employee_id, full_name, job_title
  FROM PharmacyCopy.dbo.employees;
