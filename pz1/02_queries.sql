-- ПЗ1. 10 запитів до системного каталогу.
-- M = 9, Ni = (M + 3*(i-1)) mod 16: 9, 12, 15, 2, 5, 8, 11, 14, 1, 4.

USE Pharmacy;
GO

-- Запит 1 (№ 9). Імена всіх індексів
SELECT OBJECT_NAME(i.object_id) AS table_name,
       i.name AS index_name,
       i.type_desc,
       i.is_unique,
       i.is_primary_key
FROM sys.indexes AS i
JOIN sys.objects AS o ON o.object_id = i.object_id
WHERE o.is_ms_shipped = 0
  AND o.type = 'U'
  AND i.name IS NOT NULL      -- у купи index_id = 0 і name = NULL
ORDER BY table_name, i.index_id;
GO

-- Запит 2 (№ 12). Усі зовнішні ключі
SELECT fk.name AS fk_name,
       OBJECT_NAME(fk.parent_object_id) AS child_table,
       COL_NAME(fkc.parent_object_id,
                fkc.parent_column_id) AS child_column,
       OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       COL_NAME(fkc.referenced_object_id,
                fkc.referenced_column_id) AS parent_column
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
     ON fkc.constraint_object_id = fk.object_id
ORDER BY child_table, fk.name;
GO

-- Запит 3 (№ 15). Таблиці, що мають тільки батьківські таблиці
SELECT o.name AS table_name
FROM sys.objects AS o
WHERE o.type = 'U'
  AND o.is_ms_shipped = 0
  AND EXISTS (SELECT 1 FROM sys.foreign_keys AS f
              WHERE f.parent_object_id = o.object_id)
  AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys AS f
                  WHERE f.referenced_object_id = o.object_id)
ORDER BY table_name;
GO

-- Запит 4 (№ 2). Імена всіх збережених процедур
SELECT o.name AS procedure_name,
       o.create_date,
       o.modify_date
FROM sys.objects AS o
WHERE o.type = 'P'
  AND o.is_ms_shipped = 0
ORDER BY o.name;
GO

-- Запит 5 (№ 5). Імена всіх обмежень
SELECT o.name AS constraint_name,
       o.type_desc,
       OBJECT_NAME(o.parent_object_id) AS table_name
FROM sys.objects AS o
WHERE o.type IN ('PK', 'UQ', 'F', 'C', 'D')
  AND o.is_ms_shipped = 0
ORDER BY table_name, o.type_desc, o.name;
GO

-- Запит 6 (№ 8). Імена всіх куп
SELECT OBJECT_NAME(i.object_id) AS heap_table
FROM sys.indexes AS i
JOIN sys.objects AS o ON o.object_id = i.object_id
WHERE i.index_id = 0          -- 0 = купа
  AND o.type = 'U'
  AND o.is_ms_shipped = 0
ORDER BY heap_table;
GO

-- Запит 7 (№ 11). Стовпці з властивістю IDENTITY
SELECT OBJECT_NAME(ic.object_id) AS table_name,
       ic.name AS column_name,
       ic.seed_value,
       ic.increment_value,
       ic.last_value
FROM sys.identity_columns AS ic
JOIN sys.objects AS o ON o.object_id = ic.object_id
WHERE o.is_ms_shipped = 0
ORDER BY table_name;
GO

-- Запит 8 (№ 14). Залежні таблиці
SELECT o.name AS table_name,
       CASE WHEN EXISTS (SELECT 1 FROM sys.foreign_keys AS f
                         WHERE f.referenced_object_id = o.object_id)
            THEN 'yes' ELSE 'no' END AS is_parent,
       CASE WHEN EXISTS (SELECT 1 FROM sys.foreign_keys AS f
                         WHERE f.parent_object_id = o.object_id)
            THEN 'yes' ELSE 'no' END AS is_child
FROM sys.objects AS o
WHERE o.type = 'U'
  AND o.is_ms_shipped = 0
  AND (EXISTS (SELECT 1 FROM sys.foreign_keys AS f
               WHERE f.referenced_object_id = o.object_id)
    OR EXISTS (SELECT 1 FROM sys.foreign_keys AS f
               WHERE f.parent_object_id = o.object_id))
ORDER BY table_name;
GO

-- Запит 9 (№ 1). Імена всіх таблиць
SELECT SCHEMA_NAME(o.schema_id) AS schema_name,
       o.name AS table_name,
       o.create_date
FROM sys.objects AS o
WHERE o.type = 'U'
  AND o.is_ms_shipped = 0
ORDER BY table_name;
GO

-- Запит 10 (№ 4). Синоніми в усіх користувацьких БД
-- sys.synonyms є в кожній БД окремо, тому запит динамічний
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql
     + N'SELECT ' + QUOTENAME(d.name, '''') + N' AS db_name, '
     + N's.name AS synonym_name, s.base_object_name FROM '
     + QUOTENAME(d.name) + N'.sys.synonyms AS s UNION ALL '
FROM sys.databases AS d
WHERE d.database_id > 4       -- без master, tempdb, model, msdb
  AND d.state = 0;            -- лише доступні БД

SET @sql = LEFT(@sql, LEN(@sql) - 10)
         + N' ORDER BY db_name, synonym_name;';

EXEC sys.sp_executesql @sql;
GO
