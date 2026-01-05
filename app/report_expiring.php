<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
if (!in_array($_SESSION['db_user'], ['root', 'u_admin', 'u_pharm'])) {
    die('Доступ заборонено: у вас недостатньо прав для перегляду цієї сторінки.');
}
$rows = [];
$days = (int)($_GET['days'] ?? 365); // за замовчуванням 365 днів для демо
if (isset($_GET['run'])) {
    $stmt = db()->prepare("SELECT ph.name AS pharmacy, p.name AS product, b.lot_no, ps.qty, b.exp_date
                           FROM Batch b
                           JOIN Product p        ON p.id = b.product_id
                           JOIN PharmacyStock ps ON ps.batch_id = b.id
                           JOIN Pharmacy ph      ON ph.id = ps.pharmacy_id
                           WHERE b.exp_date <= DATE_ADD(CURDATE(), INTERVAL :days DAY)
                           ORDER BY b.exp_date");
    $stmt->execute([':days'=>$days]);
    $rows = $stmt->fetchAll();
}
render_header('Партії, що закінчуються');
?>
<h3>Партії, що закінчуються у N днів</h3>
<form method="get">
  <label>Днів <input type="number" name="days" value="<?=htmlspecialchars((string)$days)?>" min="1"></label>
  <button type="submit" name="run" value="1">Показати</button>
  <small>Підказка: для демо оберіть 365, щоб побачити партії з терміном у наступному році.</small>
  </form>
<?php if ($rows): ?>
<table>
  <thead><tr><th>Аптека</th><th>Продукт</th><th>Лот</th><th>Кількість</th><th>Дата</th></tr></thead>
  <tbody>
  <?php foreach ($rows as $r): ?>
    <tr><td><?=$r['pharmacy']?></td><td><?=$r['product']?></td><td><?=$r['lot_no']?></td><td><?=$r['qty']?></td><td><?=$r['exp_date']?></td></tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
<p>Немає партій у вибраному інтервалі. Збільшіть кількість днів або додайте поставки.</p>
<?php endif; ?>
<?php render_footer(); ?>
