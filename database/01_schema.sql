-- Lab 3: Physical Data Model (MySQL 8.0, InnoDB, utf8mb4)
-- Schema: Pharmacy Chain (Variant #2)

SET NAMES utf8mb4;
SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET time_zone = '+00:00';

-- Recreate database to allow re-running the script safely
DROP DATABASE IF EXISTS pharmacy_chain;
CREATE DATABASE IF NOT EXISTS pharmacy_chain
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE pharmacy_chain;

-- -----------------------------------------------------
-- 1. Reference tables
-- -----------------------------------------------------

CREATE TABLE Region (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_region_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE City (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  region_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY fk_city_region (region_id),
  CONSTRAINT fk_city_region FOREIGN KEY (region_id) REFERENCES Region(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Pharmacy (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL,
  address VARCHAR(255) NOT NULL,
  city_id BIGINT UNSIGNED NOT NULL,
  license_no VARCHAR(64) NOT NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (id),
  UNIQUE KEY uq_pharmacy_license (license_no),
  KEY fk_pharmacy_city (city_id),
  CONSTRAINT fk_pharmacy_city FOREIGN KEY (city_id) REFERENCES City(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Role (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_role_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Employee (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pharmacy_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  hired_at DATE NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  KEY fk_employee_pharmacy (pharmacy_id),
  KEY fk_employee_role (role_id),
  CONSTRAINT fk_employee_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES Pharmacy(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_employee_role FOREIGN KEY (role_id) REFERENCES Role(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_employee_active CHECK (is_active IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Manufacturer (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  country VARCHAR(80) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_manufacturer_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE DosageForm (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dosageform_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Product (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(200) NOT NULL,
  atc_code VARCHAR(10) NULL,
  dosage_form_id BIGINT UNSIGNED NOT NULL,
  manufacturer_id BIGINT UNSIGNED NOT NULL,
  is_rx TINYINT(1) NOT NULL DEFAULT 0,
  is_controlled TINYINT(1) NOT NULL DEFAULT 0,
  strength VARCHAR(40) NULL,
  unit VARCHAR(16) NULL,
  pack_size INT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY fk_product_dosageform (dosage_form_id),
  KEY fk_product_manufacturer (manufacturer_id),
  KEY idx_product_atc (atc_code),
  CONSTRAINT fk_product_dosageform FOREIGN KEY (dosage_form_id) REFERENCES DosageForm(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_product_manufacturer FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_product_rx CHECK (is_rx IN (0,1)),
  CONSTRAINT chk_product_ctrl CHECK (is_controlled IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Supplier (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  tax_no VARCHAR(32) NOT NULL,
  phone VARCHAR(32) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_supplier_tax (tax_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Batch (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  lot_no VARCHAR(40) NOT NULL,
  mfg_date DATE NOT NULL,
  exp_date DATE NOT NULL,
  buy_price DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_batch_business (product_id, lot_no, mfg_date),
  KEY fk_batch_product (product_id),
  KEY fk_batch_supplier (supplier_id),
  CONSTRAINT fk_batch_product FOREIGN KEY (product_id) REFERENCES Product(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_batch_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_batch_dates CHECK (exp_date > mfg_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- 2. Loyalty & Customers
-- -----------------------------------------------------

CREATE TABLE LoyaltyTier (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(64) NOT NULL,
  discount_pct DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_loyaltytier_name (name),
  CONSTRAINT chk_loyalty_discount CHECK (discount_pct >= 0 AND discount_pct <= 50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE LoyaltyCard (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  number VARCHAR(32) NOT NULL,
  tier_id BIGINT UNSIGNED NOT NULL,
  points INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_loyaltycard_number (number),
  KEY fk_loyaltycard_tier (tier_id),
  CONSTRAINT fk_loyaltycard_tier FOREIGN KEY (tier_id) REFERENCES LoyaltyTier(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Customer (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(160) NOT NULL,
  phone VARCHAR(32) NULL,
  email VARCHAR(190) NULL,
  card_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customer_phone (phone),
  UNIQUE KEY uq_customer_email (email),
  KEY fk_customer_card (card_id),
  CONSTRAINT fk_customer_card FOREIGN KEY (card_id) REFERENCES LoyaltyCard(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- 3. Inventory in pharmacies
-- -----------------------------------------------------

CREATE TABLE PharmacyStock (
  pharmacy_id BIGINT UNSIGNED NOT NULL,
  batch_id BIGINT UNSIGNED NOT NULL,
  qty INT NOT NULL,
  PRIMARY KEY (pharmacy_id, batch_id),
  KEY fk_pharmacystock_batch (batch_id),
  CONSTRAINT fk_pharmacystock_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES Pharmacy(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pharmacystock_batch FOREIGN KEY (batch_id) REFERENCES Batch(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_stock_qty_nonneg CHECK (qty >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- 4. Prescriptions
-- -----------------------------------------------------

CREATE TABLE Prescription (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  doctor_name VARCHAR(160) NOT NULL,
  doctor_license VARCHAR(64) NOT NULL,
  issued_at DATE NOT NULL,
  valid_to DATE NOT NULL,
  PRIMARY KEY (id),
  KEY fk_prescription_customer (customer_id),
  CONSTRAINT fk_prescription_customer FOREIGN KEY (customer_id) REFERENCES Customer(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_prescr_dates CHECK (valid_to >= issued_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE PrescriptionItem (
  prescription_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  dosage VARCHAR(80) NULL,
  qty INT NOT NULL,
  repeats_left INT NOT NULL DEFAULT 0,
  PRIMARY KEY (prescription_id, product_id),
  KEY fk_prescitem_product (product_id),
  CONSTRAINT fk_prescitem_prescription FOREIGN KEY (prescription_id) REFERENCES Prescription(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_prescitem_product FOREIGN KEY (product_id) REFERENCES Product(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_prescitem_qty CHECK (qty > 0),
  CONSTRAINT chk_prescitem_repeats CHECK (repeats_left >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- 5. Sales and promotions
-- -----------------------------------------------------

CREATE TABLE Sale (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pharmacy_id BIGINT UNSIGNED NOT NULL,
  employee_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NULL,
  sold_at DATETIME NOT NULL,
  total DECIMAL(12,2) NOT NULL,
  discount_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  pay_method ENUM('cash','card','mixed') NOT NULL,
  PRIMARY KEY (id),
  KEY fk_sale_pharmacy (pharmacy_id),
  KEY fk_sale_employee (employee_id),
  KEY fk_sale_customer (customer_id),
  KEY idx_sale_soldat (sold_at),
  CONSTRAINT fk_sale_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES Pharmacy(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_sale_employee FOREIGN KEY (employee_id) REFERENCES Employee(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES Customer(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE SaleItem (
  sale_id BIGINT UNSIGNED NOT NULL,
  line_no INT NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  batch_id BIGINT UNSIGNED NOT NULL,
  qty INT NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  prescription_id BIGINT UNSIGNED NULL,
  prescription_product_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (sale_id, line_no),
  KEY fk_saleitem_product (product_id),
  KEY fk_saleitem_batch (batch_id),
  KEY fk_saleitem_prescr (prescription_id, prescription_product_id),
  CONSTRAINT fk_saleitem_sale FOREIGN KEY (sale_id) REFERENCES Sale(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_saleitem_product FOREIGN KEY (product_id) REFERENCES Product(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_saleitem_batch FOREIGN KEY (batch_id) REFERENCES Batch(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_saleitem_prescr FOREIGN KEY (prescription_id, prescription_product_id)
    REFERENCES PrescriptionItem(prescription_id, product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_saleitem_qty CHECK (qty > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Enforce pairwise NULL/not-NULL for prescription columns via triggers (MySQL 8.0 limitation on CHECK)
DELIMITER //
CREATE TRIGGER trg_saleitem_bi_prescription_pair
BEFORE INSERT ON SaleItem
FOR EACH ROW
BEGIN
  IF ((NEW.prescription_id IS NULL) <> (NEW.prescription_product_id IS NULL)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SaleItem: prescription pair must be both NULL or both NOT NULL';
  END IF;
END//

CREATE TRIGGER trg_saleitem_bu_prescription_pair
BEFORE UPDATE ON SaleItem
FOR EACH ROW
BEGIN
  IF ((NEW.prescription_id IS NULL) <> (NEW.prescription_product_id IS NULL)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SaleItem: prescription pair must be both NULL or both NOT NULL';
  END IF;
END//
DELIMITER ;

CREATE TABLE Promotion (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  rules JSON NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_promo_dates CHECK (end_at >= start_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE SalePromotion (
  sale_id BIGINT UNSIGNED NOT NULL,
  promotion_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (sale_id, promotion_id),
  KEY fk_salepromo_promo (promotion_id),
  CONSTRAINT fk_salepromo_sale FOREIGN KEY (sale_id) REFERENCES Sale(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_salepromo_promo FOREIGN KEY (promotion_id) REFERENCES Promotion(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- 6. Supplier orders and deliveries
-- -----------------------------------------------------

CREATE TABLE SupplierOrder (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pharmacy_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  ordered_at DATETIME NOT NULL,
  status ENUM('draft','sent','confirmed','received','closed') NOT NULL DEFAULT 'draft',
  PRIMARY KEY (id),
  KEY fk_supporder_pharmacy (pharmacy_id),
  KEY fk_supporder_supplier (supplier_id),
  CONSTRAINT fk_supporder_pharmacy FOREIGN KEY (pharmacy_id) REFERENCES Pharmacy(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_supporder_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE SupplierOrderItem (
  supplier_order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  qty INT NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (supplier_order_id, product_id),
  KEY fk_supporderitem_product (product_id),
  CONSTRAINT fk_supporderitem_order FOREIGN KEY (supplier_order_id) REFERENCES SupplierOrder(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_supporderitem_product FOREIGN KEY (product_id) REFERENCES Product(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_supporderitem_qty CHECK (qty > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Delivery (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  supplier_order_id BIGINT UNSIGNED NOT NULL,
  delivered_at DATETIME NOT NULL,
  invoice_no VARCHAR(64) NOT NULL,
  PRIMARY KEY (id),
  KEY fk_delivery_order (supplier_order_id),
  CONSTRAINT fk_delivery_order FOREIGN KEY (supplier_order_id) REFERENCES SupplierOrder(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE DeliveryItem (
  delivery_id BIGINT UNSIGNED NOT NULL,
  batch_id BIGINT UNSIGNED NOT NULL,
  qty_received INT NOT NULL,
  PRIMARY KEY (delivery_id, batch_id),
  KEY fk_deliveryitem_batch (batch_id),
  CONSTRAINT fk_deliveryitem_delivery FOREIGN KEY (delivery_id) REFERENCES Delivery(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_deliveryitem_batch FOREIGN KEY (batch_id) REFERENCES Batch(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_deliveryitem_qty CHECK (qty_received > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- 7. Returns and audit
-- -----------------------------------------------------

CREATE TABLE `Return` (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sale_id BIGINT UNSIGNED NOT NULL,
  returned_at DATETIME NOT NULL,
  reason VARCHAR(200) NULL,
  amount DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id),
  KEY fk_return_sale (sale_id),
  CONSTRAINT fk_return_sale FOREIGN KEY (sale_id) REFERENCES Sale(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE AuditLog (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  employee_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  action ENUM('view','sell','adjust','dispose') NOT NULL,
  ts DATETIME NOT NULL,
  details JSON NULL,
  PRIMARY KEY (id),
  KEY fk_audit_employee (employee_id),
  KEY fk_audit_product (product_id),
  KEY idx_audit_ts (ts),
  CONSTRAINT fk_audit_employee FOREIGN KEY (employee_id) REFERENCES Employee(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_audit_product FOREIGN KEY (product_id) REFERENCES Product(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Helpful view (inspection during defense)
CREATE OR REPLACE VIEW v_expiring_batches AS
SELECT p.name AS product, b.lot_no, ph.name AS pharmacy, ps.qty, b.exp_date
FROM PharmacyStock ps
JOIN Batch b ON b.id = ps.batch_id
JOIN Product p ON p.id = b.product_id
JOIN Pharmacy ph ON ph.id = ps.pharmacy_id
WHERE b.exp_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY);


