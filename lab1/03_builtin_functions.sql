-- рядкові функції
SELECT UPPER(name)      AS name_upper,
       LEN(name)        AS name_length,
       LEFT(producer, 3) AS producer_code
  FROM medicines;
GO

-- перетворення типів
SELECT CONVERT(CHAR(10), GETDATE(), 104) AS date_de,
       CONVERT(CHAR(10), GETDATE(), 101) AS date_us,
       CAST(640.00 AS VARCHAR(20))       AS price_text,
       TRY_CONVERT(INT, N'12a')          AS bad_value;
GO

-- агрегатні функції
SELECT COUNT(*)      AS positions,
       AVG(price)    AS avg_price,
       MIN(price)    AS min_price,
       MAX(price)    AS max_price,
       SUM(quantity) AS total_quantity
  FROM stock;
GO

-- системні функції
SELECT DB_NAME()   AS current_db,
       USER_NAME() AS current_user_name,
       DATEDIFF(DAY, '2026-09-01', GETDATE()) AS days_from_start;
GO
