<?php
declare(strict_types=1);
require __DIR__ . '/config.php';
ob_start();

$action = $_GET['action'] ?? 'bootstrap';
$input = request_body();

try {
    match ($action) {
        'bootstrap' => bootstrap(),
        'login' => login($input),
        'save_vehicle' => save_vehicle($input),
        'save_employee' => save_employee($input),
        'save_store' => save_store($input),
        'toggle_employee_freeze' => toggle_employee_freeze($input),
        'delete_employee' => delete_employee($input),
        'delete_vehicle' => delete_vehicle($input),
        'save_invoice' => save_invoice($input),
        'update_sale_status' => update_sale_status($input),
        'mark_emi_paid' => mark_emi_paid($input),
        default => json_response(['ok' => false, 'error' => 'Unknown action']),
    };
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()]);
}

function bootstrap(): void {
    $pdo = db();
    ensure_schema($pdo);
    $stores = $pdo->query("
        SELECT s.id, s.name, s.location, s.tier, s.performance_rating AS rating,
        COALESCE(COUNT(sa.id), 0) AS units,
        COALESCE(SUM(sa.amount_lakh), 0) AS revenue
        FROM stores s
        LEFT JOIN sales sa ON sa.store_id = s.id
        GROUP BY s.id
        ORDER BY s.id
    ")->fetchAll();

    $employees = $pdo->query("
        SELECT u.emp_id, u.name, u.username, u.password, u.role, u.shift, u.active, u.frozen,
        COALESCE(s.name, 'All Showrooms') AS branch,
        COUNT(sa.id) AS closed,
        COALESCE(SUM(sa.amount_lakh), 0) AS revenue
        FROM users u
        LEFT JOIN stores s ON s.id = u.store_id
        LEFT JOIN sales sa ON sa.employee_id = u.id
        WHERE u.user_type = 'staff'
        GROUP BY u.id
        ORDER BY u.id
    ")->fetchAll();

    $bikes = $pdo->query("
        SELECT b.id, b.name, b.brand, b.category, b.stock_units AS stock, b.sold_units AS sold,
        b.showroom_price AS price, b.purchase_cost, b.gst_percent, b.margin_percent,
        b.price_unit, b.cost_unit, b.display_status AS status, b.chassis_vin, b.engine_serial,
        b.plate, b.color_scheme, b.odometer, b.fuel_model, b.model_year, b.registration_state,
        b.media_name, b.media_type, b.media_data, b.last_service_date, b.owner, b.insurance, b.low_threshold, b.created_at,
        COALESCE(s.name, 'Unassigned') AS showroom, COALESCE(u.name, '') AS created_by
        FROM bikes b
        LEFT JOIN stores s ON s.id = b.store_id
        LEFT JOIN users u ON u.id = b.created_by
        ORDER BY b.id DESC
    ")->fetchAll();

    $sales = $pdo->query("
        SELECT sa.id AS sale_db_id, sa.transaction_id, sa.customer_name AS customer, sa.phone, sa.bike_name AS bike,
        sa.amount_lakh AS amount, sa.status, sa.payment_status AS payment, sa.payment_mode AS mode,
        sa.gst_percent, sa.discount_lakh, COALESCE(st.name, 'Unassigned') AS branch,
        COALESCE(u.name, 'Network Admin') AS employee, COALESCE(u.emp_id, '') AS employee_emp_id,
        sa.sale_date, bi.id AS invoice_id, bi.invoice_number, bi.transaction_type, bi.booking,
        bi.customer_type, bi.email, bi.address, bi.city, bi.state_name, bi.pincode, bi.id_type, bi.id_reference,
        bi.id_proof_file_name, bi.customer_gstin, bi.customer_pan,
        bi.relation_name, bi.bill_to_address, bi.delivery_address, bi.bike_id, bi.category, bi.color, bi.vin, bi.engine,
        bi.model_year, bi.fuel_type, bi.odometer, bi.showroom_price_lakh, bi.quantity, bi.accessories_lakh, bi.insurance_lakh,
        bi.registration_lakh, bi.handling_lakh, bi.logistics_lakh, bi.extended_warranty_lakh, bi.other_charges_lakh,
        bi.subtotal_lakh, bi.discount_type, bi.discount_value, bi.taxable_lakh, bi.gst_amount_lakh, bi.cgst_percent,
        bi.cgst_lakh, bi.sgst_percent, bi.sgst_lakh, bi.round_off_lakh, bi.grand_total_lakh, bi.payment_reference,
        bi.payment_date, bi.amount_paid_lakh, bi.balance_lakh, bi.booking_number, bi.booking_amount_lakh, bi.booking_date,
        bi.expected_delivery_date, bi.booking_status, bi.finance_required, bi.finance_provider, bi.loan_amount_lakh,
        bi.loan_application_number, bi.loan_account_number, bi.down_payment_lakh, bi.loan_tenure_months,
        bi.interest_rate_percent, bi.finance_status, bi.emi_amount_lakh, bi.emi_start_date, bi.emi_due_date,
        bi.emi_due_day, bi.emi_frequency, bi.number_of_emis, bi.emis_paid, bi.remaining_emis, bi.emi_status, bi.next_emi_due_date,
        bi.delivery_status, bi.actual_delivery_date, bi.delivery_location,
        bi.sales_executive, bi.created_at AS invoice_created_at, b.media_data AS bike_media_data, b.media_type AS bike_media_type,
        b.media_name AS bike_media_name
        FROM sales sa
        LEFT JOIN stores st ON st.id = sa.store_id
        LEFT JOIN users u ON u.id = sa.employee_id
        LEFT JOIN billing_invoices bi ON bi.sale_id = sa.id OR bi.invoice_number = sa.transaction_id
        LEFT JOIN bikes b ON b.id = bi.bike_id
        ORDER BY sa.sale_date DESC, sa.id DESC
    ")->fetchAll();

    $historyRows = $pdo->query("
        SELECT h.sale_id, h.status, h.notes, h.changed_at, COALESCE(u.name, 'System') AS changed_by
        FROM sale_status_history h
        LEFT JOIN users u ON u.id = h.changed_by
        ORDER BY h.changed_at ASC, h.id ASC
    ")->fetchAll();
    $historyBySale = [];
    foreach ($historyRows as $row) {
        $historyBySale[(int)$row['sale_id']][] = $row;
    }
    foreach ($sales as &$sale) {
        $sale['status_history'] = $historyBySale[(int)$sale['sale_db_id']] ?? [];
    }
    unset($sale);

    $paymentRows = $pdo->query("
        SELECT p.invoice_id, p.sale_id, p.booking_number, p.payment_type, p.payment_mode, p.amount_lakh,
        p.reference, p.payment_date, p.created_at, COALESCE(u.name, 'System') AS employee
        FROM billing_payments p
        LEFT JOIN users u ON u.id = p.employee_id
        ORDER BY COALESCE(p.payment_date, DATE(p.created_at)) ASC, p.id ASC
    ")->fetchAll();
    $paymentsByInvoice = [];
    $paymentsBySale = [];
    foreach ($paymentRows as $row) {
        if (!empty($row['invoice_id'])) {
            $paymentsByInvoice[(int)$row['invoice_id']][] = $row;
        }
        if (!empty($row['sale_id'])) {
            $paymentsBySale[(int)$row['sale_id']][] = $row;
        }
    }
    foreach ($sales as &$sale) {
        $sale['payment_history'] = $paymentsByInvoice[(int)($sale['invoice_id'] ?? 0)] ?? $paymentsBySale[(int)$sale['sale_db_id']] ?? [];
    }
    unset($sale);

    json_response(['ok' => true, 'stores' => $stores, 'employees' => $employees, 'bikes' => $bikes, 'sales' => $sales]);
}

function ensure_schema(PDO $pdo): void {
    $storeColumns = $pdo->query('SHOW COLUMNS FROM stores')->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('location', $storeColumns, true)) {
        exec_schema_change($pdo, 'ALTER TABLE stores ADD COLUMN location VARCHAR(180) DEFAULT NULL AFTER name');
    }
    $pdo->exec("
        UPDATE stores SET location = CASE name
            WHEN 'Vizag Showroom' THEN 'Visakhapatnam'
            WHEN 'Hyderabad Center' THEN 'Hyderabad'
            WHEN 'Vijayawada Hub' THEN 'Vijayawada'
            WHEN 'Guntur Outlet' THEN 'Guntur'
            ELSE location
        END
        WHERE location IS NULL OR location = ''
    ");
    $userColumns = $pdo->query('SHOW COLUMNS FROM users')->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('frozen', $userColumns, true)) {
        exec_schema_change($pdo, 'ALTER TABLE users ADD COLUMN frozen TINYINT(1) NOT NULL DEFAULT 0 AFTER active');
    }
    $columns = $pdo->query('SHOW COLUMNS FROM bikes')->fetchAll(PDO::FETCH_COLUMN);
    $add = [
        'brand' => 'ALTER TABLE bikes ADD COLUMN brand VARCHAR(120) DEFAULT NULL AFTER name',
        'margin_percent' => 'ALTER TABLE bikes ADD COLUMN margin_percent DECIMAL(7,2) NOT NULL DEFAULT 0 AFTER gst_percent',
        'price_unit' => "ALTER TABLE bikes ADD COLUMN price_unit VARCHAR(20) NOT NULL DEFAULT 'lakhs' AFTER showroom_price",
        'cost_unit' => "ALTER TABLE bikes ADD COLUMN cost_unit VARCHAR(20) NOT NULL DEFAULT 'lakhs' AFTER purchase_cost",
        'media_name' => 'ALTER TABLE bikes ADD COLUMN media_name VARCHAR(180) DEFAULT NULL AFTER registration_state',
        'media_type' => 'ALTER TABLE bikes ADD COLUMN media_type VARCHAR(80) DEFAULT NULL AFTER media_name',
        'media_data' => 'ALTER TABLE bikes ADD COLUMN media_data LONGTEXT DEFAULT NULL AFTER media_type',
        'last_service_date' => 'ALTER TABLE bikes ADD COLUMN last_service_date DATE DEFAULT NULL AFTER media_name',
        'owner' => "ALTER TABLE bikes ADD COLUMN owner VARCHAR(140) NOT NULL DEFAULT 'Motorstock Network' AFTER last_service_date",
        'insurance' => "ALTER TABLE bikes ADD COLUMN insurance VARCHAR(140) NOT NULL DEFAULT 'Active' AFTER owner",
        'low_threshold' => 'ALTER TABLE bikes ADD COLUMN low_threshold INT NOT NULL DEFAULT 2 AFTER insurance',
        'created_by' => 'ALTER TABLE bikes ADD COLUMN created_by INT NULL AFTER store_id',
    ];
    foreach ($add as $column => $sql) {
        if (!in_array($column, $columns, true)) {
            exec_schema_change($pdo, $sql);
        }
    }
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS billing_invoices (
          id INT AUTO_INCREMENT PRIMARY KEY,
          invoice_number VARCHAR(60) NOT NULL UNIQUE,
          transaction_type VARCHAR(40) NOT NULL,
          booking VARCHAR(10) NOT NULL DEFAULT 'No',
          customer_name VARCHAR(140) NOT NULL,
          phone VARCHAR(40) NOT NULL,
          email VARCHAR(140) DEFAULT NULL,
          address TEXT DEFAULT NULL,
          city VARCHAR(80) DEFAULT NULL,
          state_name VARCHAR(80) DEFAULT NULL,
          pincode VARCHAR(20) DEFAULT NULL,
          id_type VARCHAR(60) DEFAULT NULL,
          id_reference VARCHAR(120) DEFAULT NULL,
          id_proof_file_name VARCHAR(180) DEFAULT NULL,
          id_proof_file_data LONGTEXT DEFAULT NULL,
          bike_id INT NULL,
          bike_name VARCHAR(160) NOT NULL,
          category VARCHAR(80) DEFAULT NULL,
          color VARCHAR(100) DEFAULT NULL,
          vin VARCHAR(100) DEFAULT NULL,
          engine VARCHAR(100) DEFAULT NULL,
          model_year VARCHAR(12) DEFAULT NULL,
          fuel_type VARCHAR(40) DEFAULT NULL,
          odometer VARCHAR(80) DEFAULT NULL,
          showroom_price_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          accessories_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          insurance_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          registration_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          handling_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          other_charges_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          subtotal_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          discount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          gst_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
          gst_amount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          grand_total_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          payment_status VARCHAR(80) NOT NULL,
          payment_mode VARCHAR(100) NOT NULL,
          amount_paid_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          balance_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          booking_amount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          expected_delivery_date DATE DEFAULT NULL,
          booking_status VARCHAR(80) DEFAULT NULL,
          finance_status VARCHAR(80) DEFAULT NULL,
          emi_amount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          emi_start_date DATE DEFAULT NULL,
          emi_due_date DATE DEFAULT NULL,
          emi_frequency VARCHAR(40) NOT NULL DEFAULT 'Monthly',
          number_of_emis INT NOT NULL DEFAULT 0,
          remaining_emis INT NOT NULL DEFAULT 0,
          next_emi_due_date DATE DEFAULT NULL,
          store_id INT NULL,
          employee_id INT NULL,
          sale_id INT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (bike_id) REFERENCES bikes(id) ON DELETE SET NULL,
          FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE SET NULL,
          FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE SET NULL,
          FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL
        )
    ");
    $billingColumns = $pdo->query('SHOW COLUMNS FROM billing_invoices')->fetchAll(PDO::FETCH_COLUMN);
    $billingAdd = [
        'customer_type' => "ALTER TABLE billing_invoices ADD COLUMN customer_type VARCHAR(40) NOT NULL DEFAULT 'Individual' AFTER transaction_type",
        'booking' => "ALTER TABLE billing_invoices ADD COLUMN booking VARCHAR(10) NOT NULL DEFAULT 'No' AFTER transaction_type",
        'id_proof_file_name' => 'ALTER TABLE billing_invoices ADD COLUMN id_proof_file_name VARCHAR(180) DEFAULT NULL AFTER id_reference',
        'id_proof_file_data' => 'ALTER TABLE billing_invoices ADD COLUMN id_proof_file_data LONGTEXT DEFAULT NULL AFTER id_proof_file_name',
        'customer_gstin' => 'ALTER TABLE billing_invoices ADD COLUMN customer_gstin VARCHAR(40) DEFAULT NULL AFTER id_reference',
        'customer_pan' => 'ALTER TABLE billing_invoices ADD COLUMN customer_pan VARCHAR(40) DEFAULT NULL AFTER customer_gstin',
        'relation_name' => 'ALTER TABLE billing_invoices ADD COLUMN relation_name VARCHAR(140) DEFAULT NULL AFTER customer_pan',
        'bill_to_address' => 'ALTER TABLE billing_invoices ADD COLUMN bill_to_address TEXT DEFAULT NULL AFTER relation_name',
        'delivery_address' => 'ALTER TABLE billing_invoices ADD COLUMN delivery_address TEXT DEFAULT NULL AFTER bill_to_address',
        'quantity' => 'ALTER TABLE billing_invoices ADD COLUMN quantity INT NOT NULL DEFAULT 1 AFTER showroom_price_lakh',
        'logistics_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN logistics_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER handling_lakh',
        'extended_warranty_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN extended_warranty_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER logistics_lakh',
        'discount_type' => "ALTER TABLE billing_invoices ADD COLUMN discount_type VARCHAR(40) NOT NULL DEFAULT 'None' AFTER subtotal_lakh",
        'discount_value' => 'ALTER TABLE billing_invoices ADD COLUMN discount_value DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER discount_type',
        'taxable_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN taxable_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER discount_lakh',
        'cgst_percent' => 'ALTER TABLE billing_invoices ADD COLUMN cgst_percent DECIMAL(5,2) NOT NULL DEFAULT 0 AFTER gst_amount_lakh',
        'cgst_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN cgst_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER cgst_percent',
        'sgst_percent' => 'ALTER TABLE billing_invoices ADD COLUMN sgst_percent DECIMAL(5,2) NOT NULL DEFAULT 0 AFTER cgst_lakh',
        'sgst_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN sgst_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER sgst_percent',
        'round_off_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN round_off_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER sgst_lakh',
        'payment_reference' => 'ALTER TABLE billing_invoices ADD COLUMN payment_reference VARCHAR(160) DEFAULT NULL AFTER payment_mode',
        'payment_date' => 'ALTER TABLE billing_invoices ADD COLUMN payment_date DATE DEFAULT NULL AFTER payment_reference',
        'booking_number' => 'ALTER TABLE billing_invoices ADD COLUMN booking_number VARCHAR(60) DEFAULT NULL AFTER balance_lakh',
        'booking_date' => 'ALTER TABLE billing_invoices ADD COLUMN booking_date DATE DEFAULT NULL AFTER booking_amount_lakh',
        'finance_required' => "ALTER TABLE billing_invoices ADD COLUMN finance_required VARCHAR(10) NOT NULL DEFAULT 'No' AFTER booking_status",
        'finance_provider' => 'ALTER TABLE billing_invoices ADD COLUMN finance_provider VARCHAR(140) DEFAULT NULL AFTER finance_required',
        'loan_amount_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN loan_amount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER finance_provider',
        'loan_application_number' => 'ALTER TABLE billing_invoices ADD COLUMN loan_application_number VARCHAR(120) DEFAULT NULL AFTER loan_amount_lakh',
        'loan_account_number' => 'ALTER TABLE billing_invoices ADD COLUMN loan_account_number VARCHAR(120) DEFAULT NULL AFTER loan_application_number',
        'down_payment_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN down_payment_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER loan_account_number',
        'loan_tenure_months' => 'ALTER TABLE billing_invoices ADD COLUMN loan_tenure_months INT NOT NULL DEFAULT 0 AFTER down_payment_lakh',
        'interest_rate_percent' => 'ALTER TABLE billing_invoices ADD COLUMN interest_rate_percent DECIMAL(6,2) NOT NULL DEFAULT 0 AFTER loan_tenure_months',
        'emi_amount_lakh' => 'ALTER TABLE billing_invoices ADD COLUMN emi_amount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER finance_status',
        'emi_start_date' => 'ALTER TABLE billing_invoices ADD COLUMN emi_start_date DATE DEFAULT NULL AFTER emi_amount_lakh',
        'emi_due_date' => 'ALTER TABLE billing_invoices ADD COLUMN emi_due_date DATE DEFAULT NULL AFTER emi_start_date',
        'emi_due_day' => 'ALTER TABLE billing_invoices ADD COLUMN emi_due_day INT NOT NULL DEFAULT 0 AFTER emi_due_date',
        'emi_frequency' => "ALTER TABLE billing_invoices ADD COLUMN emi_frequency VARCHAR(40) NOT NULL DEFAULT 'Monthly' AFTER emi_due_date",
        'number_of_emis' => 'ALTER TABLE billing_invoices ADD COLUMN number_of_emis INT NOT NULL DEFAULT 0 AFTER emi_frequency',
        'emis_paid' => 'ALTER TABLE billing_invoices ADD COLUMN emis_paid INT NOT NULL DEFAULT 0 AFTER number_of_emis',
        'remaining_emis' => 'ALTER TABLE billing_invoices ADD COLUMN remaining_emis INT NOT NULL DEFAULT 0 AFTER number_of_emis',
        'emi_status' => "ALTER TABLE billing_invoices ADD COLUMN emi_status VARCHAR(40) NOT NULL DEFAULT 'Upcoming' AFTER remaining_emis",
        'next_emi_due_date' => 'ALTER TABLE billing_invoices ADD COLUMN next_emi_due_date DATE DEFAULT NULL AFTER remaining_emis',
        'delivery_status' => "ALTER TABLE billing_invoices ADD COLUMN delivery_status VARCHAR(80) NOT NULL DEFAULT 'Pending' AFTER finance_status",
        'actual_delivery_date' => 'ALTER TABLE billing_invoices ADD COLUMN actual_delivery_date DATE DEFAULT NULL AFTER delivery_status',
        'delivery_location' => 'ALTER TABLE billing_invoices ADD COLUMN delivery_location VARCHAR(160) DEFAULT NULL AFTER actual_delivery_date',
        'sales_executive' => 'ALTER TABLE billing_invoices ADD COLUMN sales_executive VARCHAR(140) DEFAULT NULL AFTER delivery_location',
        'updated_at' => 'ALTER TABLE billing_invoices ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
    ];
    foreach ($billingAdd as $column => $sql) {
        if (!in_array($column, $billingColumns, true)) {
            exec_schema_change($pdo, $sql);
        }
    }
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS sale_status_history (
          id INT AUTO_INCREMENT PRIMARY KEY,
          sale_id INT NOT NULL,
          status VARCHAR(80) NOT NULL,
          notes VARCHAR(255) DEFAULT NULL,
          changed_by INT NULL,
          changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
          FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL
        )
    ");
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS billing_payments (
          id INT AUTO_INCREMENT PRIMARY KEY,
          invoice_id INT NOT NULL,
          sale_id INT NULL,
          booking_number VARCHAR(60) DEFAULT NULL,
          customer_name VARCHAR(140) NOT NULL,
          bike_id INT NULL,
          store_id INT NULL,
          employee_id INT NULL,
          payment_type VARCHAR(80) NOT NULL,
          payment_mode VARCHAR(100) NOT NULL,
          amount_lakh DECIMAL(10,2) NOT NULL DEFAULT 0,
          reference VARCHAR(160) DEFAULT NULL,
          payment_date DATE DEFAULT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (invoice_id) REFERENCES billing_invoices(id) ON DELETE CASCADE,
          FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL,
          FOREIGN KEY (bike_id) REFERENCES bikes(id) ON DELETE SET NULL,
          FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE SET NULL,
          FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE SET NULL
        )
    ");
}

function exec_schema_change(PDO $pdo, string $sql): void {
    try {
        $pdo->exec($sql);
    } catch (PDOException $e) {
        if (($e->errorInfo[1] ?? null) === 1060) {
            return;
        }
        throw $e;
    }
}

function user_id_by_username(?string $username): ?int {
    if (!$username) {
        return null;
    }
    $stmt = db()->prepare('SELECT id FROM users WHERE username = ? OR name = ? LIMIT 1');
    $stmt->execute([$username, $username]);
    $id = $stmt->fetchColumn();
    return $id ? (int)$id : null;
}

function login(array $input): void {
    $username = trim((string)($input['username'] ?? ''));
    $password = trim((string)($input['password'] ?? ''));
    $pdo = db();
    ensure_schema($pdo);
    $stmt = $pdo->prepare("
        SELECT u.id, u.emp_id, u.name, u.username, u.password, u.user_type AS type, u.role, u.shift, u.frozen,
        COALESCE(s.name, 'All Showrooms') AS branch
        FROM users u
        LEFT JOIN stores s ON s.id = u.store_id
        WHERE u.username = ? AND u.password = ?
    ");
    $stmt->execute([$username, $password]);
    $user = $stmt->fetch();
    if (!$user) {
        json_response(['ok' => false, 'error' => 'Invalid database login.']);
    }
    if ($user['type'] === 'staff' && (int)($user['frozen'] ?? 0) === 1) {
        json_response(['ok' => false, 'error' => 'This employee account is frozen. Contact admin to resume access.']);
    }
    if ($user['type'] === 'staff' && !within_shift((string)$user['shift'])) {
        json_response(['ok' => false, 'error' => 'Staff can login only inside assigned shift timing.']);
    }
    $pdo->prepare('UPDATE users SET active = 1 WHERE id = ?')->execute([$user['id']]);
    json_response(['ok' => true, 'user' => $user]);
}

function update_sale_status(array $input): void {
    $pdo = db();
    ensure_schema($pdo);
    $username = (string)($input['username'] ?? '');
    $stmt = $pdo->prepare('SELECT id, user_type FROM users WHERE username = ? OR emp_id = ? LIMIT 1');
    $stmt->execute([$username, (string)($input['user_id'] ?? '')]);
    $user = $stmt->fetch();
    if (!$user || !in_array($user['user_type'], ['admin', 'staff'], true)) {
        json_response(['ok' => false, 'error' => 'Only showroom users can update transaction status.']);
    }
    $status = trim((string)($input['status'] ?? ''));
    $allowed = ['Pending', 'Booking Confirmed', 'Payment Completed', 'Balance Pending', 'Documents Pending', 'Documents Submitted', 'Under Verification', 'Payment Processed', 'Down Payment', 'Partially Paid', 'Paid', 'Pending Finance', 'Finance Pending', 'Finance Approved', 'Loan Disbursed', 'EMI Active', 'Vehicle Allocated', 'Processing', 'PDI Scheduled', 'PDI Completed', 'Registration In Process', 'Registration Completed', 'Delivery Scheduled', 'Delivered', 'Cancelled'];
    if (!in_array($status, $allowed, true)) {
        json_response(['ok' => false, 'error' => 'Invalid transaction status.']);
    }
    $transactionId = trim((string)($input['transaction_id'] ?? ''));
    if ($transactionId === '') {
        json_response(['ok' => false, 'error' => 'Transaction id is required.']);
    }
    $sale = $pdo->prepare('SELECT id FROM sales WHERE transaction_id = ? LIMIT 1');
    $sale->execute([$transactionId]);
    $saleId = $sale->fetchColumn();
    if (!$saleId) {
        json_response(['ok' => false, 'error' => 'Transaction was not found.']);
    }
    $stageDate = trim((string)($input['stage_date'] ?? ''));
    if ($stageDate !== '') {
        $date = DateTime::createFromFormat('Y-m-d', $stageDate);
        if (!$date || $date->format('Y-m-d') !== $stageDate) {
            json_response(['ok' => false, 'error' => 'Stage date must use YYYY-MM-DD format.']);
        }
    }
    $stageAmount = rupees_to_lakhs($input['stage_amount'] ?? 0);
    $pdo->beginTransaction();
    try {
        $pdo->prepare('UPDATE sales SET status = ? WHERE id = ?')->execute([$status, $saleId]);
        if ($stageAmount > 0) {
            $invoiceStmt = $pdo->prepare('
                SELECT bi.*, s.transaction_id
                FROM billing_invoices bi
                INNER JOIN sales s ON s.id = bi.sale_id
                WHERE bi.sale_id = ?
                LIMIT 1
                FOR UPDATE
            ');
            $invoiceStmt->execute([$saleId]);
            $invoice = $invoiceStmt->fetch();
            if (!$invoice) {
                throw new RuntimeException('Invoice was not found for this payment.');
            }
            $currentBalance = (float)($invoice['balance_lakh'] ?? 0);
            if ($stageAmount > $currentBalance + 0.00001) {
                throw new RuntimeException('Stage payment cannot exceed current balance.');
            }
            $newPaid = (float)($invoice['amount_paid_lakh'] ?? 0) + $stageAmount;
            $newBalance = max($currentBalance - $stageAmount, 0);
            $paymentStatus = $newBalance <= 0.00001 ? 'Fully Paid' : (preg_match('/down/i', $status) ? 'Down Payment' : 'Partially Paid');
            $paidDate = $stageDate ?: date('Y-m-d');
            $reference = trim((string)($input['payment_reference'] ?? '')) ?: ($status . ' on ' . $paidDate);
            $insertPayment = $pdo->prepare('
                INSERT INTO billing_payments (invoice_id, sale_id, booking_number, customer_name, bike_id, store_id, employee_id, payment_type, payment_mode, amount_lakh, reference, payment_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ');
            $insertPayment->execute([
                (int)$invoice['id'],
                (int)$invoice['sale_id'],
                $invoice['booking_number'],
                $invoice['customer_name'],
                $invoice['bike_id'],
                $invoice['store_id'],
                $user['id'],
                preg_match('/emi/i', $status) ? 'EMI Payment' : 'Stage Payment',
                $input['payment_mode'] ?? ($invoice['payment_mode'] ?? 'UPI'),
                $stageAmount,
                $reference,
                $paidDate,
            ]);
            $pdo->prepare('UPDATE billing_invoices SET amount_paid_lakh = ?, balance_lakh = ?, payment_status = ?, payment_date = ? WHERE id = ?')
                ->execute([$newPaid, $newBalance, $paymentStatus, $paidDate, (int)$invoice['id']]);
            $pdo->prepare('UPDATE sales SET payment_status = ? WHERE id = ?')
                ->execute([$paymentStatus, $saleId]);
        }
        $deliveryStatuses = ['Processing', 'PDI Scheduled', 'PDI Completed', 'Registration In Process', 'Registration Completed', 'Delivery Scheduled', 'Delivered', 'Cancelled'];
        if (in_array($status, $deliveryStatuses, true)) {
            $pdo->prepare('UPDATE billing_invoices SET delivery_status = ? WHERE sale_id = ?')->execute([$status, $saleId]);
        }
        if ($stageDate !== '') {
            if (in_array($status, ['Payment Processed', 'Payment Completed', 'Down Payment', 'Partially Paid', 'Balance Pending', 'Paid'], true)) {
                $pdo->prepare('UPDATE billing_invoices SET payment_date = ? WHERE sale_id = ?')->execute([$stageDate, $saleId]);
                if ($stageAmount <= 0) {
                    $paymentStatus = match ($status) {
                        'Down Payment' => 'Down Payment',
                        'Partially Paid', 'Balance Pending' => 'Partially Paid',
                        default => 'Fully Paid',
                    };
                    $pdo->prepare('UPDATE sales SET payment_status = ? WHERE id = ?')->execute([$paymentStatus, $saleId]);
                    $pdo->prepare('UPDATE billing_invoices SET payment_status = ? WHERE sale_id = ?')->execute([$paymentStatus, $saleId]);
                }
            }
            if (in_array($status, ['Documents Pending', 'Documents Submitted', 'Under Verification', 'Finance Pending', 'Finance Approved', 'Loan Disbursed', 'EMI Active'], true)) {
                $pdo->prepare('UPDATE billing_invoices SET finance_status = ? WHERE sale_id = ?')->execute([$status, $saleId]);
                $paymentStatus = match ($status) {
                    'Finance Approved' => 'Finance Approved',
                    'Loan Disbursed' => 'Loan Disbursed',
                    'EMI Active' => 'EMI Active',
                    default => 'Finance Pending',
                };
                $pdo->prepare('UPDATE sales SET payment_status = ? WHERE id = ?')->execute([$paymentStatus, $saleId]);
                $pdo->prepare('UPDATE billing_invoices SET payment_status = ? WHERE sale_id = ?')->execute([$paymentStatus, $saleId]);
            }
            if ($status === 'Delivery Scheduled') {
                $pdo->prepare('UPDATE billing_invoices SET expected_delivery_date = ?, delivery_status = ? WHERE sale_id = ?')->execute([$stageDate, $status, $saleId]);
            }
            if ($status === 'Delivered') {
                $pdo->prepare('UPDATE billing_invoices SET actual_delivery_date = ?, delivery_status = ? WHERE sale_id = ?')->execute([$stageDate, $status, $saleId]);
            }
        }
        $historySql = $stageDate === ''
            ? 'INSERT INTO sale_status_history (sale_id, status, notes, changed_by) VALUES (?, ?, ?, ?)'
            : "INSERT INTO sale_status_history (sale_id, status, notes, changed_by, changed_at) VALUES (?, ?, ?, ?, CONCAT(?, ' ', CURRENT_TIME()))";
        $historyParams = [
            $saleId,
            $status,
            $input['notes'] ?? 'Status updated from Sales page',
            $user['id'],
        ];
        if ($stageDate !== '') {
            $historyParams[] = $stageDate;
        }
        $pdo->prepare($historySql)->execute($historyParams);
        $pdo->commit();
        json_response(['ok' => true]);
    } catch (Throwable $e) {
        $pdo->rollBack();
        throw $e;
    }
}

function within_shift(string $shift): bool {
    $hour = (int)(new DateTime('now', new DateTimeZone('Asia/Kolkata')))->format('G');
    return $shift === 'A' ? ($hour >= 10 && $hour < 15) : ($hour >= 16 && $hour < 21);
}

function store_id(string $name): ?int {
    $stmt = db()->prepare('SELECT id FROM stores WHERE name = ?');
    $stmt->execute([$name]);
    $id = $stmt->fetchColumn();
    return $id ? (int)$id : null;
}

function inventory_actor(array $input): ?array {
    $username = trim((string)($input['username'] ?? $input['created_by'] ?? ''));
    $userId = trim((string)($input['user_id'] ?? ''));
    if ($username === '' && $userId === '') {
        return null;
    }
    $stmt = db()->prepare('SELECT id, user_type, store_id FROM users WHERE username = ? OR emp_id = ? OR name = ? LIMIT 1');
    $stmt->execute([$username, $userId, $username]);
    $user = $stmt->fetch();
    return $user ?: null;
}

function assert_inventory_permission(PDO $pdo, array $input, ?int $vehicleStoreId = null): void {
    $user = inventory_actor($input);
    if (!$user) {
        json_response(['ok' => false, 'error' => 'Authorized user is required for inventory changes.']);
    }
    if ($user['user_type'] === 'admin') {
        return;
    }
    if ((int)$user['store_id'] <= 0 || (int)$vehicleStoreId !== (int)$user['store_id']) {
        json_response(['ok' => false, 'error' => 'Employees can edit inventory only for their assigned showroom.']);
    }
}

function save_vehicle(array $input): void {
    $pdo = db();
    ensure_schema($pdo);
    $storeId = store_id((string)($input['showroom'] ?? ''));
    assert_inventory_permission($pdo, $input, $storeId);
    $values = [
        $input['model_name'] ?? $input['brand'] ?? '',
        $input['brand'] ?? '',
        $input['category'] ?? '',
        $input['price'] ?? 0,
        $input['price_unit'] ?? 'lakhs',
        $input['cost'] ?? 0,
        $input['cost_unit'] ?? 'lakhs',
        $input['tax'] ?? 0,
        $input['margin'] ?? 0,
        $input['percent'] ?? 0,
        $input['total'] ?? $input['units'] ?? 0,
        $input['display'] ?? 'In Stock',
        $input['vin'] ?? '',
        $input['engine'] ?? '',
        $input['plate'] ?? '',
        $input['color'] ?? '',
        $input['odo'] ?? '',
        $input['fuel'] ?? '',
        $input['year'] ?? '',
        $input['state'] ?? '',
        $input['media_name'] ?? '',
        $input['media_type'] ?? '',
        $input['media_data'] ?? '',
        ($input['service'] ?? '') ?: null,
        $input['owner'] ?? 'Motorstock Network',
        $input['insurance'] ?? 'Active',
        $input['low'] ?? 2,
        $storeId,
        user_id_by_username((string)($input['created_by'] ?? '')),
    ];
    if (!empty($input['id'])) {
        $existing = $pdo->prepare('SELECT store_id FROM bikes WHERE id = ?');
        $existing->execute([(int)$input['id']]);
        $existingStoreId = $existing->fetchColumn();
        assert_inventory_permission($pdo, $input, $existingStoreId ? (int)$existingStoreId : null);
        $stmt = $pdo->prepare("
            UPDATE bikes SET name = ?, brand = ?, category = ?, showroom_price = ?, price_unit = ?, purchase_cost = ?,
            cost_unit = ?, gst_percent = ?, margin_percent = ?, discount_percent = ?, stock_units = ?,
            display_status = ?, chassis_vin = ?, engine_serial = ?, plate = ?, color_scheme = ?, odometer = ?,
            fuel_model = ?, model_year = ?, registration_state = ?, media_name = ?, media_type = ?, media_data = ?, last_service_date = ?,
            owner = ?, insurance = ?, low_threshold = ?, store_id = ?, created_by = COALESCE(?, created_by) WHERE id = ?
        ");
        $values[] = (int)$input['id'];
        $stmt->execute($values);
    } else {
        $stmt = $pdo->prepare("
            INSERT INTO bikes (name, brand, category, showroom_price, price_unit, purchase_cost, cost_unit, gst_percent,
            margin_percent, discount_percent, stock_units, display_status, chassis_vin, engine_serial, plate,
            color_scheme, odometer, fuel_model, model_year, registration_state, media_name, media_type, media_data, last_service_date,
            owner, insurance, low_threshold, store_id, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute($values);
    }
    json_response(['ok' => true]);
}

function save_store(array $input): void {
    $name = trim((string)($input['name'] ?? ''));
    $location = trim((string)($input['location'] ?? ''));
    if ($name === '') {
        json_response(['ok' => false, 'error' => 'Showroom name is required.']);
    }
    $stmt = db()->prepare('INSERT INTO stores (name, location, tier, performance_rating) VALUES (?, ?, "Silver", 70)');
    $stmt->execute([$name, $location]);
    json_response(['ok' => true]);
}

function save_employee(array $input): void {
    $storeId = store_id((string)($input['branch'] ?? ''));
    $existing = db()->prepare('SELECT id FROM users WHERE emp_id = ?');
    $existing->execute([$input['id'] ?? '']);
    $id = $existing->fetchColumn();
    if ($id) {
        $stmt = db()->prepare('UPDATE users SET name = ?, username = ?, password = ?, shift = ?, role = ?, store_id = ? WHERE emp_id = ?');
        $stmt->execute([$input['name'] ?? '', $input['username'] ?? '', $input['password'] ?? '', $input['shift'] ?? 'A', $input['role'] ?? '', $storeId, $input['id'] ?? '']);
    } else {
        $stmt = db()->prepare('INSERT INTO users (emp_id, name, username, password, user_type, role, shift, store_id) VALUES (?, ?, ?, ?, "staff", ?, ?, ?)');
        $stmt->execute([$input['id'] ?? '', $input['name'] ?? '', $input['username'] ?? '', $input['password'] ?? '', $input['role'] ?? '', $input['shift'] ?? 'A', $storeId]);
    }
    json_response(['ok' => true]);
}

function delete_employee(array $input): void {
    $stmt = db()->prepare('DELETE FROM users WHERE emp_id = ? AND user_type = "staff"');
    $stmt->execute([$input['id'] ?? '']);
    json_response(['ok' => true]);
}

function toggle_employee_freeze(array $input): void {
    $frozen = ((int)($input['frozen'] ?? 0)) === 1 ? 1 : 0;
    $stmt = db()->prepare('UPDATE users SET frozen = ?, active = IF(? = 1, 0, active) WHERE emp_id = ? AND user_type = "staff"');
    $stmt->execute([$frozen, $frozen, $input['id'] ?? '']);
    json_response(['ok' => true]);
}

function delete_vehicle(array $input): void {
    $pdo = db();
    ensure_schema($pdo);
    $existing = $pdo->prepare('SELECT store_id FROM bikes WHERE id = ?');
    $existing->execute([(int)($input['id'] ?? 0)]);
    $storeId = $existing->fetchColumn();
    assert_inventory_permission($pdo, $input, $storeId ? (int)$storeId : null);
    $stmt = $pdo->prepare('DELETE FROM bikes WHERE id = ?');
    $stmt->execute([(int)($input['id'] ?? 0)]);
    json_response(['ok' => true]);
}

function save_invoice(array $input): void {
    $pdo = db();
    ensure_schema($pdo);
    $customer = trim((string)($input['customer'] ?? ''));
    $phone = trim((string)($input['phone'] ?? ''));
    $bikeName = trim((string)($input['bike'] ?? ''));
    $color = trim((string)($input['color'] ?? ''));
    if ($customer === '' || $phone === '' || $bikeName === '' || $color === '') {
        json_response(['ok' => false, 'error' => 'Customer, phone, vehicle, and color are required.']);
    }
    if (!preg_match('/^[0-9+\-\s()]{10,18}$/', $phone)) {
        json_response(['ok' => false, 'error' => 'Enter a valid phone number.']);
    }
    $booking = (string)($input['booking'] ?? 'No');
    $booking = $booking === 'Yes' ? 'Yes' : 'No';
    $transactionType = $booking === 'Yes' ? 'Booking' : 'Vehicle Sale';
    if (!in_array($transactionType, ['Vehicle Sale', 'Booking'], true)) {
        json_response(['ok' => false, 'error' => 'Invalid transaction type.']);
    }
    $employeeId = user_id_by_username((string)($input['username'] ?? $input['user_id'] ?? $input['employee'] ?? ''));
    if (!$employeeId && !empty($input['user_id'])) {
        $stmt = $pdo->prepare('SELECT id FROM users WHERE emp_id = ? LIMIT 1');
        $stmt->execute([(string)$input['user_id']]);
        $employeeId = $stmt->fetchColumn() ?: null;
    }
    $user = null;
    if ($employeeId) {
        $stmt = $pdo->prepare('SELECT u.id, u.name, u.user_type, u.store_id, COALESCE(s.name, "All Showrooms") AS branch FROM users u LEFT JOIN stores s ON s.id = u.store_id WHERE u.id = ?');
        $stmt->execute([$employeeId]);
        $user = $stmt->fetch();
    }
    if (!$user) {
        json_response(['ok' => false, 'error' => 'Authorized employee was not found.']);
    }
    $amount = to_lakhs((float)($input['amount'] ?? 0), (string)($input['amount_unit'] ?? 'lakhs'));
    $quantity = max((int)($input['quantity'] ?? 1), 1);
    $accessories = money_lakh($input['accessories'] ?? 0);
    $insurance = money_lakh($input['insurance_amount'] ?? 0);
    $registration = money_lakh($input['registration'] ?? 0);
    $handling = money_lakh($input['handling'] ?? 0);
    $logistics = money_lakh($input['logistics'] ?? 0);
    $extendedWarranty = money_lakh($input['extended_warranty'] ?? 0);
    $other = money_lakh($input['other_charges'] ?? 0);
    $discountType = (string)($input['discount_type'] ?? 'None');
    if (!in_array($discountType, ['None', 'Percentage', 'Fixed Amount'], true)) {
        json_response(['ok' => false, 'error' => 'Invalid discount type.']);
    }
    $discountValue = $discountType === 'Percentage' ? money_lakh($input['discount_percent'] ?? 0) : money_lakh($input['discount'] ?? 0);
    $gstPercent = (float)($input['gst'] ?? 0);
    if ($amount <= 0 || $gstPercent < 0 || $gstPercent > 50) {
        json_response(['ok' => false, 'error' => 'Invalid price or GST value.']);
    }
    $subtotal = max(($amount * $quantity) + $accessories + $insurance + $registration + $handling + $logistics + $extendedWarranty + $other, 0);
    $discount = $discountType === 'Percentage' ? ($subtotal * $discountValue / 100) : $discountValue;
    if ($discount > $subtotal) {
        json_response(['ok' => false, 'error' => 'Discount cannot exceed subtotal.']);
    }
    $taxable = max($subtotal - $discount, 0);
    $gstAmount = $taxable * $gstPercent / 100;
    $cgstPercent = $gstPercent / 2;
    $sgstPercent = $gstPercent / 2;
    $cgstAmount = $gstAmount / 2;
    $sgstAmount = $gstAmount / 2;
    $grandTotal = $taxable + $gstAmount;
    $paid = $booking === 'Yes' ? 0 : rupees_to_lakhs($input['amount_paid'] ?? 0);
    $bookingAmount = $booking === 'Yes' ? rupees_to_lakhs($input['booking_amount'] ?? 0) : 0;
    if (($paid + $bookingAmount) > $grandTotal) {
        json_response(['ok' => false, 'error' => 'Payment amount cannot exceed total amount.']);
    }
    $financeRequired = (string)($input['finance_required'] ?? 'No');
    if ($financeRequired === 'Yes' && trim((string)($input['finance_provider'] ?? '')) === '') {
        json_response(['ok' => false, 'error' => 'Finance provider is required.']);
    }
    $loanAmount = $financeRequired === 'Yes' ? rupees_to_lakhs($input['loan_amount'] ?? 0) : 0;
    $downPayment = $financeRequired === 'Yes' ? rupees_to_lakhs($input['down_payment'] ?? 0) : 0;
    $loanTenure = $financeRequired === 'Yes' ? (int)($input['loan_tenure_months'] ?? $input['total_emis'] ?? $input['number_of_emis'] ?? 0) : 0;
    $interestRate = $financeRequired === 'Yes' ? (float)($input['interest_rate'] ?? 0) : 0;
    $emiDueDay = $financeRequired === 'Yes' ? (int)($input['emi_due_day'] ?? 0) : 0;
    $totalEmis = $financeRequired === 'Yes' ? max((int)($input['total_emis'] ?? $input['number_of_emis'] ?? $loanTenure), 0) : 0;
    $emisPaid = $financeRequired === 'Yes' ? max((int)($input['emis_paid'] ?? 0), 0) : 0;
    $remainingEmis = $financeRequired === 'Yes' ? max((int)($input['remaining_emis'] ?? ($totalEmis - $emisPaid)), 0) : 0;
    $emiStatus = $financeRequired === 'Yes' ? (string)($input['emi_status'] ?? 'Upcoming') : 'Upcoming';
    $financeStatus = $financeRequired === 'Yes' ? (string)($input['finance_status'] ?? 'Documents Pending') : 'Not Applied';
    if ($financeRequired === 'Yes' && $financeStatus === 'Not Applied') {
        $financeStatus = 'Documents Pending';
    }
    $emiAmount = $financeRequired === 'Yes' ? rupees_to_lakhs($input['emi_amount'] ?? 0) : 0;
    if ($financeRequired === 'Yes' && $emiAmount <= 0) {
        $emiAmount = calculate_emi_lakh($loanAmount, $totalEmis ?: $loanTenure, $interestRate);
    }
    if ($loanAmount > max($grandTotal - $bookingAmount - $paid - $downPayment, 0)) {
        json_response(['ok' => false, 'error' => 'Finance loan amount cannot exceed remaining balance.']);
    }
    $financeCoverage = in_array($financeStatus, ['Loan Disbursed', 'EMI Started', 'EMI Active', 'Completed'], true) ? $loanAmount : 0;
    $balance = max($grandTotal - $paid - $bookingAmount - $downPayment - $financeCoverage, 0);
    $paymentStatus = derived_payment_status($grandTotal, $bookingAmount, $paid, $financeRequired, $financeStatus);
    $paymentDate = trim((string)($input['payment_date'] ?? ''));
    if ($paymentDate === '' && ($paid > 0 || $paymentStatus === 'Fully Paid')) {
        $paymentDate = date('Y-m-d');
    }
    $bookingDate = trim((string)($input['booking_date'] ?? ''));
    if ($booking === 'Yes' && $bookingDate === '') {
        $bookingDate = date('Y-m-d');
    }
    if (($input['payment_mode'] ?? '') === 'Mixed Payment') {
        $mixedTotal = mixed_payment_total_lakh($input);
        if (abs($mixedTotal - $paid) > 0.01) {
            json_response(['ok' => false, 'error' => 'Mixed payment total must match Amount Paid.']);
        }
    }
    $input['payment_date'] = $paymentDate;
    $input['booking_date'] = $bookingDate;
    $pdo->beginTransaction();
    try {
        $selectedStoreId = null;
        $selectedShowroom = trim((string)($input['showroom'] ?? ''));
        if ($user['user_type'] === 'staff') {
            $selectedStoreId = (int)$user['store_id'];
            $selectedShowroom = (string)$user['branch'];
        } elseif ($selectedShowroom !== '') {
            $selectedStoreId = store_id($selectedShowroom);
            if (!$selectedStoreId) {
                throw new RuntimeException('Selected showroom was not found.');
            }
        }
        $bikeSql = '
            SELECT b.*, s.name AS showroom
            FROM bikes b
            LEFT JOIN stores s ON s.id = b.store_id
            WHERE b.name = ? AND COALESCE(NULLIF(b.color_scheme, ""), "Not specified") = ?
        ';
        $bikeArgs = [$bikeName, $color];
        if ($selectedStoreId) {
            $bikeSql .= ' AND b.store_id = ?';
            $bikeArgs[] = $selectedStoreId;
        }
        $bikeSql .= ' ORDER BY b.stock_units DESC, b.id ASC LIMIT 1 FOR UPDATE';
        $bikeStmt = $pdo->prepare($bikeSql);
        $bikeStmt->execute($bikeArgs);
        $bike = $bikeStmt->fetch();
        $branchBike = $bike;
        if (!$bike && $transactionType === 'Booking') {
            $templateStmt = $pdo->prepare('
                SELECT b.*, s.name AS showroom
                FROM bikes b
                LEFT JOIN stores s ON s.id = b.store_id
                WHERE b.name = ?
                ORDER BY b.stock_units DESC, b.id ASC
                LIMIT 1
            ');
            $templateStmt->execute([$bikeName]);
            $bike = $templateStmt->fetch();
        }
        if (!$bike) {
            throw new RuntimeException('Vehicle is not available for this showroom.');
        }
        if ($transactionType === 'Vehicle Sale' && $selectedStoreId && (int)$bike['store_id'] !== (int)$selectedStoreId) {
            throw new RuntimeException('Employee is not authorized for this showroom.');
        }
        if ($transactionType === 'Vehicle Sale' && (!$branchBike || (int)$bike['stock_units'] < $quantity)) {
            throw new RuntimeException('Requested quantity is not available in this showroom. Create a booking instead.');
        }
        $invoiceStoreId = $branchBike ? (int)$bike['store_id'] : (int)($selectedStoreId ?: $bike['store_id']);
        $invoiceShowroom = $branchBike ? $bike['showroom'] : ($selectedShowroom ?: $bike['showroom']);
        $vehicleVin = $branchBike ? ($bike['chassis_vin'] ?? '') : '';
        $vehicleEngine = $branchBike ? ($bike['engine_serial'] ?? '') : '';
        $vehicleYear = $branchBike ? ($bike['model_year'] ?? '') : '';
        $vehicleFuel = $branchBike ? ($bike['fuel_model'] ?? '') : '';
        $vehicleOdometer = $branchBike ? ($bike['odometer'] ?? 0) : 0;
        $placeholder = 'PENDING-' . bin2hex(random_bytes(8));
        $invoiceInsert = $pdo->prepare('
            INSERT INTO billing_invoices (
              invoice_number, transaction_type, booking, customer_type, customer_name, phone, email, address, city, state_name, pincode, id_type, id_reference, id_proof_file_name, id_proof_file_data,
              customer_gstin, customer_pan, relation_name, bill_to_address, delivery_address,
              bike_id, bike_name, category, color, vin, engine, model_year, fuel_type, odometer,
              showroom_price_lakh, quantity, accessories_lakh, insurance_lakh, registration_lakh, handling_lakh, logistics_lakh,
              extended_warranty_lakh, other_charges_lakh, subtotal_lakh, discount_type, discount_value, discount_lakh, taxable_lakh,
              gst_percent, gst_amount_lakh, cgst_percent, cgst_lakh, sgst_percent, sgst_lakh, round_off_lakh,
              grand_total_lakh, payment_status, payment_mode, payment_reference, payment_date,
              amount_paid_lakh, balance_lakh, booking_number, booking_amount_lakh, booking_date, expected_delivery_date, booking_status,
              finance_required, finance_provider, loan_amount_lakh, loan_application_number, loan_account_number, down_payment_lakh, loan_tenure_months, interest_rate_percent, finance_status,
              emi_amount_lakh, emi_start_date, emi_due_date, emi_due_day, emi_frequency, number_of_emis, emis_paid, remaining_emis, emi_status, next_emi_due_date,
              delivery_status, actual_delivery_date, delivery_location, sales_executive,
              store_id, employee_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ');
        $invoiceInsert->execute([
            $placeholder, $transactionType, $booking, $input['customer_type'] ?? 'Individual', $customer, $phone, $input['email'] ?? null, $input['address'] ?? null, $input['city'] ?? null,
            $input['state_name'] ?? null, $input['pincode'] ?? null, $input['id_type'] ?? null, $input['id_reference'] ?? null, $input['id_proof_file_name'] ?? null, $input['id_proof_file_data'] ?? null,
            $input['customer_gstin'] ?? null, $input['customer_pan'] ?? null, $input['relation_name'] ?? null, $input['bill_to_address'] ?? null, $input['delivery_address'] ?? null,
            $bike['id'], $bike['name'], $bike['category'], $color, $vehicleVin, $vehicleEngine, $vehicleYear,
            $vehicleFuel, $vehicleOdometer, $amount, $quantity, $accessories, $insurance, $registration, $handling, $logistics,
            $extendedWarranty, $other, $subtotal, $discountType, $discountValue, $discount, $taxable,
            $gstPercent, $gstAmount, $cgstPercent, $cgstAmount, $sgstPercent, $sgstAmount, 0,
            $grandTotal, $paymentStatus, $input['payment_mode'] ?? 'UPI', $input['payment_reference'] ?? null, $paymentDate ?: null,
            $paid, $balance, null, $bookingAmount, $bookingDate ?: null, ($input['delivery_date'] ?? '') ?: null, $input['booking_status'] ?? null,
            $financeRequired, $input['finance_provider'] ?? null, $loanAmount, $input['loan_application_number'] ?? null, $input['loan_account_number'] ?? null, $downPayment, $loanTenure, $interestRate, $financeStatus,
            $emiAmount, ($input['emi_start_date'] ?? '') ?: null, ($input['emi_due_date'] ?? '') ?: null,
            $emiDueDay, $input['emi_frequency'] ?? 'Monthly', $totalEmis, $emisPaid, $remainingEmis, $emiStatus, ($input['next_emi_due_date'] ?? '') ?: null,
            $input['delivery_status'] ?? 'Pending', ($input['actual_delivery_date'] ?? '') ?: null, $input['delivery_location'] ?? $invoiceShowroom, $input['sales_executive'] ?? $user['name'],
            $invoiceStoreId, $employeeId
        ]);
        $billingId = (int)$pdo->lastInsertId();
        $bookingNumber = $transactionType === 'Booking' ? ('BKG-' . date('Y') . '-' . str_pad((string)$billingId, 6, '0', STR_PAD_LEFT)) : null;
        $invoiceNumber = 'INV-' . date('Y') . '-' . str_pad((string)$billingId, 6, '0', STR_PAD_LEFT);
        $status = sales_workflow_status($transactionType, $paymentStatus, $financeRequired, $financeStatus, (string)($input['booking_status'] ?? ''), (string)($input['delivery_status'] ?? 'Pending'));
        $stmt = $pdo->prepare("
            INSERT INTO sales (transaction_id, customer_name, phone, bike_name, amount_lakh, gst_percent, discount_lakh, status, payment_status, payment_mode, store_id, employee_id, sale_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE())
        ");
        $stmt->execute([
            $invoiceNumber,
            $customer,
            $phone,
            $bike['name'],
            $grandTotal,
            $gstPercent,
            $discount,
            $status,
            $paymentStatus,
            $input['payment_mode'] ?? 'UPI',
            $invoiceStoreId,
            $employeeId,
        ]);
        $saleId = (int)$pdo->lastInsertId();
        $pdo->prepare('UPDATE billing_invoices SET invoice_number = ?, booking_number = ?, sale_id = ? WHERE id = ?')->execute([$invoiceNumber, $bookingNumber, $saleId, $billingId]);
        insert_payment_history($pdo, $input, $billingId, $saleId, $bookingNumber, $customer, (int)$bike['id'], $invoiceStoreId, $employeeId, $bookingAmount, $paid);
        $pdo->prepare('INSERT INTO sale_status_history (sale_id, status, notes, changed_by) VALUES (?, ?, ?, ?)')->execute([
            $saleId,
            $status,
            $transactionType === 'Booking' ? 'Booking created from Billing page' : 'Invoice created from Billing page',
            $employeeId,
        ]);
        if ($transactionType === 'Vehicle Sale') {
            $stock = $pdo->prepare('UPDATE bikes SET stock_units = stock_units - ?, sold_units = sold_units + ? WHERE id = ? AND stock_units >= ?');
            $stock->execute([$quantity, $quantity, $bike['id'], $quantity]);
            if ($stock->rowCount() !== 1) {
                throw new RuntimeException('Stock update failed. Bill was not saved.');
            }
        }
        $pdo->commit();
        json_response(['ok' => true, 'invoice' => [
            'invoice_number' => $invoiceNumber,
            'invoice_date' => date('Y-m-d'),
            'invoice_time' => date('H:i'),
            'transaction_type' => $transactionType,
            'booking' => $booking,
            'booking_number' => $bookingNumber,
            'customer_type' => $input['customer_type'] ?? 'Individual',
            'customer' => $customer,
            'phone' => $phone,
            'email' => $input['email'] ?? '',
            'address' => $input['address'] ?? '',
            'city' => $input['city'] ?? '',
            'state_name' => $input['state_name'] ?? '',
            'pincode' => $input['pincode'] ?? '',
            'customer_gstin' => $input['customer_gstin'] ?? '',
            'customer_pan' => $input['customer_pan'] ?? '',
            'relation_name' => $input['relation_name'] ?? '',
            'bill_to_address' => $input['bill_to_address'] ?? '',
            'delivery_address' => $input['delivery_address'] ?? '',
            'bike' => $bike['name'],
            'category' => $bike['category'],
            'showroom' => $invoiceShowroom,
            'color' => $color,
            'vin' => $vehicleVin,
            'engine' => $vehicleEngine,
            'year' => $vehicleYear,
            'fuel' => $vehicleFuel,
            'odometer' => $vehicleOdometer,
            'amount' => $amount,
            'amount_unit' => 'lakhs',
            'quantity' => $quantity,
            'id_type' => $input['id_type'] ?? '',
            'id_reference' => $input['id_reference'] ?? '',
            'id_proof_file_name' => $input['id_proof_file_name'] ?? '',
            'accessories' => $accessories,
            'insurance_amount' => $insurance,
            'registration' => $registration,
            'handling' => $handling,
            'logistics' => $logistics,
            'extended_warranty' => $extendedWarranty,
            'other_charges' => $other,
            'discount_type' => $discountType,
            'discount_percent' => $input['discount_percent'] ?? 0,
            'discount_lakh' => $discount,
            'taxable_lakh' => $taxable,
            'gst' => $gstPercent,
            'gst_amount_lakh' => $gstAmount,
            'cgst_percent' => $cgstPercent,
            'cgst_lakh' => $cgstAmount,
            'sgst_percent' => $sgstPercent,
            'sgst_lakh' => $sgstAmount,
            'round_off_lakh' => 0,
            'grand_total_lakh' => $grandTotal,
            'amount_paid_lakh' => $paid,
            'balance_lakh' => $balance,
            'payment_mode' => $input['payment_mode'] ?? 'UPI',
            'payment_status' => $paymentStatus,
            'payment_reference' => $input['payment_reference'] ?? '',
            'booking_amount' => $bookingAmount,
            'finance_required' => $financeRequired,
            'finance_provider' => $input['finance_provider'] ?? '',
            'loan_application_number' => $input['loan_application_number'] ?? '',
            'loan_account_number' => $input['loan_account_number'] ?? '',
            'loan_amount_lakh' => $loanAmount,
            'down_payment_lakh' => $downPayment,
            'loan_tenure_months' => $loanTenure,
            'interest_rate_percent' => $interestRate,
            'finance_status' => $financeStatus,
            'emi_amount_lakh' => $emiAmount,
            'emi_start_date' => $input['emi_start_date'] ?? '',
            'emi_due_date' => $input['emi_due_date'] ?? '',
            'emi_due_day' => $emiDueDay,
            'emi_frequency' => $input['emi_frequency'] ?? 'Monthly',
            'number_of_emis' => $totalEmis,
            'emis_paid' => $emisPaid,
            'remaining_emis' => $remainingEmis,
            'emi_status' => $emiStatus,
            'next_emi_due_date' => $input['next_emi_due_date'] ?? '',
            'delivery_status' => $input['delivery_status'] ?? 'Pending',
            'employee' => $user['name'],
        ]]);
    } catch (Throwable $e) {
        $pdo->rollBack();
        throw $e;
    }
}

function money_lakh($value): float {
    return max((float)$value, 0);
}

function mixed_payment_total_lakh(array $input): float {
    $fields = ['mixed_cash', 'mixed_upi', 'mixed_debit_card', 'mixed_credit_card', 'mixed_neft', 'mixed_rtgs', 'mixed_imps', 'mixed_bank_transfer', 'mixed_cheque'];
    return array_reduce($fields, fn($sum, $field) => $sum + rupees_to_lakhs($input[$field] ?? 0), 0.0);
}

function derived_payment_status(float $total, float $bookingAmount, float $paid, string $financeRequired, string $financeStatus): string {
    if ($financeRequired === 'Yes') {
        if ($financeStatus === 'EMI Active') {
            return 'EMI Active';
        }
        if (in_array($financeStatus, ['Loan Disbursed', 'Completed'], true)) {
            return 'Loan Disbursed';
        }
        if ($financeStatus === 'Finance Approved') {
            return 'Finance Approved';
        }
        return 'Finance Pending';
    }
    $collected = $bookingAmount + $paid;
    if ($collected <= 0) {
        return 'Pending';
    }
    if ($collected >= $total) {
        return 'Fully Paid';
    }
    return $bookingAmount > 0 && $paid <= 0 ? 'Down Payment' : 'Partially Paid';
}

function emi_status_for_date(?string $value): string {
    if (!$value) {
        return 'Upcoming';
    }
    $today = new DateTime(date('Y-m-d'));
    $due = DateTime::createFromFormat('Y-m-d', $value);
    if (!$due) {
        return 'Upcoming';
    }
    if ($due->format('Y-m-d') === $today->format('Y-m-d')) {
        return 'Due Today';
    }
    return $due < $today ? 'Overdue' : 'Upcoming';
}

function sales_workflow_status(string $transactionType, string $paymentStatus, string $financeRequired, string $financeStatus, string $bookingStatus, string $deliveryStatus): string {
    if ($deliveryStatus === 'Delivered') {
        return 'Delivered';
    }
    if (in_array($deliveryStatus, ['Ready for Delivery', 'Delivery Scheduled'], true)) {
        return 'Delivery Scheduled';
    }
    if ($transactionType === 'Booking') {
        return $bookingStatus !== '' ? $bookingStatus : 'Booking Confirmed';
    }
    if ($financeRequired === 'Yes') {
        if ($financeStatus === 'EMI Active') {
            return 'EMI Active';
        }
        return $financeStatus !== '' && $financeStatus !== 'Not Applied' ? $financeStatus : 'Documents Pending';
    }
    if ($paymentStatus === 'Fully Paid') {
        return 'Payment Completed';
    }
    if ($paymentStatus === 'Partially Paid') {
        return 'Partially Paid';
    }
    if ($paymentStatus === 'Down Payment') {
        return 'Balance Pending';
    }
    return 'Pending';
}

function insert_payment_history(PDO $pdo, array $input, int $invoiceId, int $saleId, ?string $bookingNumber, string $customer, int $bikeId, int $storeId, int $employeeId, float $bookingAmount, float $paid): void {
    $insert = $pdo->prepare('
        INSERT INTO billing_payments (invoice_id, sale_id, booking_number, customer_name, bike_id, store_id, employee_id, payment_type, payment_mode, amount_lakh, reference, payment_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
    if ($bookingAmount > 0) {
        $insert->execute([$invoiceId, $saleId, $bookingNumber, $customer, $bikeId, $storeId, $employeeId, 'Booking', $input['payment_mode'] ?? 'UPI', $bookingAmount, $input['payment_reference'] ?? null, ($input['booking_date'] ?? $input['payment_date'] ?? '') ?: null]);
    }
    if ($paid <= 0) {
        return;
    }
    if (($input['payment_mode'] ?? '') !== 'Mixed Payment') {
        $type = ($bookingAmount + $paid) >= money_lakh($input['grand_total_lakh'] ?? 0) ? 'Final Payment' : 'Partial Payment';
        $insert->execute([$invoiceId, $saleId, $bookingNumber, $customer, $bikeId, $storeId, $employeeId, $type, $input['payment_mode'] ?? 'UPI', $paid, $input['payment_reference'] ?? null, ($input['payment_date'] ?? '') ?: null]);
        return;
    }
    $mixed = [
        'mixed_cash' => 'Cash',
        'mixed_upi' => 'UPI',
        'mixed_debit_card' => 'Debit Card',
        'mixed_credit_card' => 'Credit Card',
        'mixed_neft' => 'NEFT',
        'mixed_rtgs' => 'RTGS',
        'mixed_imps' => 'IMPS',
        'mixed_bank_transfer' => 'Bank Transfer',
        'mixed_cheque' => 'Cheque',
    ];
    foreach ($mixed as $field => $mode) {
        $amount = rupees_to_lakhs($input[$field] ?? 0);
        if ($amount > 0) {
            $insert->execute([$invoiceId, $saleId, $bookingNumber, $customer, $bikeId, $storeId, $employeeId, 'Mixed Payment', $mode, $amount, $input['payment_reference'] ?? null, ($input['payment_date'] ?? '') ?: null]);
        }
    }
}

function mark_emi_paid(array $input): void {
    $pdo = db();
    ensure_schema($pdo);
    $username = (string)($input['username'] ?? '');
    $stmt = $pdo->prepare('SELECT id, user_type, store_id FROM users WHERE username = ? OR emp_id = ? LIMIT 1');
    $stmt->execute([$username, (string)($input['user_id'] ?? '')]);
    $user = $stmt->fetch();
    if (!$user || !in_array($user['user_type'], ['admin', 'staff'], true)) {
        json_response(['ok' => false, 'error' => 'Only authorized showroom users can update EMI payments.']);
    }
    $transactionId = trim((string)($input['transaction_id'] ?? ''));
    if ($transactionId === '') {
        json_response(['ok' => false, 'error' => 'Transaction id is required.']);
    }
    $invoiceStmt = $pdo->prepare('
        SELECT bi.*, s.id AS sale_db_id
        FROM billing_invoices bi
        INNER JOIN sales s ON s.id = bi.sale_id
        WHERE s.transaction_id = ? OR bi.invoice_number = ?
        LIMIT 1
    ');
    $invoiceStmt->execute([$transactionId, $transactionId]);
    $invoice = $invoiceStmt->fetch();
    if (!$invoice) {
        json_response(['ok' => false, 'error' => 'EMI invoice was not found.']);
    }
    if ($user['user_type'] === 'staff' && (int)$invoice['store_id'] !== (int)$user['store_id']) {
        json_response(['ok' => false, 'error' => 'Employee is not authorized for this showroom EMI.']);
    }
    $dueDate = $invoice['next_emi_due_date'] ?: $invoice['emi_due_date'] ?: date('Y-m-d');
    $emiAmount = (float)($invoice['emi_amount_lakh'] ?? 0);
    if ($emiAmount <= 0) {
        json_response(['ok' => false, 'error' => 'EMI amount is not available for this invoice.']);
    }
        $pdo->beginTransaction();
    try {
        $paidDate = trim((string)($input['payment_date'] ?? '')) ?: date('Y-m-d');
        $emiReference = trim((string)($input['reference'] ?? '')) ?: ('EMI due ' . $dueDate);
        $duplicate = $pdo->prepare("SELECT id FROM billing_payments WHERE invoice_id = ? AND payment_type = 'EMI Payment' AND reference = ? LIMIT 1");
        $duplicate->execute([(int)$invoice['id'], $emiReference]);
        if (!$duplicate->fetchColumn()) {
            $insert = $pdo->prepare('
                INSERT INTO billing_payments (invoice_id, sale_id, booking_number, customer_name, bike_id, store_id, employee_id, payment_type, payment_mode, amount_lakh, reference, payment_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ');
            $insert->execute([(int)$invoice['id'], (int)$invoice['sale_id'], $invoice['booking_number'], $invoice['customer_name'], $invoice['bike_id'], $invoice['store_id'], $user['id'], 'EMI Payment', $input['payment_mode'] ?? 'EMI', $emiAmount, $emiReference, $paidDate]);
        }
        $paidEmis = (int)($invoice['emis_paid'] ?? 0) + 1;
        $remaining = max((int)($invoice['remaining_emis'] ?? 0) - 1, 0);
        $nextDue = $remaining > 0 ? (new DateTime($dueDate))->modify('+1 month')->format('Y-m-d') : null;
        $paymentStatus = $remaining > 0 ? 'EMI Active' : 'Fully Paid';
        $saleStatus = $remaining > 0 ? 'EMI Active' : 'Delivered';
        $financeStatus = $remaining > 0 ? 'EMI Active' : 'Completed';
        $emiStatus = $remaining > 0 ? emi_status_for_date($nextDue) : 'Paid';
        $pdo->prepare('UPDATE billing_invoices SET emis_paid = ?, remaining_emis = ?, next_emi_due_date = ?, emi_due_date = ?, payment_date = ?, payment_status = ?, finance_status = ?, emi_status = ? WHERE id = ?')
            ->execute([$paidEmis, $remaining, $nextDue, $nextDue, $paidDate, $paymentStatus, $financeStatus, $emiStatus, (int)$invoice['id']]);
        $pdo->prepare('UPDATE sales SET payment_status = ?, status = ? WHERE id = ?')
            ->execute([$paymentStatus, $saleStatus, (int)$invoice['sale_id']]);
        $pdo->prepare('INSERT INTO sale_status_history (sale_id, status, notes, changed_by) VALUES (?, ?, ?, ?)')
            ->execute([(int)$invoice['sale_id'], $saleStatus, 'EMI installment marked paid', $user['id']]);
        $pdo->commit();
        json_response(['ok' => true, 'remaining_emis' => $remaining, 'next_emi_due_date' => $nextDue]);
    } catch (Throwable $e) {
        $pdo->rollBack();
        throw $e;
    }
}

function rupees_to_lakhs($value): float {
    return money_lakh($value) / 100000;
}

function calculate_emi_lakh(float $principal, int $months, float $annualRate): float {
    if ($principal <= 0 || $months <= 0) {
        return 0;
    }
    $monthlyRate = $annualRate / 1200;
    if ($monthlyRate <= 0) {
        return round($principal / $months, 2);
    }
    $factor = pow(1 + $monthlyRate, $months);
    return round(($principal * $monthlyRate * $factor) / ($factor - 1), 2);
}

function to_lakhs(float $value, string $unit): float {
    if ($unit === 'rupees') {
        return $value / 100000;
    }
    if ($unit === 'hundreds') {
        return $value / 1000;
    }
    if ($unit === 'thousands') {
        return $value / 100;
    }
    return $value;
}
