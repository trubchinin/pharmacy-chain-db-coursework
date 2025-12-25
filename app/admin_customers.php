<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
$rows = db()->query("SELECT id, full_name, phone, email, card_id FROM v_customer_secure ORDER BY id LIMIT 100")->fetchAll();
render_header('Адмін: Клієнти');
?>
<h3>Адмін: Клієнти (безпечне відображення PII)</h3>
<table>
  <thead><tr><th>ID</th><th>ПІБ</th><th>Телефон</th><th>Email</th><th>Карта</th></tr></thead>
  <tbody>
  <?php foreach ($rows as $r): ?>
    <tr>
      <td><?=$r['id']?></td>
      <td><?=htmlspecialchars((string)($r['full_name'] ?? ''))?></td>
      <td><?=htmlspecialchars((string)($r['phone'] ?? ''))?></td>
      <td><?=htmlspecialchars((string)($r['email'] ?? ''))?></td>
      <td><?=htmlspecialchars((string)$r['card_id'])?></td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php render_footer(); ?>
