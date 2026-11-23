-- ПЗ1. Підготовка об'єктів для запитів № 9, 8 і 4.
-- У схемі з ЛР1 немає купи, синоніма і вторинного індексу.

USE Pharmacy;
GO

-- купа: таблиця без кластеризованого індексу
IF OBJECT_ID(N'dbo.price_log', N'U') IS NOT NULL
    DROP TABLE dbo.price_log;
GO

CREATE TABLE price_log (
    log_id      INT IDENTITY(1,1) NOT NULL,
    medicine_id INT               NOT NULL,
    old_price   DECIMAL(10,2)     NULL,
    new_price   DECIMAL(10,2)     NULL,
    changed_at  DATETIME2         NOT NULL DEFAULT SYSDATETIME()
);
GO

-- синонім на таблицю препаратів
IF OBJECT_ID(N'dbo.syn_medicines', N'SN') IS NOT NULL
    DROP SYNONYM dbo.syn_medicines;
GO

CREATE SYNONYM syn_medicines FOR Pharmacy.dbo.medicines;
GO

-- некластеризований індекс за назвою препарату
IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = N'ix_medicines_name')
    DROP INDEX ix_medicines_name ON medicines;
GO

CREATE NONCLUSTERED INDEX ix_medicines_name
    ON medicines (name)
    INCLUDE (base_price);
GO
