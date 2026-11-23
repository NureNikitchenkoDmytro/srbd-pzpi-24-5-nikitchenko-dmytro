-- ПЗ2. Запити варіанта 9: 1.5, 2.1, 3.2.

USE TestDB;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Запит 1 (1.5)
SELECT Id, Label, Quantity
FROM Goods
WHERE Quantity < 100;
GO

-- Запит 2 (2.1), GETDATE() повертає дату з часом, тому CAST до date
SELECT Id, Label
FROM Goods
WHERE Price > 100.0
  AND InputDate = CAST(GETDATE() AS date);
GO

-- Запит 3 (3.2)
SELECT InputDate, SUM(Quantity) AS 'Count'
FROM Goods
GROUP BY InputDate;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
