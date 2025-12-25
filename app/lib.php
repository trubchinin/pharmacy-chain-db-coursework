<?php
session_start();

function db(): PDO {
    static $pdo = null;
    if ($pdo) return $pdo;
    $cfg = require __DIR__ . '/config.php';
    $user = $_SESSION['db_user'] ?? null;
    $pass = $_SESSION['db_pass'] ?? null;
    if (!$user || !$pass) {
        throw new RuntimeException('Користувач не автентифікований');
    }
    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $cfg['host'], $cfg['port'], $cfg['db']);
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    // активуємо ролі за замовчуванням, якщо налаштовано
    try { $pdo->exec('SET ROLE ALL'); } catch (Throwable $e) {}
    // ініціалізуємо ключ шифрування для поточної сесії
    try {
        $keyHex = strtoupper(hash('sha256', (require __DIR__.'/config.php')['app_key']));
        $pdo->exec("SET @app_key = '{$keyHex}'");
    } catch (Throwable $e) {}
    return $pdo;
}

function login(string $user, string $pass): bool {
    $cfg = require __DIR__ . '/config.php';
    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $cfg['host'], $cfg['port'], $cfg['db']);
    try {
        $pdo = new PDO($dsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        try { $pdo->exec('SET ROLE ALL'); } catch (Throwable $e) {}
        $_SESSION['db_user'] = $user;
        $_SESSION['db_pass'] = $pass;
        // збережемо поточну роль (за потреби)
        $role = $pdo->query('SELECT CURRENT_ROLE() AS r')->fetch()['r'] ?? null;
        $_SESSION['db_role'] = $role;
        return true;
    } catch (Throwable $e) {
        return false;
    }
}

function logout(): void {
    session_destroy();
}

function ensure_logged_in(): void {
    if (!isset($_SESSION['db_user'])) {
        header('Location: /login.php');
        exit;
    }
}

function render_header(string $title = 'ЛР7'): void {
    echo "<!doctype html><html><head><meta charset='utf-8'><title>" . htmlspecialchars($title) . "</title>
<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/water.css@2/out/water.css'>
</head><body><nav><a href='/'>Головна</a> | <a href='/report_revenue.php'>Звіт виручка</a> | <a href='/report_expiring.php'>Партії</a> | <a href='/sale_create.php'>Створити продаж</a> | <a href='/admin_customers.php'>Клієнти (адмін)</a> | <a href='/guest_views.php'>Гостьові</a> | <a href='/logout.php'>Вихід</a></nav><hr>";
}

function render_footer(): void { echo "</body></html>"; }
