-- ЛР5: Запити (MySQL 8.0) — схема pharmacy_chain
USE pharmacy_chain;

-- 1) Список продажів за період з деталями (для чека)
EXPLAIN ANALYZE
SELECT s.id AS sale_id, s.sold_at, ph.name AS pharmacy, e.full_name AS cashier,
       c.full_name AS customer, si.line_no, si.product_name, si.qty, si.price,
       (si.qty * si.price) AS line_total
FROM Sale s
JOIN Pharmacy ph ON ph.id = s.pharmacy_id
JOIN Employee e ON e.id = s.employee_id
LEFT JOIN Customer c ON c.id = s.customer_id
JOIN SaleItem si ON si.sale_id = s.id
WHERE s.sold_at >= '2025-09-01' AND s.sold_at < '2025-10-01'
ORDER BY s.id, si.line_no;

-- 2) Топ-товари за день (за виручкою)
EXPLAIN ANALYZE
SELECT d, p.name AS product, SUM(sfd.revenue) AS revenue, SUM(sfd.qty) AS qty
FROM SalesFactDaily sfd
JOIN Product p ON p.id = sfd.product_id
WHERE d = '2025-09-15'
GROUP BY d, p.name
ORDER BY revenue DESC
LIMIT 10;

-- 3) Запаси та партії, що закінчуються
EXPLAIN ANALYZE
SELECT ph.name AS pharmacy, p.name AS product, b.lot_no, ps.qty, b.exp_date
FROM Batch b
JOIN Product p ON p.id = b.product_id
JOIN PharmacyStock ps ON ps.batch_id = b.id
JOIN Pharmacy ph ON ph.id = ps.pharmacy_id
WHERE b.exp_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY b.exp_date;
