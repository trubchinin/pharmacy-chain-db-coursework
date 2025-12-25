-- ЛР6: Тести (SQLPro)
USE pharmacy_chain;

-- 1) Перевірка ролей (виконується адміністратором)
-- Показати призначення ролей
SELECT grantee, role_name, is_default
FROM INFORMATION_SCHEMA.APPLICABLE_ROLES
WHERE grantee IN ("'u_admin'@'%'","'u_pharm'@'%'","'u_cashier'@'%'","'u_auditor'@'%'");

-- 2) Бекап таблиці у CSV (потрібні FILE‑права й доступний каталог на сервері)
-- CALL sp_backup_table_csv('Sale', '/var/lib/mysql-files');

-- 3) Відновлення з CSV (демо; файл має існувати на сервері)
-- CALL sp_restore_table_csv('Sale', '/var/lib/mysql-files/Sale_YYYYMMDD_HHMMSS.csv');

-- 4) Шифрування/дешифрування
-- Перевірка подання з прозорою розшифровкою (має показати дані з phone/email)
SELECT * FROM v_customer_secure LIMIT 5;

-- Точкова перевірка функцій
SELECT fn_encrypt_varchar('test@example.com') AS enc,
       fn_decrypt_varchar(fn_encrypt_varchar('test@example.com')) AS decrypted;
