<?php
require __DIR__ . '/lib.php';
if (!isset($_SESSION['db_user'])) { header('Location: /login.php'); exit; }
render_header('ЛР7: Головна');
?>
<h3>Вітаю, <?=htmlspecialchars($_SESSION['db_user'])?>!</h3>
<p>Поточна роль: <?=htmlspecialchars($_SESSION['db_role'] ?? 'N/A')?>.</p>
<ul>
  <li><a href="/report_revenue.php">Звіт: виручка за період</a></li>
  <li><a href="/report_expiring.php">Партії з терміном ≤30 днів</a></li>
  <li><a href="/sale_create.php">Створити продаж</a></li>
</ul>
<?php render_footer(); ?>
