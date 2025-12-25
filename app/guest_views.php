<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
$vb = db()->query("SELECT * FROM v_expiring_batches ORDER BY exp_date LIMIT 50")->fetchAll();
$products = db()->query("SELECT id, name FROM Product ORDER BY name LIMIT 50")->fetchAll();
render_header('Гостьові перегляди');
?>
<h3>Гостьовий перегляд: Партії, що закінчуються (v_expiring_batches)</h3>
<table>
  <thead><tr><th>ID</th><th>Product ID</th><th>Lot</th><th>exp</th><th>buy_price</th></tr></thead>
  <tbody>
  <?php foreach ($vb as $r): ?>
    <tr><td><?=$r['id']?></td><td><?=$r['product_id']?></td><td><?=$r['lot_no']?></td><td><?=$r['exp_date']?></td><td><?=$r['buy_price']?></td></tr>
  <?php endforeach; ?>
  </tbody>
</table>

<h3>Гостьовий перегляд: Товари</h3>
<ul>
<?php foreach ($products as $p): ?>
  <li><?=$p['id']?> — <?=htmlspecialchars($p['name'])?></li>
<?php endforeach; ?>
</ul>
<?php render_footer(); ?>
