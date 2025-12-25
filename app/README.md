# ЛР7: PHP-інтерфейс до `pharmacy_chain`

## Запуск локально (PHP built-in)
1. Переконайтесь, що встановлено PHP ≥ 8.0 + розширення `pdo_mysql`.
2. Налаштуйте підключення (опційно через ENV):
   - `DB_HOST` (за замовчуванням `127.0.0.1`)
   - `DB_PORT` (за замовчуванням `3306`)
   - `DB_NAME` (за замовчуванням `pharmacy_chain`)
   - `APP_KEY`  (має збігатися з ключем у `database/07_crypto.sql`, за замовчуванням `demo_secret_key_change_me`)
3. Запустіть:
   ```bash
   cd app
   php -S 127.0.0.1:8080
   ```
4. Відкрийте `http://127.0.0.1:8080/` у браузері.

## Логін
Використовуйте MySQL-користувачів, створених у `database/06_security.sql` (змініть паролі перед продом):
- `u_admin` / `Passw0rd!` — роль `r_admin`
- `u_pharm` / `Passw0rd!` — роль `r_pharmacist`
- `u_cashier` / `Passw0rd!` — роль `r_cashier`
- `u_auditor` / `Passw0rd!` — роль `r_auditor`

## Функціонал
- Логін/лог-аут (підключення до MySQL від імені введеного користувача).
- Звіти: виручка за період (`SalesFactDaily`), партії з коротким терміном (`v_expiring_batches`).
- Операції: створення продажу (`sp_create_sale`), гостьові перегляди та secure-в’юхи (`v_customer_secure`).
- Навігація у `nav` зверху кожної сторінки.
