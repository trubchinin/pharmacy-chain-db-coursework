<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
$d1 = $_GET['d1'] ?? date('Y-m-01');
$d2 = $_GET['d2'] ?? date('Y-m-t');
$rows = [];
if (isset($_GET['run'])) {
    $stmt = db()->prepare("SELECT pharmacy_id, SUM(revenue) AS revenue, SUM(checks_cnt) AS checks
                           FROM SalesFactDaily WHERE d >= :d1 AND d < DATE_ADD(:d2, INTERVAL 1 DAY)
                           GROUP BY pharmacy_id ORDER BY revenue DESC");
    $stmt->execute([':d1'=>$d1, ':d2'=>$d2]);
    $rows = $stmt->fetchAll();
}
render_header('Звіт: виручка');
?>
<h3>Звіт: виручка за період</h3>
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
