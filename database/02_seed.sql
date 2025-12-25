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

