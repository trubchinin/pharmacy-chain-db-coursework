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
