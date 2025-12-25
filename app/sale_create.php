<?php
require __DIR__ . '/lib.php';
ensure_logged_in();
$msg = null; $err = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo = db();
        $pdo->beginTransaction();
        $items = [
            [
              'product_id' => (int)($_POST['product_id'] ?? 0),
              'batch_id'   => (int)($_POST['batch_id'] ?? 0),
              'qty'        => (int)($_POST['qty'] ?? 1),
              'price'      => (float)($_POST['price'] ?? 0),
            ]
        ];
        $json = json_encode($items, JSON_UNESCAPED_UNICODE);
        $stmt = $pdo->prepare("CALL sp_create_sale(:ph, :emp, :cust, :items)");
        $stmt->execute([
            ':ph' => (int)($_POST['pharmacy_id'] ?? 1),
            ':emp'=> (int)($_POST['employee_id'] ?? 1),
            ':cust'=> (int)($_POST['customer_id'] ?? 1),
            ':items'=> $json,
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        // Закриваємо курсор, інакше pending result set завадить наступним запитам
        $stmt->closeCursor();
        $saleId = $row['sale_id'] ?? null;
        $pdo->commit();
        $msg = 'Продаж створено. ID = ' . $saleId;
    } catch (Throwable $e) {
        if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
        $err = $e->getMessage();
    }
}
render_header('Створити продаж');
?>
<h3>Створити продаж (спрощено)</h3>
<?php if ($msg): ?><div style="color:green;"><?=$msg?></div><?php endif; ?>
<?php if ($err): ?><div style="color:red;"><?=$err?></div><?php endif; ?>
<form method="post">
  <fieldset>
    <legend>Заголовок</legend>
    <label>Pharmacy ID <input type="number" name="pharmacy_id" value="1"></label>
    <label>Employee ID <input type="number" name="employee_id" value="1"></label>
    <label>Customer ID <input type="number" name="customer_id" value="1"></label>
  </fieldset>
  <fieldset>
    <legend>Позиція</legend>
    <label>Product ID <input type="number" name="product_id" required></label>
    <label>Batch ID <input type="number" name="batch_id" required></label>
    <label>Qty <input type="number" name="qty" min="1" value="1"></label>
    <label>Price <input type="number" name="price" step="0.01" value="0"></label>
  </fieldset>
  <button type="submit">Створити</button>
</form>
<?php render_footer(); ?>
