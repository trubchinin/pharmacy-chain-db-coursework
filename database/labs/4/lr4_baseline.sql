-- ЛР4: Базові запити ДО рефакторингу (для вимірювань)
USE pharmacy_chain;

-- Q1: виручка по аптеках у діапазоні дат
-- EXPLAIN ANALYZE
SELECT ph.id AS pharmacy_id, ph.name AS pharmacy_name,
       SUM(si.qty * si.price) AS revenue, COUNT(DISTINCT s.id) AS checks_cnt
FROM Sale s
JOIN Pharmacy ph ON ph.id = s.pharmacy_id
JOIN SaleItem si ON si.sale_id = s.id
WHERE s.sold_at >= '2025-09-01' AND s.sold_at < '2025-10-01'
GROUP BY ph.id, ph.name
ORDER BY revenue DESC;

-- Q2: партії з терміном ≤30 днів
-- EXPLAIN ANALYZE
SELECT ph.id AS pharmacy_id, ph.name,
       p.name AS product, b.lot_no, ps.qty, b.exp_date
FROM PharmacyStock ps
JOIN Batch b ON b.id = ps.batch_id
JOIN Product p ON p.id = b.product_id
JOIN Pharmacy ph ON ph.id = ps.pharmacy_id
WHERE b.exp_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY b.exp_date;

-- Q3: Rx-продажі з прив'язкою до рецепта
-- EXPLAIN ANALYZE
SELECT s.id AS sale_id, s.sold_at, c.full_name AS customer,
       si.product_id, p.name AS product_name, si.qty, si.price
FROM Sale s
JOIN SaleItem si ON si.sale_id = s.id
JOIN Product p ON p.id = si.product_id
LEFT JOIN Customer c ON c.id = s.customer_id
WHERE p.is_rx = 1
  AND si.prescription_id IS NOT NULL;
