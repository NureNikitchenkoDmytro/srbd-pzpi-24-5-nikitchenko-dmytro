-- ПЗ4. Підготовка: копія БД Pharmacy для роботи
USE master;
GO

-- стара копія з попереднього запуску
IF DATABASEPROPERTYEX('PharmacyCopy', 'Status') = 'ONLINE'
    ALTER DATABASE PharmacyCopy
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
IF DB_ID('PharmacyCopy') IS NOT NULL
    DROP DATABASE PharmacyCopy;
GO

-- копія Pharmacy, щоб не змінювати БД попередніх робіт
BACKUP DATABASE Pharmacy
    TO DISK = '/var/opt/mssql/backup/Pharmacy_copy.bak'
    WITH COPY_ONLY, INIT;

RESTORE DATABASE PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/Pharmacy_copy.bak'
    WITH MOVE 'Pharmacy'
             TO '/var/opt/mssql/data/PharmacyCopy.mdf',
         MOVE 'Pharmacy_log'
             TO '/var/opt/mssql/data/PharmacyCopy_log.ldf';
GO

-- модель відновлення FULL
ALTER DATABASE PharmacyCopy SET RECOVERY FULL;
GO

-- моменти часу зберігаються поза PharmacyCopy,
-- бо її будемо видаляти
IF OBJECT_ID('tempdb.dbo.pz4_points') IS NOT NULL
    DROP TABLE tempdb.dbo.pz4_points;
CREATE TABLE tempdb.dbo.pz4_points (
    point VARCHAR(10) PRIMARY KEY,
    t     DATETIME    NOT NULL
);
GO

SELECT name, recovery_model_desc, state_desc
  FROM sys.databases
 WHERE name IN ('Pharmacy', 'PharmacyCopy');
