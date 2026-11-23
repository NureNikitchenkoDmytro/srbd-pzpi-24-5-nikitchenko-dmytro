-- ПЗ3. Варіант 4: знизити ціну на заданий відсоток (1..50)
-- для препаратів, проданих на суму більше заданої.

USE Pharmacy;
GO

CREATE OR ALTER PROCEDURE usp_discount_best_sellers
    @percent INT,
    @min_sum MONEY
AS
BEGIN
    SET NOCOUNT ON;

    IF @percent NOT BETWEEN 1 AND 50
        THROW 50010, N'Відсоток має бути від 1 до 50', 1;

    DECLARE @result TABLE (
        name      NVARCHAR(50),
        old_price MONEY,
        new_price MONEY,
        total_qty INT
    );
    DECLARE @id INT, @name NVARCHAR(50), @price MONEY, @qty INT;

    DECLARE price_cursor CURSOR LOCAL STATIC FOR
        SELECT m.medicine_id, m.name, m.base_price,
               (SELECT ISNULL(SUM(s.quantity), 0)
                  FROM stock AS s
                 WHERE s.medicine_id = m.medicine_id)
          FROM medicines AS m
         WHERE (SELECT SUM(oi.quantity * oi.unit_price)
                  FROM order_items AS oi
                 WHERE oi.medicine_id = m.medicine_id) > @min_sum;

    OPEN price_cursor;
    FETCH NEXT FROM price_cursor INTO @id, @name, @price, @qty;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE medicines
           SET base_price = ROUND(@price * (100 - @percent) / 100, 2)
         WHERE medicine_id = @id;

        INSERT INTO @result
        SELECT @name, @price, base_price, @qty
          FROM medicines
         WHERE medicine_id = @id;

        FETCH NEXT FROM price_cursor INTO @id, @name, @price, @qty;
    END

    CLOSE price_cursor;
    DEALLOCATE price_cursor;

    SELECT * FROM @result;
END
GO

-- перевірка
EXEC usp_discount_best_sellers @percent = 10, @min_sum = 250;
GO

-- відсоток поза діапазоном - помилка
EXEC usp_discount_best_sellers @percent = 70, @min_sum = 250;
GO
