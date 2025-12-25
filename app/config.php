<?php
// Конфіг: налаштування підключення до MySQL (змінити під своє оточення)
return [
    'host' => getenv('DB_HOST') ?: '127.0.0.1',
    'port' => getenv('DB_PORT') ?: '3306',
    'db'   => getenv('DB_NAME') ?: 'pharmacy_chain',
    'app_key' => getenv('APP_KEY') ?: 'demo_secret_key_change_me',
];
