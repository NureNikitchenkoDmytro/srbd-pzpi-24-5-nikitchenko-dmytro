INSERT INTO pharmacies (name, address, city, info) VALUES
 (N'Аптека №1 «Центральна»',   N'Харківська обл., м. Харків, вул. Сумська, 12',      N'Харків',    N'Круглодобова'),
 (N'Аптека №2 «Слобожанська»', N'Харківська обл., м. Харків, просп. Науки, 45',      N'Харків',    NULL),
 (N'Аптека №3 «Здоров''я»',    N'Полтавська обл., м. Полтава, вул. Соборності, 8',   N'Полтава',   N'Є відділ рецептурних препаратів'),
 (N'Аптека №4 «Родинна»',      N'Київська обл., м. Бровари, вул. Київська, 210',     N'Бровари',   NULL),
 (N'Аптека №5 «Медсервіс»',    N'Полтавська обл., м. Кременчук, вул. Соборна, 3',    N'Кременчук', N'Пункт видачі замовлень');
GO

INSERT INTO employees (full_name, address, job_title, pharmacy_id) VALUES
 (N'Нікітченко Д. О.', N'Харківська обл., м. Харків, вул. Гагаріна, 5',          N'Manager',   1),
 (N'Ковальчук І. П.',  N'Харківська обл., м. Чугуїв, вул. Шевченка, 17',         N'Фармацевт', 1),
 (N'Литвин О. С.',     N'Харківська обл., м. Харків, вул. Полтавський Шлях, 60', N'Фармацевт', 2),
 (N'Гриценко М. В.',   N'Полтавська обл., м. Полтава, вул. Європейська, 21',     N'Manager',   3),
 (N'Савченко Т. А.',   N'Київська обл., м. Бровари, вул. Гагаріна, 9',           N'Фармацевт', 4),
 (N'Шевчук Н. І.',     N'Полтавська обл., м. Кременчук, вул. Лікарська, 2',      N'Провізор',  5);
GO

INSERT INTO medicines (name, producer, base_price, prescription_only) VALUES
 (N'Парацетамол 500 мг',   N'Дарниця',         42.50,  0),
 (N'Амоксицилін 250 мг',   N'Київмедпрепарат', 138.00, 1),
 (N'Аскорбінова кислота',  N'Здоров''я',       25.90,  0),
 (N'Ібупрофен 400 мг',     N'Дарниця',         96.40,  0),
 (N'Інсулін Хумодар',      N'Індар',           640.00, 1),
 (N'Фізіологічний розчин', N'Юрія-Фарм',       18.75,  0);
GO

INSERT INTO stock (pharmacy_id, medicine_id, price, quantity, note) VALUES
 (1, 1,  44.00, 120, NULL),
 (1, 2, 142.00,  30, NULL),
 (1, 3,  26.50, 200, NULL),
 (1, 4,  99.00,  75, NULL),
 (1, 5, 655.00,  10, NULL),
 (1, 6,  19.00, 300, NULL),
 (2, 1,  43.00,  90, NULL),
 (2, 4,  97.50,  40, NULL),
 (2, 6,  18.90, 150, NULL),
 (3, 2, 135.00,  25, NULL),
 (3, 5, 630.00,   6, NULL),
 (4, 3,  27.10, 110, NULL);
GO

INSERT INTO orders (pharmacy_id, employee_id, order_date, total_sum) VALUES
 (1, 2, '2026-09-01', 0),
 (1, 2, '2026-09-02', 0),
 (2, 3, '2026-09-02', 0),
 (3, 4, '2026-09-03', 0),
 (1, 1, '2026-09-04', 0);
GO

INSERT INTO order_items (order_id, medicine_id, quantity, unit_price) VALUES
 (1, 1, 2,  44.00),
 (1, 3, 1,  26.50),
 (2, 4, 3,  99.00),
 (3, 1, 5,  43.00),
 (3, 6, 2,  18.90),
 (4, 5, 1, 630.00),
 (5, 2, 1, 142.00);
GO

UPDATE o
   SET total_sum = ISNULL(t.s, 0)
  FROM orders AS o
  LEFT JOIN (SELECT order_id, SUM(quantity * unit_price) AS s
               FROM order_items GROUP BY order_id) AS t
    ON t.order_id = o.order_id;
GO

SELECT 'pharmacies' AS t, COUNT(*) AS cnt FROM pharmacies
UNION ALL SELECT 'employees',   COUNT(*) FROM employees
UNION ALL SELECT 'medicines',   COUNT(*) FROM medicines
UNION ALL SELECT 'stock',       COUNT(*) FROM stock
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
GO
