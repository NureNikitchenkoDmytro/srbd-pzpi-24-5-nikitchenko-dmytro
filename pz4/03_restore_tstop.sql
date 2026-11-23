-- ПЗ4. Видалення БД і відновлення на момент T_stop
USE master;
GO

ALTER DATABASE PharmacyCopy
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE PharmacyCopy;
GO

-- повна копія без відновлення
RESTORE DATABASE PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Full1.bak'
    WITH NORECOVERY;
SELECT DATABASEPROPERTYEX('PharmacyCopy', 'Status') AS status;
GO

-- Log1 повністю, щоб потім застосувати Log2
RESTORE LOG PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log1.trn'
    WITH NORECOVERY;
SELECT DATABASEPROPERTYEX('PharmacyCopy', 'Status') AS status;
GO

-- Log2 до моменту T_stop
DECLARE @t DATETIME = (SELECT t FROM tempdb.dbo.pz4_points
                        WHERE point = 'T_stop');
RESTORE LOG PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log2.trn'
    WITH RECOVERY, STOPAT = @t;
SELECT DATABASEPROPERTYEX('PharmacyCopy', 'Status') AS status;
GO

-- новий працівник є, посада працівника 3 не змінилась
SELECT employee_id, full_name, job_title
  FROM PharmacyCopy.dbo.employees;
