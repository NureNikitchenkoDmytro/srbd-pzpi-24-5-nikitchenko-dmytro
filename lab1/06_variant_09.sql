-- 9: для препаратів заданої аптеки, ціна яких належить до 25% найдорожчих,
-- у полі note записати «Дорогий товар», для 25% найдешевших - «Дешевий товар».
-- Діапазон цін ділиться на частини 25% / 50% / 25%.

IF OBJECT_ID(N'dbo.usp_mark_price_segments', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_mark_price_segments;
GO

CREATE PROCEDURE usp_mark_price_segments
    @pharmacy_id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM pharmacies WHERE pharmacy_id = @pharmacy_id)
    BEGIN
        PRINT N'Аптеки з кодом #' + LTRIM(CAST(@pharmacy_id AS VARCHAR(10)))
              + N' не існує';
        RETURN;
    END

    DECLARE @min_price MONEY, @max_price MONEY;
    SELECT @min_price = MIN(price), @max_price = MAX(price)
      FROM stock
     WHERE pharmacy_id = @pharmacy_id;

    IF @min_price IS NULL
    BEGIN
        PRINT N'Асортимент аптеки #' + LTRIM(CAST(@pharmacy_id AS VARCHAR(10)))
              + N' порожній';
        RETURN;
    END

    IF @min_price = @max_price
    BEGIN
        PRINT N'Усі препарати аптеки мають однакову ціну - поділ на групи неможливий';
        RETURN;
    END

    DECLARE @low_bound  MONEY = @min_price + (@max_price - @min_price) * 0.25,
            @high_bound MONEY = @max_price - (@max_price - @min_price) * 0.25;

    UPDATE stock
       SET note = CASE
                     WHEN price <= @low_bound  THEN N'Дешевий товар'
                     WHEN price >= @high_bound THEN N'Дорогий товар'
                     ELSE NULL
                  END
     WHERE pharmacy_id = @pharmacy_id;

    PRINT N'Оброблено позицій: ' + LTRIM(CAST(@@ROWCOUNT AS VARCHAR(10)))
          + N'; діапазон цін ' + LTRIM(CAST(CAST(@min_price AS DECIMAL(10,2)) AS VARCHAR(20)))
          + N' - '             + LTRIM(CAST(CAST(@max_price AS DECIMAL(10,2)) AS VARCHAR(20)))
          + N'; межі ' + LTRIM(CAST(CAST(@low_bound  AS DECIMAL(10,2)) AS VARCHAR(20)))
          + N' та '    + LTRIM(CAST(CAST(@high_bound AS DECIMAL(10,2)) AS VARCHAR(20)));

    SELECT m.name, s.price, s.note
      FROM stock AS s
      JOIN medicines AS m ON m.medicine_id = s.medicine_id
     WHERE s.pharmacy_id = @pharmacy_id
     ORDER BY s.price;
END
GO


-- перевірка
SELECT m.name, s.price, s.note
  FROM stock AS s JOIN medicines AS m ON m.medicine_id = s.medicine_id
 WHERE s.pharmacy_id = 1 ORDER BY s.price;
GO

EXEC usp_mark_price_segments @pharmacy_id = 1;
EXEC usp_mark_price_segments @pharmacy_id = 4;
EXEC usp_mark_price_segments @pharmacy_id = 99;
GO
