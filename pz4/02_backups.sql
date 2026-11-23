-- ПЗ4. Повна копія, дві зміни даних і дві копії журналу
USE master;
GO

-- 1. повна копія Full1
BACKUP DATABASE PharmacyCopy
    TO DISK = '/var/opt/mssql/backup/PharmacyCopy_Full1.bak'
    WITH INIT, NAME = 'Full1';
GO

-- 2. зміна 1: новий працівник, після неї час T1
INSERT INTO PharmacyCopy.dbo.employees
       (full_name, address, job_title, pharmacy_id)
VALUES (N'Бондар В. О.', N'Ізюм, вул. Соборна, 5',
        N'Фармацевт', 6);
WAITFOR DELAY '00:00:02';
INSERT INTO tempdb.dbo.pz4_points VALUES ('T1', GETDATE());
WAITFOR DELAY '00:00:02';
GO

-- 3. копія журналу Log1
BACKUP LOG PharmacyCopy
    TO DISK = '/var/opt/mssql/backup/PharmacyCopy_Log1.trn'
    WITH INIT, NAME = 'Log1';
GO

-- 4. час T_stop: після Log1, до зміни 2
WAITFOR DELAY '00:00:02';
INSERT INTO tempdb.dbo.pz4_points VALUES ('T_stop', GETDATE());
WAITFOR DELAY '00:00:02';

-- 5. зміна 2: нова посада працівника 3, після неї час T2
UPDATE PharmacyCopy.dbo.employees
   SET job_title = N'Провізор'
 WHERE employee_id = 3;
WAITFOR DELAY '00:00:02';
INSERT INTO tempdb.dbo.pz4_points VALUES ('T2', GETDATE());
WAITFOR DELAY '00:00:02';
GO

-- 6. копія журналу Log2
BACKUP LOG PharmacyCopy
    TO DISK = '/var/opt/mssql/backup/PharmacyCopy_Log2.trn'
    WITH INIT, NAME = 'Log2';
GO

-- перевірка копій
RESTORE VERIFYONLY
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Full1.bak';
RESTORE VERIFYONLY
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log1.trn';
RESTORE VERIFYONLY
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log2.trn';
GO

-- послідовність дій: копії з історії msdb і моменти часу
SELECT name, backup_finish_date AS time
  FROM msdb.dbo.backupset
 WHERE database_name = 'PharmacyCopy'
   AND backup_set_id >= (SELECT MAX(backup_set_id)
                           FROM msdb.dbo.backupset
                          WHERE name = 'Full1')
UNION ALL
SELECT point, t FROM tempdb.dbo.pz4_points
 ORDER BY time;

-- стан після обох змін
SELECT employee_id, full_name, job_title
  FROM PharmacyCopy.dbo.employees;
