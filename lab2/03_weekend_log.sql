-- ЛР2. Той самий тригер із логуванням спроб у вихідні.

USE Pharmacy;
GO

IF OBJECT_ID(N'dbo.medicine_attempts', N'U') IS NOT NULL
    DROP TABLE dbo.medicine_attempts;
GO

CREATE TABLE medicine_attempts (
    attempt_id   INT          IDENTITY(1,1) NOT NULL,
    attempt_date DATETIME     NOT NULL,
    login_name   NVARCHAR(50) NOT NULL,
    medicine     NVARCHAR(50) NOT NULL,
    CONSTRAINT pk_medicine_attempts PRIMARY KEY (attempt_id)
);
GO

CREATE OR ALTER TRIGGER trg_medicines_weekend
ON medicines
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF DATEPART(dw, GETDATE()) IN (1, 7)
    BEGIN
        INSERT INTO medicine_attempts (attempt_date, login_name,
                                       medicine)
        SELECT GETDATE(), SUSER_SNAME(), name
          FROM inserted;
        RAISERROR (N'Не можна додавати препарати у вихідні', 16, 1);
    END
    ELSE
        INSERT INTO medicines (name, producer, base_price,
                               prescription_only)
        SELECT name, producer, base_price, prescription_only
          FROM inserted;
END
GO

-- імітація суботи: з DATEFIRST 6 п'ятниця має номер 7
SET DATEFIRST 6;
INSERT INTO medicines (name, producer, base_price, prescription_only)
VALUES (N'Валідол', N'Здоров''я', 12.80, 0);
SET DATEFIRST 7;
GO

SELECT * FROM medicine_attempts;
SELECT COUNT(*) AS validol_rows
  FROM medicines
 WHERE name = N'Валідол';
GO
