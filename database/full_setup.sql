-- Lab 3: Physical Data Model (MySQL 8.0, InnoDB, utf8mb4)
-- Schema: Pharmacy Chain (Variant #2)

SET NAMES utf8mb4;
SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET time_zone = '+00:00';

-- Recreate database to allow re-running the script safely
DROP DATABASE IF EXISTS pharmacy_chain;
CREATE DATABASE IF NOT EXISTS pharmacy_chain
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
USE pharmacy_chain;

-- -----------------------------------------------------
-- 1. Reference tables
-- -----------------------------------------------------

CREATE TABLE Region (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_region_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE City (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  region_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY fk_city_region (region_id),
  CONSTRAINT fk_city_region FOREIGN KEY (region_id) REFERENCES Region(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE Role (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_role_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE Manufacturer (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  country VARCHAR(80) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_manufacturer_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE DosageForm (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dosageform_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE Supplier (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  tax_no VARCHAR(32) NOT NULL,
  phone VARCHAR(32) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_supplier_tax (tax_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE SalePromotion (
  sale_id BIGINT UNSIGNED NOT NULL,
  promotion_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (sale_id, promotion_id),
  KEY fk_salepromo_promo (promotion_id),
  CONSTRAINT fk_salepromo_sale FOREIGN KEY (sale_id) REFERENCES Sale(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_salepromo_promo FOREIGN KEY (promotion_id) REFERENCES Promotion(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE Delivery (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  supplier_order_id BIGINT UNSIGNED NOT NULL,
  delivered_at DATETIME NOT NULL,
  invoice_no VARCHAR(64) NOT NULL,
  PRIMARY KEY (id),
  KEY fk_delivery_order (supplier_order_id),
  CONSTRAINT fk_delivery_order FOREIGN KEY (supplier_order_id) REFERENCES SupplierOrder(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Helpful view (inspection during defense)
CREATE OR REPLACE VIEW v_expiring_batches AS
SELECT p.name AS product, b.lot_no, ph.name AS pharmacy, ps.qty, b.exp_date
FROM PharmacyStock ps
JOIN Batch b ON b.id = ps.batch_id
JOIN Product p ON p.id = b.product_id
JOIN Pharmacy ph ON ph.id = ps.pharmacy_id
WHERE b.exp_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY);


-- Lab 3: Seed data for Pharmacy Chain (Variant #2)
-- Run after: 01_schema.sql

SET NAMES utf8mb4;
USE pharmacy_chain;

-- -----------------------------------------------------
-- 1) Reference data: Region, City, Pharmacy, Role, Employee
-- -----------------------------------------------------

INSERT INTO Region (name) VALUES
  ('North'), ('South'), ('East');

INSERT INTO City (name, region_id)
SELECT v.city, r.id
FROM (
  SELECT 'Springfield' AS city, 'North' AS region UNION ALL
  SELECT 'Shelbyville', 'North' UNION ALL
  SELECT 'South City', 'South' UNION ALL
  SELECT 'Eastown', 'East'
) v
JOIN Region r ON r.name = v.region;

INSERT INTO Pharmacy (name, address, city_id, license_no, status)
SELECT v.name, v.address, c.id, v.license_no, v.status
FROM (
  SELECT 'Central Pharmacy' AS name, '123 Main St' AS address, 'Springfield' AS city, 'LIC-001' AS license_no, 'active' AS status UNION ALL
  SELECT 'Riverside Pharmacy', '45 Riverside Ave', 'Shelbyville', 'LIC-002', 'active' UNION ALL
  SELECT 'SouthCare Pharmacy', '9 Ocean Blvd', 'South City', 'LIC-003', 'inactive'
) v
JOIN City c ON c.name = v.city;

INSERT INTO Role (name) VALUES ('Pharmacist'), ('Cashier'), ('Manager');

INSERT INTO Employee (pharmacy_id, role_id, full_name, hired_at, is_active)
SELECT p.id, r.id, v.full_name, v.hired_at, v.is_active
FROM (
  SELECT 'Central Pharmacy' AS pharmacy, 'Pharmacist' AS role, 'Alice Brown' AS full_name, DATE('2021-03-01') AS hired_at, 1 AS is_active UNION ALL
  SELECT 'Central Pharmacy', 'Cashier', 'Bob Smith', DATE('2022-06-15'), 1 UNION ALL
  SELECT 'Riverside Pharmacy', 'Manager', 'Carol Jones', DATE('2020-01-10'), 1 UNION ALL
  SELECT 'Riverside Pharmacy', 'Pharmacist', 'David Miller', DATE('2023-02-20'), 1 UNION ALL
  SELECT 'SouthCare Pharmacy', 'Cashier', 'Eva Johnson', DATE('2022-11-05'), 0
) v
JOIN Pharmacy p ON p.name = v.pharmacy
JOIN Role r ON r.name = v.role;

-- -----------------------------------------------------
-- 2) Catalog: Manufacturer, DosageForm, Product, Supplier
-- -----------------------------------------------------

INSERT INTO Manufacturer (name, country) VALUES
  ('ACME Pharma', 'USA'),
  ('HealthCorp', 'Germany'),
  ('BioMed', 'UK');

INSERT INTO DosageForm (name) VALUES
  ('Tablet'), ('Capsule'), ('Syrup'), ('Ointment'), ('Injection');

-- Products: mix of OTC and Rx/controlled
INSERT INTO Product (name, atc_code, dosage_form_id, manufacturer_id, is_rx, is_controlled, strength, unit, pack_size)
SELECT v.name, v.atc, df.id, m.id, v.is_rx, v.is_ctrl, v.strength, v.unit, v.pack_size
FROM (
  SELECT 'Paracetamol 500 mg Tablet' AS name, 'N02BE01' AS atc, 'Tablet' AS df, 'ACME Pharma' AS mf, 0 AS is_rx, 0 AS is_ctrl, '500' AS strength, 'mg' AS unit, 10 AS pack_size UNION ALL
  SELECT 'Ibuprofen 200 mg Tablet', 'M01AE01', 'Tablet', 'ACME Pharma', 0, 0, '200', 'mg', 20 UNION ALL
  SELECT 'Amoxicillin 500 mg Capsule', 'J01CA04', 'Capsule', 'HealthCorp', 1, 0, '500', 'mg', 20 UNION ALL
  SELECT 'Insulin 100 IU/mL Injection', 'A10AB01', 'Injection', 'BioMed', 1, 1, '100', 'IU/mL', 1 UNION ALL
  SELECT 'Cough Syrup 100 ml', 'R05DA20', 'Syrup', 'HealthCorp', 0, 0, '100', 'ml', 1 UNION ALL
  SELECT 'Morphine 10 mg Injection', 'N02AA01', 'Injection', 'BioMed', 1, 1, '10', 'mg', 1
) v
JOIN DosageForm df ON df.name = v.df
JOIN Manufacturer m ON m.name = v.mf;

INSERT INTO Supplier (name, tax_no, phone) VALUES
  ('MedSupply', 'TAX001', '+1-202-555-0101'),
  ('GoodHealth', 'TAX002', '+1-202-555-0102'),
  ('PharmaLogistics', 'TAX003', '+1-202-555-0103');

-- -----------------------------------------------------
-- 3) Batches (per product & supplier)
-- -----------------------------------------------------

INSERT INTO Batch (product_id, supplier_id, lot_no, mfg_date, exp_date, buy_price)
SELECT p.id, s.id, v.lot, v.mfg, v.exp, v.price
FROM (
  SELECT 'Paracetamol 500 mg Tablet' AS prod, 'MedSupply' AS supp, 'PARA-LOT-A' AS lot, DATE('2024-01-15') AS mfg, DATE('2026-01-15') AS exp, 1.50 AS price UNION ALL
  SELECT 'Paracetamol 500 mg Tablet', 'GoodHealth', 'PARA-LOT-B', DATE('2024-05-10'), DATE('2026-05-10'), 1.55 UNION ALL
  SELECT 'Ibuprofen 200 mg Tablet', 'MedSupply', 'IBU-LOT-A', DATE('2024-02-20'), DATE('2026-02-20'), 2.10 UNION ALL
  SELECT 'Amoxicillin 500 mg Capsule', 'PharmaLogistics', 'AMOX-LOT-A', DATE('2024-03-01'), DATE('2025-09-01'), 5.80 UNION ALL
  SELECT 'Insulin 100 IU/mL Injection', 'BioMed' /* supplier name differs; we use real supplier below */ , 'INS-LOT-A', DATE('2024-04-01'), DATE('2025-04-01'), 12.00 UNION ALL
  SELECT 'Cough Syrup 100 ml', 'GoodHealth', 'CSYR-LOT-A', DATE('2024-03-15'), DATE('2025-03-15'), 3.40 UNION ALL
  SELECT 'Morphine 10 mg Injection', 'PharmaLogistics', 'MOR-LOT-A', DATE('2024-01-10'), DATE('2025-01-10'), 18.00
) v
JOIN Product p ON p.name = v.prod
JOIN Supplier s ON s.name = CASE
  WHEN v.supp = 'BioMed' THEN 'PharmaLogistics' -- ensure supplier exists (BioMed is manufacturer)
  ELSE v.supp
END;

-- -----------------------------------------------------
-- 4) Loyalty & Customers
-- -----------------------------------------------------

INSERT INTO LoyaltyTier (name, discount_pct) VALUES
  ('Bronze', 0.00), ('Silver', 5.00), ('Gold', 10.00);

INSERT INTO LoyaltyCard (number, tier_id, points)
SELECT v.num, t.id, v.points
FROM (
  SELECT 'LC1001' AS num, 'Bronze' AS tier, 120 AS points UNION ALL
  SELECT 'LC1002', 'Silver', 300 UNION ALL
  SELECT 'LC1003', 'Gold', 900
) v
JOIN LoyaltyTier t ON t.name = v.tier;

INSERT INTO Customer (full_name, phone, email, card_id)
SELECT v.full_name, v.phone, v.email, c.id
FROM (
  SELECT 'John Doe' AS full_name, '+1-202-555-1001' AS phone, 'john@example.com' AS email, 'LC1001' AS card UNION ALL
  SELECT 'Jane Roe', '+1-202-555-1002', 'jane@example.com', 'LC1002' UNION ALL
  SELECT 'Max Payne', '+1-202-555-1003', 'max@example.com', NULL UNION ALL
  SELECT 'Ann Smith', NULL, 'ann@example.com', 'LC1003' UNION ALL
  SELECT 'Bruce Wayne', '+1-202-555-1004', NULL, NULL
) v
LEFT JOIN LoyaltyCard c ON c.number = v.card;

-- -----------------------------------------------------
-- 5) Prescriptions & Items (for RX/controlled products)
-- -----------------------------------------------------

INSERT INTO Prescription (customer_id, doctor_name, doctor_license, issued_at, valid_to)
VALUES (
  (SELECT id FROM Customer WHERE full_name = 'John Doe'), 'Dr. House', 'DOC-0001', DATE('2025-09-01'), DATE('2025-12-01')
);
SET @rx1 := LAST_INSERT_ID();

INSERT INTO PrescriptionItem (prescription_id, product_id, dosage, qty, repeats_left)
VALUES
  (@rx1, (SELECT id FROM Product WHERE name = 'Amoxicillin 500 mg Capsule'), '1 cap x 3/day', 30, 0),
  (@rx1, (SELECT id FROM Product WHERE name = 'Insulin 100 IU/mL Injection'), '10 IU daily', 3, 1);

-- -----------------------------------------------------
-- 6) Supplier Orders, Deliveries, Delivery Items
-- -----------------------------------------------------

INSERT INTO SupplierOrder (pharmacy_id, supplier_id, ordered_at, status)
VALUES
  ((SELECT id FROM Pharmacy WHERE name='Central Pharmacy'), (SELECT id FROM Supplier WHERE name='MedSupply'), NOW() - INTERVAL 15 DAY, 'received');
SET @so1 := LAST_INSERT_ID();

INSERT INTO SupplierOrderItem (supplier_order_id, product_id, qty, price)
VALUES
  (@so1, (SELECT id FROM Product WHERE name='Paracetamol 500 mg Tablet'), 200, 1.50),
  (@so1, (SELECT id FROM Product WHERE name='Ibuprofen 200 mg Tablet'), 150, 2.10);

INSERT INTO Delivery (supplier_order_id, delivered_at, invoice_no)
VALUES (@so1, NOW() - INTERVAL 13 DAY, 'INV-1001');
SET @del1 := LAST_INSERT_ID();

INSERT INTO DeliveryItem (delivery_id, batch_id, qty_received)
VALUES
  (@del1, (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Paracetamol 500 mg Tablet' ORDER BY b.exp_date LIMIT 1), 200),
  (@del1, (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Ibuprofen 200 mg Tablet' ORDER BY b.exp_date LIMIT 1), 150);

-- Stock per pharmacy derived from deliveries
INSERT INTO PharmacyStock (pharmacy_id, batch_id, qty)
SELECT so.pharmacy_id, di.batch_id, di.qty_received
FROM DeliveryItem di
JOIN Delivery d ON d.id = di.delivery_id
JOIN SupplierOrder so ON so.id = d.supplier_order_id
LEFT JOIN PharmacyStock ps ON ps.pharmacy_id = so.pharmacy_id AND ps.batch_id = di.batch_id
WHERE ps.pharmacy_id IS NULL;

-- -----------------------------------------------------
-- 7) Promotions
-- -----------------------------------------------------

INSERT INTO Promotion (name, start_at, end_at, rules)
VALUES
  ('Summer Sale', NOW() - INTERVAL 10 DAY, NOW() + INTERVAL 20 DAY, JSON_OBJECT('discount','10% on OTC')),
  ('Loyalty Bonus', NOW() - INTERVAL 5 DAY, NOW() + INTERVAL 25 DAY, JSON_OBJECT('tier','Gold','extra_pct',5));

-- -----------------------------------------------------
-- 8) Sales and SaleItems (mix of OTC and RX)
-- -----------------------------------------------------

-- Sale 1 (customer with prescription), two lines
INSERT INTO Sale (pharmacy_id, employee_id, customer_id, sold_at, total, discount_total, pay_method)
VALUES (
  (SELECT id FROM Pharmacy WHERE name='Central Pharmacy'),
  (SELECT id FROM Employee WHERE full_name='Bob Smith'),
  (SELECT id FROM Customer WHERE full_name='John Doe'),
  NOW() - INTERVAL 2 DAY, 50.00, 5.00, 'card'
);
SET @sale1 := LAST_INSERT_ID();

INSERT INTO SaleItem (sale_id, line_no, product_id, batch_id, qty, price, prescription_id, prescription_product_id)
VALUES
  (@sale1, 1,
   (SELECT id FROM Product WHERE name='Paracetamol 500 mg Tablet'),
   (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Paracetamol 500 mg Tablet' ORDER BY b.exp_date LIMIT 1),
   2, 10.00, NULL, NULL),
  (@sale1, 2,
   (SELECT id FROM Product WHERE name='Amoxicillin 500 mg Capsule'),
   (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Amoxicillin 500 mg Capsule' ORDER BY b.exp_date LIMIT 1),
   1, 15.00, @rx1, (SELECT id FROM Product WHERE name='Amoxicillin 500 mg Capsule'));

-- Link promotion
INSERT INTO SalePromotion (sale_id, promotion_id)
VALUES (@sale1, (SELECT id FROM Promotion WHERE name='Summer Sale'));

-- Sale 2 (OTC only)
INSERT INTO Sale (pharmacy_id, employee_id, customer_id, sold_at, total, discount_total, pay_method)
VALUES (
  (SELECT id FROM Pharmacy WHERE name='Riverside Pharmacy'),
  (SELECT id FROM Employee WHERE full_name='David Miller'),
  (SELECT id FROM Customer WHERE full_name='Jane Roe'),
  NOW() - INTERVAL 1 DAY, 25.00, 0.00, 'cash'
);
SET @sale2 := LAST_INSERT_ID();

INSERT INTO SaleItem (sale_id, line_no, product_id, batch_id, qty, price, prescription_id, prescription_product_id)
VALUES
  (@sale2, 1,
   (SELECT id FROM Product WHERE name='Ibuprofen 200 mg Tablet'),
   (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Ibuprofen 200 mg Tablet' ORDER BY b.exp_date LIMIT 1),
   1, 8.00, NULL, NULL),
  (@sale2, 2,
   (SELECT id FROM Product WHERE name='Cough Syrup 100 ml'),
   (SELECT b.id FROM Batch b JOIN Product p ON p.id=b.product_id WHERE p.name='Cough Syrup 100 ml' ORDER BY b.exp_date LIMIT 1),
   1, 12.00, NULL, NULL);

-- -----------------------------------------------------
-- 9) Returns & Audit
-- -----------------------------------------------------

INSERT INTO `Return` (sale_id, returned_at, reason, amount)
VALUES (@sale2, NOW() - INTERVAL 12 HOUR, 'Customer changed mind', 8.00);

INSERT INTO AuditLog (employee_id, product_id, action, ts, details)
VALUES
  ((SELECT id FROM Employee WHERE full_name='Alice Brown'), (SELECT id FROM Product WHERE name='Insulin 100 IU/mL Injection'), 'view', NOW() - INTERVAL 3 DAY, JSON_OBJECT('note','inventory check')),
  ((SELECT id FROM Employee WHERE full_name='Bob Smith'), (SELECT id FROM Product WHERE name='Amoxicillin 500 mg Capsule'), 'sell', NOW() - INTERVAL 2 DAY, JSON_OBJECT('sale_id', @sale1));

-- Done

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

-- Початкове наповнення факту
CALL sp_build_sales_fact_daily(CURDATE() - INTERVAL 10 YEAR, CURDATE() + INTERVAL 1 DAY)//

-- Тригер для підтримки факту в реальному часі (INSERT)
DROP TRIGGER IF EXISTS trg_saleitem_ai_fact_sync//
CREATE TRIGGER trg_saleitem_ai_fact_sync
AFTER INSERT ON SaleItem
FOR EACH ROW
BEGIN
  DECLARE v_date DATE;
  DECLARE v_pharm_id BIGINT UNSIGNED;
  
  SELECT DATE(sold_at), pharmacy_id INTO v_date, v_pharm_id 
  FROM Sale WHERE id = NEW.sale_id;
  
  INSERT INTO SalesFactDaily (d, pharmacy_id, product_id, qty, revenue, checks_cnt)
  VALUES (v_date, v_pharm_id, NEW.product_id, NEW.qty, NEW.qty * NEW.price, 1)
  ON DUPLICATE KEY UPDATE
    qty = qty + NEW.qty,
    revenue = revenue + (NEW.qty * NEW.price);
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
-- ЛР6: Ролі та права доступу (MySQL 8.0) — схема pharmacy_chain
-- Запускати під користувачем з правами CREATE ROLE / GRANT OPTION

-- 1) Створення ролей (Коментовано для сумісності зі старими версіями)
-- CREATE ROLE IF NOT EXISTS r_admin;
-- CREATE ROLE IF NOT EXISTS r_pharmacist;
-- CREATE ROLE IF NOT EXISTS r_cashier;
-- CREATE ROLE IF NOT EXISTS r_auditor;

-- 2) Привілеї на рівні схеми
-- GRANT ALL PRIVILEGES ON pharmacy_chain.* TO r_admin;

-- Pharmacist
-- GRANT SELECT, INSERT, UPDATE ON pharmacy_chain.Sale        TO r_pharmacist;
-- GRANT SELECT, INSERT, UPDATE ON pharmacy_chain.SaleItem    TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.Product        TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.Batch          TO r_pharmacist;
-- GRANT SELECT, UPDATE      ON pharmacy_chain.PharmacyStock  TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.Prescription   TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.PrescriptionItem TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.Customer       TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.Pharmacy       TO r_pharmacist;
-- GRANT SELECT              ON pharmacy_chain.SalesFactDaily TO r_pharmacist;
-- GRANT EXECUTE             ON PROCEDURE pharmacy_chain.sp_create_sale TO r_pharmacist;

-- Cashier
-- GRANT SELECT, INSERT      ON pharmacy_chain.Sale           TO r_cashier;
-- GRANT SELECT, INSERT      ON pharmacy_chain.SaleItem       TO r_cashier;
-- GRANT SELECT              ON pharmacy_chain.Product        TO r_cashier;
-- GRANT SELECT              ON pharmacy_chain.Batch          TO r_cashier;
-- GRANT SELECT              ON pharmacy_chain.Customer       TO r_cashier;

-- Auditor (читання звітності та логів)
-- GRANT SELECT ON pharmacy_chain.SalesFactDaily TO r_auditor;
-- GRANT SELECT ON pharmacy_chain.v_sales_by_pharmacy TO r_auditor;
-- GRANT SELECT ON pharmacy_chain.v_sales_top_products TO r_auditor;
-- GRANT SELECT ON pharmacy_chain.AuditLog TO r_auditor;

-- 3) Створення тестових користувачів і призначення ролей (приклад)
-- УВАГА: змініть пароль перед здачею
CREATE USER IF NOT EXISTS 'u_admin'@'%'      IDENTIFIED BY 'Passw0rd!';
CREATE USER IF NOT EXISTS 'u_pharm'@'%'      IDENTIFIED BY 'Passw0rd!';
CREATE USER IF NOT EXISTS 'u_cashier'@'%'    IDENTIFIED BY 'Passw0rd!';
CREATE USER IF NOT EXISTS 'u_auditor'@'%'    IDENTIFIED BY 'Passw0rd!';

-- Прямі права (для MariaDB, де ROLE може не працювати)
GRANT ALL PRIVILEGES ON pharmacy_chain.* TO 'u_admin'@'%';

GRANT SELECT, INSERT, UPDATE ON pharmacy_chain.Sale TO 'u_pharm'@'%';
GRANT SELECT, INSERT, UPDATE ON pharmacy_chain.SaleItem TO 'u_pharm'@'%';
GRANT SELECT, UPDATE ON pharmacy_chain.PharmacyStock TO 'u_pharm'@'%';
GRANT SELECT ON pharmacy_chain.Product TO 'u_pharm'@'%';
GRANT SELECT ON pharmacy_chain.Batch TO 'u_pharm'@'%';
GRANT SELECT ON pharmacy_chain.Customer TO 'u_pharm'@'%';
GRANT SELECT ON pharmacy_chain.Pharmacy TO 'u_pharm'@'%';
GRANT SELECT ON pharmacy_chain.SalesFactDaily TO 'u_pharm'@'%';
GRANT EXECUTE ON PROCEDURE pharmacy_chain.sp_create_sale TO 'u_pharm'@'%';
GRANT SELECT ON pharmacy_chain.v_expiring_batches TO 'u_pharm'@'%';

GRANT SELECT, INSERT ON pharmacy_chain.Sale TO 'u_cashier'@'%';
GRANT SELECT, INSERT ON pharmacy_chain.SaleItem TO 'u_cashier'@'%';
GRANT SELECT ON pharmacy_chain.Product TO 'u_cashier'@'%';
GRANT SELECT ON pharmacy_chain.Batch TO 'u_cashier'@'%';
GRANT SELECT ON pharmacy_chain.Customer TO 'u_cashier'@'%';
GRANT SELECT ON pharmacy_chain.SalesFactDaily TO 'u_cashier'@'%';
GRANT EXECUTE ON PROCEDURE pharmacy_chain.sp_create_sale TO 'u_cashier'@'%';

GRANT SELECT ON pharmacy_chain.SalesFactDaily TO 'u_auditor'@'%';
GRANT SELECT ON pharmacy_chain.v_sales_by_pharmacy TO 'u_auditor'@'%';
GRANT SELECT ON pharmacy_chain.v_sales_top_products TO 'u_auditor'@'%';
GRANT SELECT ON pharmacy_chain.AuditLog TO 'u_auditor'@'%';
GRANT SELECT ON pharmacy_chain.v_customer_secure TO 'u_auditor'@'%';

FLUSH PRIVILEGES;

-- GRANT r_admin     TO 'u_admin'@'%';
-- GRANT r_pharmacist TO 'u_pharm'@'%';
-- GRANT r_cashier    TO 'u_cashier'@'%';
-- GRANT r_auditor    TO 'u_auditor'@'%';

-- SET DEFAULT ROLE r_admin      TO 'u_admin'@'%';
-- SET DEFAULT ROLE r_pharmacist FOR 'u_pharm'@'%';
-- SET DEFAULT ROLE r_cashier    TO 'u_cashier'@'%';
-- SET DEFAULT ROLE r_auditor    TO 'u_auditor'@'%';
-- ЛР6: Шифрування/дешифрування даних (MySQL 8.0)
-- Модель: симетричне шифрування AES для чутливих полів клієнта (email, phone)
-- Примітка: у проді ключі зберігати у зовнішньому KMS/ENV, не в коді БД

USE pharmacy_chain;

-- 1) Таблиці/поля для шифрування (для звіту): Customer.email, Customer.phone
--    Замість зберігання у відкритому вигляді — зберігати VARBINARY та віддавати через функції.

-- Підготовка: створимо віртуальний keyring (демо, НЕ для продакшну)
SET @app_key := SHA2('demo_secret_key_change_me', 256);

-- 2) Допоміжні функції
DELIMITER //
DROP FUNCTION IF EXISTS fn_encrypt_varchar//
CREATE FUNCTION fn_encrypt_varchar(p_plaintext VARCHAR(255))
RETURNS VARBINARY(1024)
DETERMINISTIC
BEGIN
  IF p_plaintext IS NULL THEN RETURN NULL; END IF;
  RETURN AES_ENCRYPT(p_plaintext, UNHEX(@app_key));
END//

DROP FUNCTION IF EXISTS fn_decrypt_varchar//
CREATE FUNCTION fn_decrypt_varchar(p_cipher VARBINARY(1024))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  IF p_cipher IS NULL THEN RETURN NULL; END IF;
  RETURN AES_DECRYPT(p_cipher, UNHEX(@app_key));
END//
DELIMITER ;

-- 3) Демо-колонки (не змінюємо існуючу схему, додаємо паралельні поля)
-- Додаємо колонки ідемпотентно через INFORMATION_SCHEMA
SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE Customer ADD COLUMN phone_enc VARBINARY(1024) NULL AFTER phone'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Customer' AND COLUMN_NAME = 'phone_enc'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (
  SELECT CASE WHEN COUNT(*)=0
         THEN 'ALTER TABLE Customer ADD COLUMN email_enc VARBINARY(1024) NULL AFTER email'
         ELSE 'SELECT 1' END
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Customer' AND COLUMN_NAME = 'email_enc'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Міграція існуючих значень у зашифрований вигляд
UPDATE Customer SET
  phone_enc = fn_encrypt_varchar(phone),
  email_enc = fn_encrypt_varchar(email)
WHERE phone IS NOT NULL OR email IS NOT NULL;

-- 4) Представлення із прозорою розшифровкою для читання (обмежити доступ ролево)
CREATE OR REPLACE VIEW v_customer_secure AS
SELECT id, full_name,
       fn_decrypt_varchar(phone_enc) AS phone,
       fn_decrypt_varchar(email_enc) AS email,
       card_id
FROM Customer;
-- ЛР6: Резервне копіювання та відновлення (MySQL 8.0)
-- Примітка: для повного резервного копіювання БД у проді використовуйте mysqldump / періодичні snapshot-и.
-- Нижче наведено: політика, приклад job-ів та допоміжні процедури для логічного бекапу окремих таблиць.

-- 1) Політика резервного копіювання (для звіту):
-- - Повний бекап БД pharmacy_chain: щоденно о 02:00, зберігати 7 днів.
-- - Щотижневий архів (неділя) – зберігати 4 тижні.
-- - Критичні таблиці для окремого експорту: Sale, SaleItem, Batch, PharmacyStock, AuditLog.

-- 2) Рекомендована команда (адміністратор ОС, не в SQL):
-- mysqldump -u <user> -p --routines --events --single-transaction --databases pharmacy_chain \
--   | gzip > /backups/pharmacy_chain_$(date +%F).sql.gz

-- 3) Збережені процедури для логічного бекапу таблиць у CSV (на серверному файловому сховищі)
USE pharmacy_chain;
DELIMITER //

DROP PROCEDURE IF EXISTS sp_backup_table_csv//
CREATE PROCEDURE sp_backup_table_csv(IN p_table VARCHAR(64), IN p_dir VARCHAR(255))
BEGIN
  -- УВАГА: потрібні FILE привілеї та доступний шлях p_dir на сервері MySQL
  SET @sql := CONCAT(
    'SELECT * FROM ', p_table,
    ' INTO OUTFILE \'', p_dir, '/', p_table, '_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%S'), '.csv\' ',
    " FIELDS TERMINATED BY ',' ",
    " LINES TERMINATED BY '\n'"
  );
  PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
END//

-- Авто-варіант: використовує @@secure_file_priv як каталог призначення
DROP PROCEDURE IF EXISTS sp_backup_table_csv_auto//
CREATE PROCEDURE sp_backup_table_csv_auto(IN p_table VARCHAR(64))
BEGIN
  DECLARE v_dir VARCHAR(255);
  DECLARE v_now VARCHAR(32);
  SELECT @@secure_file_priv INTO v_dir;
  IF v_dir IS NULL OR v_dir = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'secure_file_priv не налаштовано: INTO OUTFILE заборонено';
  END IF;
  SET v_now = DATE_FORMAT(NOW(), '%Y%m%d_%H%i%S');
  SET @sql := CONCAT(
    'SELECT * FROM ', p_table,
    ' INTO OUTFILE \'', v_dir, IF(RIGHT(v_dir,1)='/', '', '/'), p_table, '_', v_now, '.csv\' ',
    " FIELDS TERMINATED BY ',' ",
    " LINES TERMINATED BY '\n'"
  );
  PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
END//

DROP PROCEDURE IF EXISTS sp_restore_table_csv//
CREATE PROCEDURE sp_restore_table_csv(IN p_table VARCHAR(64), IN p_file VARCHAR(255))
BEGIN
  -- Очікується сумісний CSV (порядок колонок = як у таблиці)
  SET @sql := CONCAT(
    'LOAD DATA INFILE \'', p_file, '\' INTO TABLE ', p_table,
    " FIELDS TERMINATED BY ',' ",
    " LINES TERMINATED BY '\n'"
  );
  PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
END//

-- Авто-варіант: підставляє каталог @@secure_file_priv і приймає лише базову назву файлу
DROP PROCEDURE IF EXISTS sp_restore_table_csv_auto//
CREATE PROCEDURE sp_restore_table_csv_auto(IN p_table VARCHAR(64), IN p_basename VARCHAR(255))
BEGIN
  DECLARE v_dir VARCHAR(255);
  SELECT @@secure_file_priv INTO v_dir;
  IF v_dir IS NULL OR v_dir = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'secure_file_priv не налаштовано: LOAD DATA INFILE заборонено';
  END IF;
  SET @sql := CONCAT(
    'LOAD DATA INFILE \'', v_dir, IF(RIGHT(v_dir,1)='/', '', '/'), p_basename, '\' INTO TABLE ', p_table,
    " FIELDS TERMINATED BY ',' ",
    " LINES TERMINATED BY '\n'"
  );
  PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
END//

DELIMITER ;
