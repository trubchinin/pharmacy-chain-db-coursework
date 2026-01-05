-- ЛР4: Рефакторинг БД (MySQL 8.0, InnoDB, utf8mb4)
-- Цільова схема: pharmacy_chain

USE pharmacy_chain;

-- =====================================================================
-- 0) БЕЗПЕКА ТА НАЛАШТУВАННЯ
-- =====================================================================
SET sql_safe_updates = 0;
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 1) ПЛАН РЕФАКТОРИНГУ (огляд)
--    1.1 Денормалізація «вниз» у SaleItem
--    1.2 Денормалізація «вгору» через агрегований факт (SalesFactDaily)
--    1.3 Індекси (складені/покривні)
--    1.4 Подання (VIEW) для звітності
--    1.5 Партиціювання: SaleItem(HASH), AuditLog(RANGE по даті)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1.1 ДЕНОРМАЛІЗАЦІЯ ВНИЗ (SaleItem знімає частину JOIN-ів)
-- ---------------------------------------------------------------------
-- Додаємо колонки, якщо їх немає (через INFORMATION_SCHEMA + динамічний SQL)
SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE SaleItem ADD COLUMN product_name VARCHAR(200) NULL AFTER product_id'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem' AND COLUMN_NAME='product_name'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE SaleItem ADD COLUMN atc_code VARCHAR(10) NULL AFTER product_name'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem' AND COLUMN_NAME='atc_code'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE SaleItem ADD COLUMN buy_price DECIMAL(12,2) NULL AFTER price'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem' AND COLUMN_NAME='buy_price'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE SaleItem ADD COLUMN is_rx TINYINT(1) NOT NULL DEFAULT 0 AFTER atc_code'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem' AND COLUMN_NAME='is_rx'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- CHECK додамо лише якщо його ще немає (без анонімного блоку)
SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE SaleItem ADD CONSTRAINT chk_saleitem_isrx CHECK (is_rx IN (0,1))'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'SaleItem'
    AND CONSTRAINT_TYPE = 'CHECK'
    AND CONSTRAINT_NAME = 'chk_saleitem_isrx'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Заповнення нових колонок для наявних рядків (бекфілл).
UPDATE SaleItem si
JOIN Product p ON p.id = si.product_id
JOIN Batch b ON b.id = si.batch_id
SET si.product_name = p.name,
    si.atc_code     = p.atc_code,
    si.is_rx        = IFNULL(p.is_rx, 0),
    si.buy_price    = b.buy_price
WHERE si.product_name IS NULL
   OR si.atc_code IS NULL
   OR si.buy_price IS NULL;

-- Тригери для підтримки денормалізованих полів (INSERT/UPDATE).
DELIMITER //
DROP TRIGGER IF EXISTS trg_saleitem_bi_fill_denorm//
CREATE TRIGGER trg_saleitem_bi_fill_denorm
BEFORE INSERT ON SaleItem
FOR EACH ROW
BEGIN
  DECLARE v_name VARCHAR(200);
  DECLARE v_atc VARCHAR(10);
  DECLARE v_isrx TINYINT(1);
  DECLARE v_buy DECIMAL(12,2);

  SELECT name, atc_code, is_rx INTO v_name, v_atc, v_isrx
  FROM Product WHERE id = NEW.product_id;

  SELECT buy_price INTO v_buy
  FROM Batch WHERE id = NEW.batch_id;

  SET NEW.product_name = v_name;
  SET NEW.atc_code     = v_atc;
  SET NEW.is_rx        = IFNULL(v_isrx, 0);
  SET NEW.buy_price    = v_buy;
END//

DROP TRIGGER IF EXISTS trg_saleitem_bu_fill_denorm//
CREATE TRIGGER trg_saleitem_bu_fill_denorm
BEFORE UPDATE ON SaleItem
FOR EACH ROW
BEGIN
  DECLARE v_name2 VARCHAR(200);
  DECLARE v_atc2 VARCHAR(10);
  DECLARE v_isrx2 TINYINT(1);
  DECLARE v_buy2 DECIMAL(12,2);

  IF NEW.product_id <> OLD.product_id THEN
    SELECT name, atc_code, is_rx
      INTO v_name2, v_atc2, v_isrx2
    FROM Product WHERE id = NEW.product_id;
    SET NEW.product_name = v_name2;
    SET NEW.atc_code     = v_atc2;
    SET NEW.is_rx        = IFNULL(v_isrx2, 0);
  END IF;

  IF NEW.batch_id <> OLD.batch_id THEN
    SELECT buy_price INTO v_buy2
    FROM Batch WHERE id = NEW.batch_id;
    SET NEW.buy_price = v_buy2;
  END IF;
END//
DELIMITER ;

-- ---------------------------------------------------------------------
-- 1.2 ДЕНОРМАЛІЗАЦІЯ ВГОРУ (добовий факт продажів)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SalesFactDaily (
  d DATE NOT NULL,
  pharmacy_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  qty BIGINT UNSIGNED NOT NULL,
  revenue DECIMAL(18,2) NOT NULL,
  checks_cnt BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (d, pharmacy_id, product_id),
  KEY idx_sfd_prod (product_id),
  KEY idx_sfd_pharm (pharmacy_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Процедура побудови факту за інтервал дат [d_from, d_to).
DELIMITER //
DROP PROCEDURE IF EXISTS sp_build_sales_fact_daily//
CREATE PROCEDURE sp_build_sales_fact_daily(IN d_from DATE, IN d_to DATE)
BEGIN
  INSERT INTO SalesFactDaily (d, pharmacy_id, product_id, qty, revenue, checks_cnt)
  SELECT DATE(s.sold_at) AS d, s.pharmacy_id, si.product_id,
         SUM(si.qty) AS qty,
         SUM(si.qty * si.price) AS revenue,
         COUNT(DISTINCT s.id) AS checks_cnt
  FROM Sale s
  JOIN SaleItem si ON si.sale_id = s.id
  WHERE s.sold_at >= d_from AND s.sold_at < d_to
  GROUP BY d, s.pharmacy_id, si.product_id
  ON DUPLICATE KEY UPDATE
    qty = VALUES(qty),
    revenue = VALUES(revenue),
    checks_cnt = VALUES(checks_cnt);
END//
DELIMITER ;

-- Опційно: щоденне оновлення за «вчора». Потребує права EVENT.
SET GLOBAL event_scheduler = ON;
CREATE EVENT IF NOT EXISTS ev_build_sales_fact_daily
ON SCHEDULE EVERY 1 DAY STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 1 HOUR)
DO
  CALL sp_build_sales_fact_daily(CURRENT_DATE - INTERVAL 1 DAY, CURRENT_DATE);

-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- УВАГА: виконуйте один раз; якщо індекс існує — видаляємо і створюємо наново.
-- Створюємо індекси, якщо їх ще немає (через INFORMATION_SCHEMA)
SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
    THEN 'CREATE INDEX idx_sale_pharmacy_soldat ON Sale (pharmacy_id, sold_at)'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='Sale' AND INDEX_NAME='idx_sale_pharmacy_soldat'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
    THEN 'CREATE INDEX idx_saleitem_product_sale ON SaleItem (product_id, sale_id)'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem' AND INDEX_NAME='idx_saleitem_product_sale'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
    THEN 'CREATE INDEX idx_batch_expdate ON Batch (exp_date)'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='Batch' AND INDEX_NAME='idx_batch_expdate'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
    THEN 'CREATE INDEX idx_batch_product_exp ON Batch (product_id, exp_date)'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='Batch' AND INDEX_NAME='idx_batch_product_exp'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
    THEN 'CREATE INDEX idx_audit_ts ON AuditLog (ts)'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='AuditLog' AND INDEX_NAME='idx_audit_ts'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------
-- 1.4 ПОДАННЯ (VIEW) для звітності
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_sales_top_products AS
SELECT d, product_id,
       SUM(revenue) AS revenue,
       SUM(qty) AS qty
FROM SalesFactDaily
GROUP BY d, product_id;

CREATE OR REPLACE VIEW v_sales_by_pharmacy AS
SELECT d, pharmacy_id,
       SUM(revenue) AS revenue,
       SUM(qty) AS qty,
       SUM(checks_cnt) AS checks_cnt
FROM SalesFactDaily
GROUP BY d, pharmacy_id;

-- ---------------------------------------------------------------------
-- 1.5 ПАРТИЦІЮВАННЯ
-- ---------------------------------------------------------------------
-- 1.5.1 SaleItem: хеш-партиціювання за sale_id (PK включає sale_id) — ОК.
-- УВАГА: запускати один раз; якщо таблиця вже партиційована — команда впаде.
-- Якщо таблиця ще не партиційована — додаємо партиції
SET @sql := (
  SELECT CASE 
    WHEN (SELECT COUNT(*) FROM INFORMATION_SCHEMA.PARTITIONS 
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem' AND PARTITION_NAME IS NOT NULL) = 0
     AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
           WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME='SaleItem') = 0
    THEN 'ALTER TABLE SaleItem PARTITION BY HASH (sale_id) PARTITIONS 16'
    ELSE 'SELECT 1' END
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 1.5.2 AuditLog: діапазон по даті через «стейдж + своп».
-- Підготуємо копію з PK(id, ts), створимо RANGE-партиції, перенесемо дані.
DROP TABLE IF EXISTS AuditLog_old;
CREATE TABLE IF NOT EXISTS AuditLog_part LIKE AuditLog;

-- DROP FK у копії (MySQL не підтримує FK у партиційованих таблицях)
SET @sql := (
  SELECT CASE WHEN COUNT(*)>0
    THEN 'ALTER TABLE AuditLog_part DROP FOREIGN KEY fk_audit_employee'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME='AuditLog_part' AND CONSTRAINT_NAME='fk_audit_employee'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)>0
    THEN 'ALTER TABLE AuditLog_part DROP FOREIGN KEY fk_audit_product'
    ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME='AuditLog_part' AND CONSTRAINT_NAME='fk_audit_product'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

ALTER TABLE AuditLog_part
  DROP PRIMARY KEY,
  ADD PRIMARY KEY (id, ts);

ALTER TABLE AuditLog_part
  PARTITION BY RANGE (TO_DAYS(ts)) (
    PARTITION p2024q4 VALUES LESS THAN (TO_DAYS('2025-01-01')),
    PARTITION p2025q1 VALUES LESS THAN (TO_DAYS('2025-04-01')),
    PARTITION p2025q2 VALUES LESS THAN (TO_DAYS('2025-07-01')),
    PARTITION p2025q3 VALUES LESS THAN (TO_DAYS('2025-10-01')),
    PARTITION p2025q4 VALUES LESS THAN (TO_DAYS('2026-01-01')),
    PARTITION pmax   VALUES LESS THAN MAXVALUE
  );

INSERT INTO AuditLog_part (id, employee_id, product_id, action, ts, details)
SELECT id, employee_id, product_id, action, ts, details FROM AuditLog;

RENAME TABLE AuditLog TO AuditLog_old, AuditLog_part TO AuditLog;
-- Після перевірки можна прибрати копію:
-- DROP TABLE AuditLog_old;

-- =====================================================================
-- 2) ШАБЛОНИ ЗАПИТІВ ПІСЛЯ РЕФАКТОРИНГУ (для вимірювання)
-- =====================================================================
-- Q1' (швидко): виручка по аптеках з факту
-- EXPLAIN ANALYZE
SELECT pharmacy_id, SUM(revenue) AS revenue, SUM(checks_cnt) AS checks_cnt
FROM SalesFactDaily
WHERE d >= '2025-09-01' AND d < '2025-10-01'
GROUP BY pharmacy_id
ORDER BY revenue DESC;

-- Q3' (швидко): Rx-продажі без JOIN до Product (викор. SaleItem.is_rx/product_name)
-- EXPLAIN ANALYZE
SELECT s.id AS sale_id, s.sold_at, c.full_name AS customer,
       si.product_id, si.product_name, si.qty, si.price
FROM Sale s
JOIN SaleItem si ON si.sale_id = s.id
LEFT JOIN Customer c ON c.id = s.customer_id
WHERE si.is_rx = 1
  AND si.prescription_id IS NOT NULL;

-- Q2' не змінюємо (використає нові індекси на Batch та партиції там, де доречно).
