-- ЛР5: Тригери (MySQL 8.0) — схема pharmacy_chain
USE pharmacy_chain;

DELIMITER //

-- 1) Заборона від’ємних залишків на складі
DROP TRIGGER IF EXISTS trg_pharmacystock_bu_nonneg//
CREATE TRIGGER trg_pharmacystock_bu_nonneg
BEFORE UPDATE ON PharmacyStock
FOR EACH ROW
BEGIN
  IF NEW.qty < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PharmacyStock.qty не може бути від’ємним';
  END IF;
END//

-- 2) Автоматичний аудит операцій продажу (INSERT у SaleItem)
DROP TRIGGER IF EXISTS trg_saleitem_ai_audit//
CREATE TRIGGER trg_saleitem_ai_audit
AFTER INSERT ON SaleItem
FOR EACH ROW
BEGIN
  INSERT INTO AuditLog (employee_id, product_id, action, ts, details)
  VALUES (
    (SELECT employee_id FROM Sale WHERE id = NEW.sale_id),
    NEW.product_id,
    'sell',
    NOW(),
    JSON_OBJECT('sale_id', NEW.sale_id, 'line_no', NEW.line_no)
  );
END//

-- 3) Контроль парності колонок рецепта (пара prescription_id / prescription_product_id)
-- (аналог з ЛР3; залишено задля повноти у ЛР5)
DROP TRIGGER IF EXISTS trg_saleitem_bi_prescription_pair_l5//
CREATE TRIGGER trg_saleitem_bi_prescription_pair_l5
BEFORE INSERT ON SaleItem
FOR EACH ROW
BEGIN
  IF ((NEW.prescription_id IS NULL) <> (NEW.prescription_product_id IS NULL)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SaleItem: обидві колонки рецепта мають бути одночасно NULL або NOT NULL';
  END IF;
END//

DROP TRIGGER IF EXISTS trg_saleitem_bu_prescription_pair_l5//
CREATE TRIGGER trg_saleitem_bu_prescription_pair_l5
BEFORE UPDATE ON SaleItem
FOR EACH ROW
BEGIN
  IF ((NEW.prescription_id IS NULL) <> (NEW.prescription_product_id IS NULL)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SaleItem: обидві колонки рецепта мають бути одночасно NULL або NOT NULL';
  END IF;
END//

DELIMITER ;
