-- ПЗ4. Прибирання після захисту: завдання, процедура, копія БД
USE msdb;
GO
IF EXISTS (SELECT * FROM sysjobs WHERE name = N'pharmacy_full')
    EXEC sp_delete_job @job_name = N'pharmacy_full';
IF EXISTS (SELECT * FROM sysjobs WHERE name = N'pharmacy_diff')
    EXEC sp_delete_job @job_name = N'pharmacy_diff';
IF EXISTS (SELECT * FROM sysjobs WHERE name = N'pharmacy_log')
    EXEC sp_delete_job @job_name = N'pharmacy_log';
GO

USE master;
GO
DROP PROCEDURE IF EXISTS dbo.usp_backup_pharmacy;
IF DATABASEPROPERTYEX('PharmacyCopy', 'Status') = 'ONLINE'
    ALTER DATABASE PharmacyCopy
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
IF DB_ID('PharmacyCopy') IS NOT NULL
    DROP DATABASE PharmacyCopy;
GO
