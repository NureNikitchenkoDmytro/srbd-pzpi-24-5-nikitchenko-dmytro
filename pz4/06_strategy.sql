-- ПЗ4. Стратегія резервування БД Pharmacy (робота 24/7):
-- RPO <= 15 хв, RTO <= 30 хв, відновлення за останні 7 днів.
-- Повна копія щодня о 00:00, різницева кожні 4 год,
-- журнал кожні 10 хв, файли зберігаються 8 днів.
USE master;
GO

ALTER DATABASE Pharmacy SET RECOVERY FULL;
EXEC sys.xp_create_subdir N'/var/opt/mssql/backup/plan';
GO

-- копія заданого типу у файл з датою і часом в імені
CREATE OR ALTER PROCEDURE dbo.usp_backup_pharmacy
    @type VARCHAR(4)    -- FULL, DIFF або LOG
AS
BEGIN
    DECLARE @file NVARCHAR(200) =
        N'/var/opt/mssql/backup/plan/Pharmacy_' + @type + N'_'
        + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')
        + IIF(@type = 'LOG', N'.trn', N'.bak');

    IF @type = 'FULL'
    BEGIN
        BACKUP DATABASE Pharmacy TO DISK = @file WITH INIT;
        -- видалення копій, старших за 8 днів
        DECLARE @old DATETIME = DATEADD(DAY, -8, GETDATE());
        EXEC sys.xp_delete_file 0, N'/var/opt/mssql/backup/plan/',
             N'bak', @old, 0;
        EXEC sys.xp_delete_file 0, N'/var/opt/mssql/backup/plan/',
             N'trn', @old, 0;
    END
    ELSE IF @type = 'DIFF'
        BACKUP DATABASE Pharmacy TO DISK = @file
            WITH DIFFERENTIAL, INIT;
    ELSE IF @type = 'LOG'
        BACKUP LOG Pharmacy TO DISK = @file WITH INIT;
    ELSE
        THROW 50020, N'Тип копії: FULL, DIFF або LOG', 1;
END
GO

USE msdb;
GO

-- при повторному запуску старі завдання видаляються
IF EXISTS (SELECT * FROM sysjobs WHERE name = N'pharmacy_full')
    EXEC sp_delete_job @job_name = N'pharmacy_full';
IF EXISTS (SELECT * FROM sysjobs WHERE name = N'pharmacy_diff')
    EXEC sp_delete_job @job_name = N'pharmacy_diff';
IF EXISTS (SELECT * FROM sysjobs WHERE name = N'pharmacy_log')
    EXEC sp_delete_job @job_name = N'pharmacy_log';
GO

-- повна копія: щодня о 00:00
EXEC sp_add_job @job_name = N'pharmacy_full';
EXEC sp_add_jobstep @job_name = N'pharmacy_full',
     @step_name = N'full',
     @command = N'EXEC master.dbo.usp_backup_pharmacy ''FULL''';
EXEC sp_add_jobschedule @job_name = N'pharmacy_full',
     @name = N'daily_0000', @freq_type = 4, @freq_interval = 1,
     @active_start_time = 0;
EXEC sp_add_jobserver @job_name = N'pharmacy_full';
GO

-- різницева копія: кожні 4 години з 04:00
EXEC sp_add_job @job_name = N'pharmacy_diff';
EXEC sp_add_jobstep @job_name = N'pharmacy_diff',
     @step_name = N'diff',
     @command = N'EXEC master.dbo.usp_backup_pharmacy ''DIFF''';
EXEC sp_add_jobschedule @job_name = N'pharmacy_diff',
     @name = N'every_4h', @freq_type = 4, @freq_interval = 1,
     @freq_subday_type = 8, @freq_subday_interval = 4,
     @active_start_time = 40000;
EXEC sp_add_jobserver @job_name = N'pharmacy_diff';
GO

-- копія журналу: кожні 10 хвилин
EXEC sp_add_job @job_name = N'pharmacy_log';
EXEC sp_add_jobstep @job_name = N'pharmacy_log',
     @step_name = N'log',
     @command = N'EXEC master.dbo.usp_backup_pharmacy ''LOG''';
EXEC sp_add_jobschedule @job_name = N'pharmacy_log',
     @name = N'every_10min', @freq_type = 4, @freq_interval = 1,
     @freq_subday_type = 4, @freq_subday_interval = 10,
     @active_start_time = 0;
EXEC sp_add_jobserver @job_name = N'pharmacy_log';
GO

-- перший запуск вручну, спочатку повна копія
EXEC sp_start_job @job_name = N'pharmacy_full';
WAITFOR DELAY '00:00:05';
EXEC sp_start_job @job_name = N'pharmacy_diff';
WAITFOR DELAY '00:00:05';
EXEC sp_start_job @job_name = N'pharmacy_log';
WAITFOR DELAY '00:00:05';
GO

-- завдання і їх розклад
SELECT j.name AS job, s.name AS schedule,
       s.freq_subday_interval AS every,
       CASE s.freq_subday_type WHEN 1 THEN 'once a day'
            WHEN 4 THEN 'minutes' WHEN 8 THEN 'hours' END AS unit,
       s.active_start_time AS start_time, j.enabled
  FROM msdb.dbo.sysjobs AS j
  JOIN msdb.dbo.sysjobschedules AS js ON js.job_id = j.job_id
  JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
 WHERE j.name LIKE N'pharmacy[_]%';

-- створені копії
SELECT b.type, b.backup_finish_date, f.physical_device_name
  FROM msdb.dbo.backupset AS b
  JOIN msdb.dbo.backupmediafamily AS f
    ON f.media_set_id = b.media_set_id
 WHERE f.physical_device_name LIKE N'%/plan/%'
 ORDER BY b.backup_finish_date;
