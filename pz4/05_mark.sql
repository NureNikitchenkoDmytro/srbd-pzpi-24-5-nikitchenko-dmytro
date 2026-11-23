-- ПЗ4. Маркування транзакцій: WITH MARK і STOPATMARK
USE master;
GO

-- нова повна копія після відновлення
BACKUP DATABASE PharmacyCopy
    TO DISK = '/var/opt/mssql/backup/PharmacyCopy_Full2.bak'
    WITH INIT, NAME = 'Full2';
GO

USE PharmacyCopy;
GO

-- 1-2. маркована транзакція: ціни аптеки 1 більше на 10 %
BEGIN TRANSACTION RaisePrices WITH MARK 'BeforeInventory';
UPDATE stock SET price = price * 1.1 WHERE pharmacy_id = 1;
COMMIT TRANSACTION RaisePrices;
GO

-- 3. копія журналу Log3
BACKUP LOG PharmacyCopy
    TO DISK = '/var/opt/mssql/backup/PharmacyCopy_Log3.trn'
    WITH INIT, NAME = 'Log3';
GO

SELECT pharmacy_id, medicine_id, price FROM stock;
GO

-- 4. руйнівна дія: видалено весь асортимент
DELETE FROM stock;
SELECT COUNT(*) AS stock_rows FROM stock;
GO

-- 5. копія хвоста журналу, БД переходить у RESTORING
USE master;
ALTER DATABASE PharmacyCopy
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
BACKUP LOG PharmacyCopy
    TO DISK = '/var/opt/mssql/backup/PharmacyCopy_Tail.trn'
    WITH INIT, NORECOVERY;
GO

-- відновлення до мітки
RESTORE DATABASE PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Full2.bak'
    WITH NORECOVERY;
RESTORE LOG PharmacyCopy
    FROM DISK = '/var/opt/mssql/backup/PharmacyCopy_Log3.trn'
    WITH RECOVERY, STOPATMARK = 'RaisePrices';
GO

-- остання мітка в msdb і асортимент після відновлення
SELECT TOP (1) mark_name, description, mark_time
  FROM msdb.dbo.logmarkhistory
 WHERE database_name = 'PharmacyCopy'
 ORDER BY mark_time DESC;

SELECT pharmacy_id, medicine_id, price
  FROM PharmacyCopy.dbo.stock;
