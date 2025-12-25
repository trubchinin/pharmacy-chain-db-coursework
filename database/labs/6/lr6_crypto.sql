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
