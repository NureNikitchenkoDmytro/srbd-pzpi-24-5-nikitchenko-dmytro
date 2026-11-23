-- ЛР2. Варіант 3: заборонити продаж препарату,
-- якщо в нього вже більше 100 продажів.

USE Pharmacy;
GO

-- тестові дані: 101 продаж фізрозчину (id 6) в аптеці №2
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM order_items WHERE medicine_id = 6) <= 100
BEGIN
    DECLARE @i INT = 1;
    WHILE @i <= 101
    BEGIN
        INSERT INTO orders (pharmacy_id, employee_id, order_date,
                            total_sum)
        VALUES (2, 3, DATEADD(DAY, -@i, '2026-10-01'), 18.90);

        INSERT INTO order_items (order_id, medicine_id, quantity,
                                 unit_price)
        VALUES (SCOPE_IDENTITY(), 6, 1, 18.90);

        SET @i = @i + 1;
    END
END
GO

CREATE OR ALTER TRIGGER trg_order_items_limit
ON order_items
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @names NVARCHAR(400), @msg NVARCHAR(500);

    -- продажі до цієї вставки, без нових рядків
    SELECT @names = STRING_AGG(m.name, N', ')
      FROM medicines AS m
     WHERE m.medicine_id IN (SELECT medicine_id FROM inserted)
       AND (SELECT COUNT(*)
              FROM order_items AS oi
             WHERE oi.medicine_id = m.medicine_id
               AND oi.order_item_id NOT IN
                   (SELECT order_item_id FROM inserted)) > 100;

    IF @names IS NOT NULL
    BEGIN
        SET @msg = N'Більше 100 продажів: ' + @names;
        THROW 50001, @msg, 1;
    END
END
GO

-- новий чек для перевірок
INSERT INTO orders (pharmacy_id, employee_id, order_date, total_sum)
VALUES (1, 2, CAST(GETDATE() AS DATE), 0);
GO

-- 1) фізрозчин - помилка
INSERT INTO order_items (order_id, medicine_id, quantity, unit_price)
SELECT MAX(order_id), 6, 1, 19.00 FROM orders;
GO

-- 2) кілька рядків з таблиці: препарати 1 і 4 - успішно
INSERT INTO order_items (order_id, medicine_id, quantity, unit_price)
SELECT (SELECT MAX(order_id) FROM orders), medicine_id, 1, base_price
  FROM medicines
 WHERE medicine_id IN (1, 4);
GO

-- 3) кілька рядків: препарати 3 і 6 - відхилено всю вставку
INSERT INTO order_items (order_id, medicine_id, quantity, unit_price)
SELECT (SELECT MAX(order_id) FROM orders), medicine_id, 1, base_price
  FROM medicines
 WHERE medicine_id IN (3, 6);
GO

SELECT oi.order_id, m.name, oi.quantity, oi.unit_price
  FROM order_items AS oi
  JOIN medicines AS m ON m.medicine_id = oi.medicine_id
 WHERE oi.order_id = (SELECT MAX(order_id) FROM orders);

SELECT m.name, COUNT(oi.order_item_id) AS sales
  FROM medicines AS m
  LEFT JOIN order_items AS oi ON oi.medicine_id = m.medicine_id
 GROUP BY m.name
 ORDER BY sales DESC;
GO
