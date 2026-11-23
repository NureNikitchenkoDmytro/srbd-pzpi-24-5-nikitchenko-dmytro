-- ПЗ2. Індекси для запитів варіанта.

USE TestDB;
GO

-- для запиту 1
CREATE NONCLUSTERED INDEX ix_goods_quantity
    ON Goods (Quantity)
    INCLUDE (Id, Label);
GO

-- для запиту 2
CREATE NONCLUSTERED INDEX ix_goods_date_price
    ON Goods (InputDate, Price)
    INCLUDE (Id, Label);
GO

-- для запиту 3
CREATE NONCLUSTERED INDEX ix_goods_date_qty
    ON Goods (InputDate)
    INCLUDE (Quantity);
GO

-- кластеризований по Id
CREATE UNIQUE CLUSTERED INDEX cix_goods_id
    ON Goods (Id);
GO
