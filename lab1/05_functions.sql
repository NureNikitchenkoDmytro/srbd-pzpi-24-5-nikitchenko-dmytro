IF OBJECT_ID(N'dbo.ufn_cheaper_than_avg', N'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_cheaper_than_avg;
GO

CREATE FUNCTION ufn_cheaper_than_avg ()
RETURNS INT
AS
BEGIN
    DECLARE @row_count INT;

    SET @row_count = (SELECT COUNT(*)
                        FROM stock
                       WHERE price < (SELECT AVG(price) FROM stock));

    RETURN @row_count;
END
GO

IF OBJECT_ID(N'dbo.ufn_count_cheaper_than', N'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_count_cheaper_than;
GO

CREATE FUNCTION ufn_count_cheaper_than (@max_price MONEY)
RETURNS INT
AS
BEGIN
    DECLARE @temp_count INT;

    SET @temp_count = (SELECT COUNT(*) FROM stock WHERE price < @max_price);

    RETURN @temp_count;
END
GO

IF OBJECT_ID(N'dbo.utf_pharmacy_assortment', N'IF') IS NOT NULL
    DROP FUNCTION dbo.utf_pharmacy_assortment;
GO

CREATE FUNCTION utf_pharmacy_assortment (@pharmacy_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT m.medicine_id,
           m.name,
           m.producer,
           s.price,
           s.quantity,
           s.price * s.quantity AS stock_value
      FROM stock AS s
      JOIN medicines AS m ON m.medicine_id = s.medicine_id
     WHERE s.pharmacy_id = @pharmacy_id
);
GO


-- перевірка
SELECT dbo.ufn_cheaper_than_avg() AS cheaper_than_avg;

SELECT dbo.ufn_count_cheaper_than(50.00)  AS cheaper_50,
       dbo.ufn_count_cheaper_than(120.00) AS cheaper_120;

SELECT * FROM dbo.utf_pharmacy_assortment(1) ORDER BY price DESC;
GO
