-- ПЗ2. Видалення всіх індексів.

USE TestDB;
GO

DROP INDEX IF EXISTS ix_goods_quantity   ON Goods;
DROP INDEX IF EXISTS ix_goods_date_price ON Goods;
DROP INDEX IF EXISTS ix_goods_date_qty   ON Goods;
DROP INDEX IF EXISTS cix_goods_id        ON Goods;
GO
