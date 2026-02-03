<?php
// logs_crud.php - System Activity Logging

// 1. HELPER FUNCTION (Library Mode)
// This function is designed to be 'included' by other PHP files (login.php, add_patient.php).
// It allows backend scripts to log events internally without making a separate HTTP request.
function addSystemLog($conn, $actionType, $description, $userId = null, $userName = null, $userRole = null, $targetType = null, $targetId = null) {
    try {
        // AUTO-INIT: Create the table on the very first log attempt if it doesn't exist.
        // This makes deployment easier (no need to run manual SQL setup scripts).
        static $tableCreated = false;
        if (!$tableCreated) {
            $createTableSql = "CREATE TABLE IF NOT EXISTS system_logs (
                log_id INT AUTO_INCREMENT PRIMARY KEY,
                action_type VARCHAR(50) NOT NULL,
                action_description TEXT NOT NULL,
                user_id INT NULL,
                user_name VARCHAR(150) NULL,
                user_role VARCHAR(20) NULL,
                target_type VARCHAR(50) NULL,
                target_id INT NULL,
                ip_address VARCHAR(50) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci";
            $conn->exec($createTableSql);
            $tableCreated = true;
        }
        
        // Insert the log entry
        $sql = "INSERT INTO system_logs (action_type, action_description, user_id, user_name, user_role, target_type, target_id, ip_address) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->execute([
            $actionType,    // e.g., 'login_failed', 'patient_deleted'
            $description,   // e.g., 'Invalid password for user Admin'
            $userId,
            $userName,
            $userRole,
            $targetType,    // e.g., 'patient' (what was modified)
            $targetId,      // e.g., 105 (the ID of the modified item)
            $_SERVER['REMOTE_ADDR'] ?? null // Capture IP Address
        ]);
        return true;
    } catch (Exception $e) {
        // Fail silently so we don't crash the main app flow just because logging failed
        return false; 
    }
}

// 2. API ENDPOINT LOGIC (Direct Access)
// The code below ONLY runs if the Admin Dashboard calls this file directly via HTTP.
// If another PHP file does 'include logs_crud.php', this part is skipped.
if (basename($_SERVER['SCRIPT_FILENAME']) === 'logs_crud.php') {
    
    header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
    header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
    include 'db_connect.php';
    
    // Ensure table exists (Duplicate check for direct API calls)
    $createTableSql = "CREATE TABLE IF NOT EXISTS system_logs (
        log_id INT AUTO_INCREMENT PRIMARY KEY,
        action_type VARCHAR(50) NOT NULL,
        action_description TEXT NOT NULL,
        user_id INT NULL,
        user_name VARCHAR(150) NULL,
        user_role VARCHAR(20) NULL,
        target_type VARCHAR(50) NULL,
        target_id INT NULL,
        ip_address VARCHAR(50) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci";
    $conn->exec($createTableSql);
    
    // GET REQUESTS (View Logs)
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $action = $_GET['action'] ?? 'get_recent';
        
        // PAGINATION INPUTS
        // Logs can be huge (10,000+ rows). We MUST use pagination to prevent crashing.
        // Limit: How many to show (default 50)
        // Offset: Where to start (e.g., start at row 51 for page 2)
        $limit = intval($_GET['limit'] ?? 50);
        $offset = intval($_GET['offset'] ?? 0);
        $filterType = $_GET['filter_type'] ?? null;
        
        if ($action === 'get_recent') {
            $sql = "SELECT * FROM system_logs";
            $params = [];
            
            // Optional Filtering (e.g., Show only 'login_failed' events)
            if ($filterType) {
                $sql .= " WHERE action_type = ?";
                $params[] = $filterType;
            }
            
            // Add Sorting and Pagination
            // We cast $limit and $offset to intval() above.
            $sql .= " ORDER BY created_at DESC LIMIT $limit OFFSET $offset";
            
            $stmt = $conn->prepare($sql);
            $stmt->execute($params);
            $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get Total Count (Needed for pagination UI to calculate total pages)
            $countSql = "SELECT COUNT(*) as total FROM system_logs";
            if ($filterType) {
                $countSql .= " WHERE action_type = ?";
                $countStmt = $conn->prepare($countSql);
                $countStmt->execute([$filterType]);
            } else {
                $countStmt = $conn->query($countSql);
            }
            $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            echo json_encode([
                'success' => true,
                'logs' => $logs,
                'total' => $total,
                'limit' => $limit,
                'offset' => $offset
            ]);

        } elseif ($action === 'get_action_types') {
            // Helper for the "Filter" dropdown menu in Admin Dashboard
            $stmt = $conn->query("SELECT DISTINCT action_type FROM system_logs ORDER BY action_type");
            echo json_encode($stmt->fetchAll(PDO::FETCH_COLUMN));
        }
        exit;
    }
    
    
    // POST REQUESTS (Admin Actions)
    $data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from the Flutter app
    $action = $data['action'] ?? '';
    
    if ($action === 'add') {
        // Allow manual logging via API (e.g., from Flutter app directly)
        try {
            $sql = "INSERT INTO system_logs (action_type, action_description, user_id, user_name, user_role, target_type, target_id, ip_address) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['action_type'] ?? 'unknown',
                $data['action_description'] ?? '',
                $data['user_id'] ?? null,
                $data['user_name'] ?? null,
                $data['user_role'] ?? null,
                $data['target_type'] ?? null,
                $data['target_id'] ?? null,
                $_SERVER['REMOTE_ADDR'] ?? null
            ]);
            
            echo json_encode(['success' => true, 'log_id' => $conn->lastInsertId()]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }

    } elseif ($action === 'clear_old') {
        // Maintenance: Admin can delete logs older than X days to save space
        try {
            $days = intval($data['days'] ?? 30);
            // DATE_SUB calculates the date X days ago
            $stmt = $conn->prepare("DELETE FROM system_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)");
            $stmt->execute([$days]);
            $deleted = $stmt->rowCount();
            echo json_encode(['success' => true, 'deleted' => $deleted, 'message' => "Deleted $deleted old log entries"]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
}
?>