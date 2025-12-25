-- ЛР5: Збережені процедури та функції (MySQL 8.0) — схема pharmacy_chain
USE pharmacy_chain;

DELIMITER //

-- 1) Функція: розрахунок кінцевої ціни з урахуванням рівня лояльності
DROP FUNCTION IF EXISTS fn_apply_loyalty_discount//
CREATE FUNCTION fn_apply_loyalty_discount(base_amount DECIMAL(12,2), customer_id BIGINT UNSIGNED)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
  DECLARE v_pct DECIMAL(5,2) DEFAULT 0;
  IF customer_id IS NOT NULL THEN
    SELECT t.discount_pct INTO v_pct
    FROM Customer c
    JOIN LoyaltyCard lc ON lc.id = c.card_id
    JOIN LoyaltyTier t ON t.id = lc.tier_id
    WHERE c.id = customer_id;
  END IF;
  RETURN ROUND(base_amount * (1 - v_pct/100), 2);
END//

-- 2) Процедура: створити продаж з позиціями (спрощено)
-- Аргументи: аптекa, співробітник, клієнт (NULL), JSON-масив позицій [{product_id, batch_id, qty, price}]
DROP PROCEDURE IF EXISTS sp_create_sale//
CREATE PROCEDURE sp_create_sale(
  IN p_pharmacy_id BIGINT UNSIGNED,
  IN p_employee_id BIGINT UNSIGNED,
  IN p_customer_id BIGINT UNSIGNED,
  IN p_items_json JSON
)
BEGIN
  DECLARE v_sale_id BIGINT UNSIGNED;
  DECLARE v_total DECIMAL(12,2) DEFAULT 0;
  DECLARE v_idx INT DEFAULT 0;
  DECLARE v_cnt INT;

  SET v_cnt = JSON_LENGTH(p_items_json);

  INSERT INTO Sale (pharmacy_id, employee_id, customer_id, sold_at, total, discount_total, pay_method)
  VALUES (p_pharmacy_id, p_employee_id, p_customer_id, NOW(), 0, 0, 'card');
  SET v_sale_id = LAST_INSERT_ID();

  WHILE v_idx < v_cnt DO
    SET @pid  = JSON_EXTRACT(p_items_json, CONCAT('$[', v_idx, '].product_id'))+0;
    SET @bid  = JSON_EXTRACT(p_items_json, CONCAT('$[', v_idx, '].batch_id'))+0;
    SET @qty  = JSON_EXTRACT(p_items_json, CONCAT('$[', v_idx, '].qty'))+0;
    SET @price= JSON_EXTRACT(p_items_json, CONCAT('$[', v_idx, '].price'))+0.0;

    INSERT INTO SaleItem (sale_id, line_no, product_id, batch_id, qty, price)
    VALUES (v_sale_id, v_idx+1, @pid, @bid, @qty, @price);

    UPDATE PharmacyStock SET qty = qty - @qty
    WHERE pharmacy_id = p_pharmacy_id AND batch_id = @bid;

    SET v_total = v_total + (@qty * @price);
    SET v_idx = v_idx + 1;
  END WHILE;

  UPDATE Sale
  SET total = v_total,
      discount_total = ROUND(v_total - fn_apply_loyalty_discount(v_total, p_customer_id), 2)
  WHERE id = v_sale_id;

  SELECT v_sale_id AS sale_id;
END//

-- 3) Процедура: поповнення запасів з поставки (Delivery → PharmacyStock)
DROP PROCEDURE IF EXISTS sp_apply_delivery//
CREATE PROCEDURE sp_apply_delivery(IN p_delivery_id BIGINT UNSIGNED)
BEGIN
  INSERT INTO PharmacyStock (pharmacy_id, batch_id, qty)
  SELECT so.pharmacy_id, di.batch_id, di.qty_received
  FROM DeliveryItem di
  JOIN Delivery d  ON d.id = di.delivery_id
  JOIN SupplierOrder so ON so.id = d.supplier_order_id
  ON DUPLICATE KEY UPDATE qty = PharmacyStock.qty + VALUES(qty);
END//

DELIMITER ;
