-- ЛР5: Тести (MySQL 8.0) — запуск у SQLPro по кроках
USE pharmacy_chain;

-- Підготуємо факт за останні 30 днів, щоб були дані на актуальні дати
CALL sp_build_sales_fact_daily(CURRENT_DATE - INTERVAL 30 DAY, CURRENT_DATE + INTERVAL 1 DAY);
SET @d := (SELECT MAX(d) FROM SalesFactDaily);

-- 1) Перевірка функції знижки лояльності
SELECT fn_apply_loyalty_discount(100.00, (SELECT id FROM Customer LIMIT 1)) AS discounted;

-- 2) Перевірка процедури створення продажу
SET @items = JSON_ARRAY(
  JSON_OBJECT('product_id', (SELECT id FROM Product WHERE name='Paracetamol 500 mg Tablet'),
              'batch_id',   (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Paracetamol 500 mg Tablet' ORDER BY exp_date LIMIT 1),
              'qty', 1, 'price', 10.00),
  JSON_OBJECT('product_id', (SELECT id FROM Product WHERE name='Ibuprofen 200 mg Tablet'),
              'batch_id',   (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Ibuprofen 200 mg Tablet' ORDER BY exp_date LIMIT 1),
              'qty', 2, 'price', 8.00)
);
CALL sp_create_sale(
  (SELECT id FROM Pharmacy LIMIT 1),
  (SELECT id FROM Employee LIMIT 1),
  (SELECT id FROM Customer LIMIT 1),
  @items
);

-- 3) Аудит після додавання позицій — має з'явитися запис 'sell'
SELECT action, ts, details
FROM AuditLog
ORDER BY id DESC
LIMIT 5;

-- 4) Процедура застосування поставки
-- (якщо є Delivery/DeliveryItem) — оновлює або додає рядки у PharmacyStock
SELECT id FROM Delivery ORDER BY id DESC LIMIT 1 INTO @last_delivery_id;
DO @last_delivery_id; -- для перегляду значення
CALL sp_apply_delivery(@last_delivery_id);

-- 5) Аналітичні запити (приклади з ЛР5)
EXPLAIN ANALYZE
SELECT d, p.name AS product, SUM(sfd.revenue) AS revenue, SUM(sfd.qty) AS qty
FROM SalesFactDaily sfd
JOIN Product p ON p.id = sfd.product_id
WHERE d = @d
GROUP BY d, p.name
ORDER BY revenue DESC
LIMIT 10;
