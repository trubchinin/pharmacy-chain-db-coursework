# Database Scripts (`pharmacy_chain`)

Покроковий запуск у MySQL 8.0 (уточніть користувача/хост/порт під своє середовище):
```
mysql -u root -p < 01_schema.sql   # ЛР3: створення схеми
mysql -u root -p < 02_seed.sql     # ЛР3: тестові дані
mysql -u root -p < 03_refactor.sql # ЛР4: денормалізація, в’юхи, партиції
mysql -u root -p < 04_procedures.sql # ЛР5: функції/процедури (fn_apply_loyalty_discount, sp_create_sale, sp_apply_delivery)
mysql -u root -p < 05_triggers.sql   # ЛР5: тригери (аудит, перевірки)
mysql -u root -p < 06_security.sql   # ЛР6: ролі/користувачі r_admin/r_pharmacist/r_cashier/r_auditor + u_*
mysql -u root -p < 07_crypto.sql     # ЛР6: шифрування PII, в’юха v_customer_secure
mysql -u root -p < 08_backup.sql     # ЛР6: процедури бекапу/відновлення
```

Додаткові матеріали:
- `labs/3` — сирцеві скрипти ЛР3 (`lab3_pharmacy_chain.sql`, `lab3_pharmacy_chain_seed.sql`).
- `labs/4` — скрипти рефакторингу ЛР4.
- `labs/5` — оригінальні файли процедур/запитів/тестів ЛР5.
- `labs/6` — оригінальні файли ролей/шифрування/бекапів/тестів ЛР6.
