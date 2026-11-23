-- ПЗ3. Кожен другий препарат, якого продано більше
-- заданої кількості одиниць (прокручуваний курсор).

USE Pharmacy;
GO

CREATE OR ALTER FUNCTION utf_every_second_sold (@min_quantity INT)
RETURNS @result TABLE (
    name          NVARCHAR(50),
    sale_quantity INT,
    producer      NVARCHAR(40)
)
AS
BEGIN
    DECLARE @idx INT = 1;
    DECLARE @name NVARCHAR(50), @qty INT, @producer NVARCHAR(40);

    DECLARE sold_cursor CURSOR LOCAL SCROLL STATIC READ_ONLY FOR
        SELECT m.name, SUM(oi.quantity), m.producer
          FROM medicines AS m
          JOIN order_items AS oi ON oi.medicine_id = m.medicine_id
         GROUP BY m.medicine_id, m.name, m.producer
        HAVING SUM(oi.quantity) > @min_quantity
         ORDER BY m.medicine_id;

    OPEN sold_cursor;
    FETCH ABSOLUTE @idx FROM sold_cursor INTO @name, @qty, @producer;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @result VALUES (@name, @qty, @producer);
        SET @idx = @idx + 2;
        FETCH ABSOLUTE @idx FROM sold_cursor
            INTO @name, @qty, @producer;
    END

    CLOSE sold_cursor;
    DEALLOCATE sold_cursor;
    RETURN;
END
GO

-- усі препарати, яких продано більше 1 одиниці
SELECT m.medicine_id, m.name, SUM(oi.quantity) AS sale_quantity
  FROM medicines AS m
  JOIN order_items AS oi ON oi.medicine_id = m.medicine_id
 GROUP BY m.medicine_id, m.name
HAVING SUM(oi.quantity) > 1
 ORDER BY m.medicine_id;

-- кожен другий з них
SELECT * FROM dbo.utf_every_second_sold(1);
GO
