<?php
require __DIR__ . '/lib.php';
$error = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (login($_POST['user'] ?? '', $_POST['pass'] ?? '')) {
            header('Location: index.php');
            exit;
        } else {
            $error = 'Помилка автентифікації';
        }
    } catch (Throwable $e) {
        $error = 'Помилка БД: ' . $e->getMessage();
    }
}
render_header('Вхід');
?>
<h3>Вхід</h3>
<?php if ($error): ?><div style="color:red;"><?=$error?></div><?php endif; ?>
<form method="post">
  <label>Користувач <input name="user" required></label>
  <label>Пароль <input name="pass" type="password" required></label>
  <button type="submit">Увійти</button>
</form>
<?php render_footer(); ?>
