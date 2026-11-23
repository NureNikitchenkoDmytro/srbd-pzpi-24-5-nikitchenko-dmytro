-- ЛР2. Заборона додавати препарати у вихідні (INSTEAD OF).

USE Pharmacy;
GO

CREATE OR ALTER TRIGGER trg_medicines_weekend
ON medicines
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- 7 - субота, 1 - неділя
    IF DATEPART(dw, GETDATE()) IN (1, 7)
        RAISERROR (N'Не можна додавати препарати у вихідні', 16, 1);
    ELSE
        INSERT INTO medicines (name, producer, base_price,
                               prescription_only)
        SELECT name, producer, base_price, prescription_only
          FROM inserted;
END
GO

-- перевірка в робочий день
INSERT INTO medicines (name, producer, base_price, prescription_only)
VALUES (N'Цитрамон', N'Дарниця', 15.20, 0);
GO

SELECT medicine_id, name, producer, base_price FROM medicines;
GO
