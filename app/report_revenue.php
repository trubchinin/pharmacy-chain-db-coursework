<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
if (!in_array($_SESSION['db_user'], ['root', 'u_admin', 'u_pharm', 'u_cashier', 'u_auditor'])) {
    die('Доступ заборонено: у вас недостатньо прав для перегляду звіту.');
}
$d1 = $_GET['d1'] ?? date('Y-m-d', strtotime('-30 days'));
$d2 = $_GET['d2'] ?? date('Y-m-d');
$rows = [];
$stmt = db()->prepare("SELECT pharmacy_id, SUM(revenue) AS revenue, SUM(checks_cnt) AS checks
                       FROM SalesFactDaily WHERE d >= :d1 AND d < DATE_ADD(:d2, INTERVAL 1 DAY)
                       GROUP BY pharmacy_id ORDER BY revenue DESC");
$stmt->execute([':d1'=>$d1, ':d2'=>$d2]);
$rows = $stmt->fetchAll();

// NEW: Дані для швидкої перевірки (останні продажі)
$recent = db()->query("SELECT s.id, ph.name as pharmacy, s.sold_at, s.total 
                       FROM Sale s JOIN Pharmacy ph ON s.pharmacy_id = ph.id 
                       ORDER BY s.id DESC LIMIT 5")->fetchAll();

render_header('Звіт: виручка');
?>
<h3>Звіт: виручка за період (агреговано)</h3>

<?php if ($recent): ?>
<div style="background: #eef; padding: 10px; border-radius: 5px; margin-bottom: 20px;">
<h4>Останні 5 продажів (перевірка запису в БД):</h4>
<table style="width: 100%; border-collapse: collapse;">
  <thead style="background: #ddd;"><tr><th>ID</th><th>Аптека</th><th>Дата/Час</th><th>Сума</th></tr></thead>
  <tbody>
  <?php foreach ($recent as $r): ?>
    <tr style="border-bottom: 1px solid #ccc;"><td><?=$r['id']?></td><td><?=$r['pharmacy']?></td><td><?=$r['sold_at']?></td><td><?=$r['total']?> грн</td></tr>
  <?php endforeach; ?>
  </tbody>
</table>
</div>
<?php endif; ?>
<form method="get">
  <label>Від <input type="date" name="d1" value="<?=htmlspecialchars($d1)?>"></label>
  <label>До <input type="date" name="d2" value="<?=htmlspecialchars($d2)?>"></label>
  <button type="submit" name="run" value="1">Порахувати</button>
</form>
<?php if ($rows): ?>
<table>
  <thead><tr><th>Pharmacy ID</th><th>Revenue</th><th>Checks</th></tr></thead>
  <tbody>
  <?php foreach ($rows as $r): ?>
    <tr><td><?=$r['pharmacy_id']?></td><td><?=$r['revenue']?></td><td><?=$r['checks']?></td></tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php endif; ?>
<?php render_footer(); ?>
