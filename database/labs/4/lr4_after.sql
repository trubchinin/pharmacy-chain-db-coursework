-- ЛР4: Запити ПІСЛЯ рефакторингу + побудова факту
USE pharmacy_chain;

-- 1) Побудувати факт за цільовий період (міняти дати за потреби)
CALL sp_build_sales_fact_daily('2025-09-01','2025-10-01');

-- 2) Q1': виручка по аптеках (швидко, з факту)
-- EXPLAIN ANALYZE
SELECT pharmacy_id, SUM(revenue) AS revenue, SUM(checks_cnt) AS checks_cnt
FROM SalesFactDaily
WHERE d >= '2025-09-01' AND d < '2025-10-01'
GROUP BY pharmacy_id
ORDER BY revenue DESC;

-- 3) Q3': Rx-продажі без JOIN до Product (денормалізовані колонки)
-- EXPLAIN ANALYZE
SELECT s.id AS sale_id, s.sold_at, c.full_name AS customer,
       si.product_id, si.product_name, si.qty, si.price
FROM Sale s
JOIN SaleItem si ON si.sale_id = s.id
LEFT JOIN Customer c ON c.id = s.customer_id
WHERE si.is_rx = 1
  AND si.prescription_id IS NOT NULL;

-- 4) Q2 (без змін) — виграє за рахунок індексів/партицій
-- EXPLAIN ANALYZE
SELECT ph.id AS pharmacy_id, ph.name,
       p.name AS product, b.lot_no, ps.qty, b.exp_date
FROM PharmacyStock ps
JOIN Batch b ON b.id = ps.batch_id
JOIN Product p ON p.id = b.product_id
JOIN Pharmacy ph ON ph.id = ps.pharmacy_id
WHERE b.exp_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY b.exp_date;
