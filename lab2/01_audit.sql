-- ЛР2. Аудит змін чеків тригером AFTER UPDATE.

USE Pharmacy;
GO

IF OBJECT_ID(N'dbo.order_logs', N'U') IS NOT NULL
    DROP TABLE dbo.order_logs;
GO

CREATE TABLE order_logs (
    log_id      INT      IDENTITY(1,1) NOT NULL,
    order_id    INT      NOT NULL,
    modify_date DATETIME NOT NULL,
    CONSTRAINT pk_order_logs PRIMARY KEY (log_id)
);
GO

CREATE OR ALTER TRIGGER trg_orders_audit
ON orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- inserted може містити кілька рядків
    INSERT INTO order_logs (order_id, modify_date)
    SELECT order_id, GETDATE()
      FROM inserted;
END
GO

-- перевірка: перерахунок суми двох чеків
UPDATE orders
   SET total_sum = (SELECT SUM(quantity * unit_price)
                      FROM order_items AS oi
                     WHERE oi.order_id = orders.order_id)
 WHERE order_id IN (1, 2);
GO

SELECT * FROM order_logs;
GO
