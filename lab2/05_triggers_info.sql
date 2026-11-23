-- ЛР2. Перегляд тригерів поточної БД.

USE Pharmacy;
GO

SELECT s2.name AS table_name,
       s1.name AS trigger_name,
       CASE
           WHEN s2.deltrig = s1.id THEN 'Delete'
           WHEN s2.instrig = s1.id THEN 'Insert'
           WHEN s2.updtrig = s1.id THEN 'Update'
       END AS trigger_type
  FROM sysobjects AS s1
  JOIN sysobjects AS s2 ON s1.parent_obj = s2.id
 WHERE s1.xtype = 'TR';
GO
