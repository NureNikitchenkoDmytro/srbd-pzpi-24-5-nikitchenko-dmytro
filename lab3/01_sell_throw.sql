-- ЛР3. Процедура продажу для застосунку: замість PRINT
-- генерує виключення THROW, щоб їх обробив клієнт.

USE Pharmacy;
GO

CREATE OR ALTER PROCEDURE usp_sell_medicine
    @pharmacy_id INT,
    @employee_id INT,
    @medicine_id INT,
    @quantity    INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @price MONEY, @rest INT, @order_id INT;

    IF @quantity <= 0
        THROW 50002, N'Кількість має бути більше нуля', 1;

    SELECT @price = price, @rest = quantity
      FROM stock
     WHERE pharmacy_id = @pharmacy_id AND medicine_id = @medicine_id;

    IF @price IS NULL
        THROW 50003, N'Препарату немає в цій аптеці', 1;

    IF @rest < @quantity
        THROW 50004, N'Недостатньо препарату на складі', 1;

    IF NOT EXISTS (SELECT 1 FROM employees
                    WHERE employee_id = @employee_id
                      AND pharmacy_id = @pharmacy_id)
        THROW 50005, N'Працівник не з цієї аптеки', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO orders (pharmacy_id, employee_id, order_date,
                            total_sum)
        VALUES (@pharmacy_id, @employee_id, CAST(GETDATE() AS DATE),
                @price * @quantity);
        SET @order_id = SCOPE_IDENTITY();

        INSERT INTO order_items (order_id, medicine_id, quantity,
                                 unit_price)
        VALUES (@order_id, @medicine_id, @quantity, @price);

        UPDATE stock
           SET quantity = quantity - @quantity
         WHERE pharmacy_id = @pharmacy_id
           AND medicine_id = @medicine_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;   -- далі до клієнта (зокрема помилка тригера ЛР2)
    END CATCH

    SELECT @order_id AS order_id;
END
GO

-- перевірка
EXEC usp_sell_medicine @pharmacy_id = 1, @employee_id = 2,
                       @medicine_id = 3, @quantity = 1;
GO
EXEC usp_sell_medicine @pharmacy_id = 1, @employee_id = 2,
                       @medicine_id = 5, @quantity = 1000;
GO
