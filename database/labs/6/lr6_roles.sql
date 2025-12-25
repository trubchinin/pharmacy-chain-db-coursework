-- ЛР6: Ролі та права доступу (MySQL 8.0) — схема pharmacy_chain
-- Запускати під користувачем з правами CREATE ROLE / GRANT OPTION

-- 1) Створення ролей
CREATE ROLE IF NOT EXISTS r_admin;        -- повний доступ до схеми
CREATE ROLE IF NOT EXISTS r_pharmacist;   -- робота з продажами, рецептами, складом (читання товарів, партій)
CREATE ROLE IF NOT EXISTS r_cashier;      -- створення продажів, перегляд довідників
CREATE ROLE IF NOT EXISTS r_auditor;      -- тільки читання звітності/логів

-- 2) Привілеї на рівні схеми
GRANT ALL PRIVILEGES ON pharmacy_chain.* TO r_admin;

-- Pharmacist
GRANT SELECT, INSERT, UPDATE ON pharmacy_chain.Sale        TO r_pharmacist;
GRANT SELECT, INSERT, UPDATE ON pharmacy_chain.SaleItem    TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.Product        TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.Batch          TO r_pharmacist;
GRANT SELECT, UPDATE      ON pharmacy_chain.PharmacyStock  TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.Prescription   TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.PrescriptionItem TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.Customer       TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.Pharmacy       TO r_pharmacist;
GRANT SELECT              ON pharmacy_chain.SalesFactDaily TO r_pharmacist;
GRANT EXECUTE             ON PROCEDURE pharmacy_chain.sp_create_sale TO r_pharmacist;

-- Cashier
GRANT SELECT, INSERT      ON pharmacy_chain.Sale           TO r_cashier;
GRANT SELECT, INSERT      ON pharmacy_chain.SaleItem       TO r_cashier;
GRANT SELECT              ON pharmacy_chain.Product        TO r_cashier;
GRANT SELECT              ON pharmacy_chain.Batch          TO r_cashier;
GRANT SELECT              ON pharmacy_chain.Customer       TO r_cashier;

-- Auditor (читання звітності та логів)
GRANT SELECT ON pharmacy_chain.SalesFactDaily TO r_auditor;
GRANT SELECT ON pharmacy_chain.v_sales_by_pharmacy TO r_auditor;
GRANT SELECT ON pharmacy_chain.v_sales_top_products TO r_auditor;
GRANT SELECT ON pharmacy_chain.AuditLog TO r_auditor;

-- 3) Створення тестових користувачів і призначення ролей (приклад)
-- УВАГА: змініть пароль перед здачею
CREATE USER IF NOT EXISTS 'u_admin'@'%'      IDENTIFIED BY 'Passw0rd!';
CREATE USER IF NOT EXISTS 'u_pharm'@'%'      IDENTIFIED BY 'Passw0rd!';
CREATE USER IF NOT EXISTS 'u_cashier'@'%'    IDENTIFIED BY 'Passw0rd!';
CREATE USER IF NOT EXISTS 'u_auditor'@'%'    IDENTIFIED BY 'Passw0rd!';

GRANT r_admin     TO 'u_admin'@'%';
GRANT r_pharmacist TO 'u_pharm'@'%';
GRANT r_cashier    TO 'u_cashier'@'%';
GRANT r_auditor    TO 'u_auditor'@'%';

SET DEFAULT ROLE r_admin      TO 'u_admin'@'%';
SET DEFAULT ROLE r_pharmacist TO 'u_pharm'@'%';
SET DEFAULT ROLE r_cashier    TO 'u_cashier'@'%';
SET DEFAULT ROLE r_auditor    TO 'u_auditor'@'%';
