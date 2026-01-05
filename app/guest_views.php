<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
if (!in_array($_SESSION['db_user'], ['root', 'u_admin', 'u_pharm'])) {
    die('Доступ заборонено: у вас недостатньо прав для перегляду цієї сторінки.');
}
$vb = db()->query("SELECT * FROM v_expiring_batches ORDER BY exp_date LIMIT 50")->fetchAll();
$products = db()->query("SELECT id, name FROM Product ORDER BY name LIMIT 50")->fetchAll();
render_header('Гостьові перегляди');
?>
<h3>Гостьовий перегляд: Партії, що закінчуються (v_expiring_batches)</h3>
<table>
  <thead><tr><th>Товар</th><th>Аптека</th><th>Партія</th><th>К-сть</th><th>Придатний до</th></tr></thead>
  <tbody>
  <?php foreach ($vb as $r): ?>
    <tr>
      <td><?=htmlspecialchars($r['product'])?></td>
      <td><?=htmlspecialchars($r['pharmacy'])?></td>
      <td><?=htmlspecialchars($r['lot_no'])?></td>
      <td><?=$r['qty']?></td>
      <td><?=$r['exp_date']?></td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>

<h3>Довідник: Товари та Партії (для тестування продажу)</h3>
<table>
  <thead><tr><th>Product ID</th><th>Назва</th><th>Batch ID</th><th>Ціна закупівлі</th></tr></thead>
  <tbody>
  <?php 
  $det = db()->query("SELECT p.id as pid, p.name, b.id as bid, b.buy_price 
                      FROM Product p JOIN Batch b ON p.id = b.product_id LIMIT 20")->fetchAll();
  foreach ($det as $d): ?>
    <tr><td><?=$d['pid']?></td><td><?=htmlspecialchars($d['name'])?></td><td><?=$d['bid']?></td><td><?=$d['buy_price']?></td></tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php render_footer(); ?>
