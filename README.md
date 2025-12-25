# Pharmacy Chain Coursework (MySQL + PHP)

Курсовий проєкт: схема аптеки `pharmacy_chain` (ЛР3–ЛР6) та веб-інтерфейс на PHP (ЛР7).

## Структура

-   `database/01_schema.sql`, `02_seed.sql` — ЛР3: створення БД та наповнення.
-   `database/03_refactor.sql` — ЛР4: рефакторинг, денормалізація, в’юхи, партиції.
-   `database/04_procedures.sql`, `05_triggers.sql` + `labs/5/*.sql` — ЛР5: функції/процедури, тригери, запити, тести.
-   `database/06_security.sql`, `07_crypto.sql`, `08_backup.sql` + `labs/6/*.sql` — ЛР6: ролі/привілеї, шифрування, бекапи, тести.
-   `app/` — ЛР7: PHP-інтерфейс до БД (логін, звіти, створення продажів, гостьові перегляди).

## Швидкий старт

1. Розгорніть БД MySQL 8.0:

```
cd database
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_seed.sql
mysql -u root -p < 03_refactor.sql
mysql -u root -p < 04_procedures.sql
mysql -u root -p < 05_triggers.sql
mysql -u root -p < 06_security.sql    # створює ролі й тестових користувачів
mysql -u root -p < 07_crypto.sql      # додає шифрування + в’юху v_customer_secure
mysql -u root -p < 08_backup.sql
```

2. Запустіть PHP застосунок (PHP ≥ 8.0, pdo_mysql):

```
cd app
# за потреби налаштуйте змінні середовища:
# DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=pharmacy_chain APP_KEY=ваш_секрет
php -S 127.0.0.1:8080
```

3. Логін у застосунок — MySQL-користувачі з `06_security.sql` (паролі замініть у прод):

-   `u_admin` / `Passw0rd!` (роль r_admin)
-   `u_pharm` / `Passw0rd!` (роль r_pharmacist)
-   `u_cashier` / `Passw0rd!` (роль r_cashier)
-   `u_auditor` / `Passw0rd!` (роль r_auditor)

## Примітки

-   Оригінальні файли лабораторних ЛР3–ЛР6 лежать у `database/labs/`.
-   Ключ шифрування за замовчуванням узгоджено між `database/07_crypto.sql` та `app/config.php` (`APP_KEY`), змініть для прод.
