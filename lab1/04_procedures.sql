IF OBJECT_ID(N'dbo.usp_add_pharmacy', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_add_pharmacy;
GO

CREATE PROCEDURE usp_add_pharmacy
    @name    NVARCHAR(40),
    @address NVARCHAR(80),
    @city    NVARCHAR(30),
    @info    NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM pharmacies WHERE name = @name)
    BEGIN
        PRINT N'Аптека з назвою «' + @name + N'» вже існує';
        RETURN;
    END

    INSERT INTO pharmacies (name, address, city, info)
    VALUES (@name, @address, @city, @info);

    PRINT N'Додано аптеку #' + LTRIM(CAST(SCOPE_IDENTITY() AS VARCHAR(10)));
END
GO

IF OBJECT_ID(N'dbo.usp_sell_medicine', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_sell_medicine;
GO

CREATE PROCEDURE usp_sell_medicine
    @pharmacy_id INT,
    @employee_id INT,
    @medicine_id INT,
    @quantity    INT = 1,
    @order_id    INT = NULL   -- NULL - створити новий чек
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM medicines WHERE medicine_id = @medicine_id)
    BEGIN
        PRINT N'Препарат з кодом #' + LTRIM(CAST(@medicine_id AS VARCHAR(10)))
              + N' не існує';
        RETURN;
    END

    IF @quantity <= 0
    BEGIN
        PRINT N'Кількість проданого має бути додатною';
        RETURN;
    END

    DECLARE @price MONEY, @rest INT;
    SELECT @price = price, @rest = quantity
      FROM stock
     WHERE pharmacy_id = @pharmacy_id AND medicine_id = @medicine_id;

    IF @price IS NULL
    BEGIN
        PRINT N'Препарат #' + LTRIM(CAST(@medicine_id AS VARCHAR(10)))
              + N' відсутній в асортименті аптеки #'
              + LTRIM(CAST(@pharmacy_id AS VARCHAR(10)));
        RETURN;
    END

    IF @rest < @quantity
    BEGIN
        PRINT N'Недостатньо залишку: наявно ' + LTRIM(CAST(@rest AS VARCHAR(10)))
              + N', потрібно ' + LTRIM(CAST(@quantity AS VARCHAR(10)));
        RETURN;
    END

    IF @order_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM orders
                        WHERE order_id = @order_id AND pharmacy_id = @pharmacy_id)
    BEGIN
        PRINT N'Чек #' + LTRIM(CAST(@order_id AS VARCHAR(10)))
              + N' не знайдено в цій аптеці';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @order_id IS NULL
        BEGIN
            INSERT INTO orders (pharmacy_id, employee_id, order_date, total_sum)
            VALUES (@pharmacy_id, @employee_id, CAST(GETDATE() AS DATE), 0);

            SET @order_id = CAST(SCOPE_IDENTITY() AS INT);
            PRINT N'Створено новий чек #' + LTRIM(CAST(@order_id AS VARCHAR(10)));
        END

        IF EXISTS (SELECT 1 FROM order_items
                    WHERE order_id = @order_id AND medicine_id = @medicine_id)
            UPDATE order_items
               SET quantity = quantity + @quantity
             WHERE order_id = @order_id AND medicine_id = @medicine_id;
        ELSE
            INSERT INTO order_items (order_id, medicine_id, quantity, unit_price)
            VALUES (@order_id, @medicine_id, @quantity, @price);

        UPDATE stock
           SET quantity = quantity - @quantity
         WHERE pharmacy_id = @pharmacy_id AND medicine_id = @medicine_id;

        UPDATE o
           SET total_sum = (SELECT SUM(oi.quantity * oi.unit_price)
                              FROM order_items AS oi
                             WHERE oi.order_id = o.order_id)
          FROM orders AS o
         WHERE o.order_id = @order_id;

        COMMIT TRANSACTION;

        PRINT N'Продаж оформлено: чек #' + LTRIM(CAST(@order_id AS VARCHAR(10)))
              + N', препарат #' + LTRIM(CAST(@medicine_id AS VARCHAR(10)))
              + N', кількість ' + LTRIM(CAST(@quantity AS VARCHAR(10)));
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        PRINT N'Помилка оформлення продажу: ' + ERROR_MESSAGE();
    END CATCH
END
GO


-- перевірка
EXEC usp_add_pharmacy
     @name    = N'Аптека №6 «Нова»',
     @address = N'Харківська обл., м. Ізюм, вул. Соборна, 14',
     @city    = N'Ізюм';
GO
EXEC usp_add_pharmacy N'Аптека №6 «Нова»', N'Харківська обл., м. Ізюм, вул. Соборна, 14', N'Ізюм';
GO

EXEC usp_sell_medicine @pharmacy_id = 1, @employee_id = 2, @medicine_id = 1, @quantity = 3;
EXEC usp_sell_medicine @pharmacy_id = 1, @employee_id = 2, @medicine_id = 1,
                       @quantity = 2, @order_id = 1;
EXEC usp_sell_medicine @pharmacy_id = 1, @employee_id = 2, @medicine_id = 999, @quantity = 1;
EXEC usp_sell_medicine @pharmacy_id = 4, @employee_id = 5, @medicine_id = 5, @quantity = 1;
EXEC usp_sell_medicine @pharmacy_id = 3, @employee_id = 4, @medicine_id = 5, @quantity = 100;
GO

SELECT o.order_id, o.order_date, o.total_sum, m.name, oi.quantity, oi.unit_price
  FROM orders AS o
  JOIN order_items AS oi ON oi.order_id = o.order_id
  JOIN medicines   AS m  ON m.medicine_id = oi.medicine_id
 ORDER BY o.order_id;
GO
