-- ПЗ2. Створення тестової БД і таблиці Goods на 1 000 000 рядків.

IF DB_ID(N'TestDB') IS NOT NULL
BEGIN
    ALTER DATABASE TestDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TestDB;
END
GO

CREATE DATABASE TestDB;
GO

USE TestDB;
GO

CREATE TABLE Goods (
    Id           INT           NOT NULL,
    Label        NVARCHAR(100) NULL,
    Manufacturer NVARCHAR(50)  NULL,
    Price        FLOAT         NULL,
    Quantity     INT           NULL,
    InputDate    DATE          NULL
);
GO

-- Price 0..499, Quantity 1..1000, InputDate - останні 365 днів
WITH Numbers AS (
    SELECT TOP (1000000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
)
INSERT INTO Goods
    (Id, Label, Manufacturer, Price, Quantity, InputDate)
SELECT n,
       CONCAT(N'Product_', n),
       CONCAT(N'Manuf_', ABS(CHECKSUM(NEWID())) % 1000),
       CAST(ABS(CHECKSUM(NEWID())) % 500 AS DECIMAL(10,2)),
       ABS(CHECKSUM(NEWID())) % 1000 + 1,
       CONVERT(date, DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365,
                             GETDATE()))
FROM Numbers;
GO

-- скільки рядків повертає кожен із трьох запитів варіанта
SELECT COUNT(*)                                         AS rows_total,
       SUM(CASE WHEN Quantity < 100 THEN 1 ELSE 0 END)  AS q1_rows,
       SUM(CASE WHEN Price > 100.0
                 AND InputDate = CAST(GETDATE() AS date)
                THEN 1 ELSE 0 END)                      AS q2_rows,
       COUNT(DISTINCT InputDate)                        AS q3_groups
FROM Goods;
GO
