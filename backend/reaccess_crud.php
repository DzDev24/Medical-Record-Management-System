<?php
// reaccess_crud.php - CRUD operations for re-access requests

// ==========================================
// 1. ADVANCED ERROR HANDLING
// ==========================================
// 'ob_start' turns on Output Buffering.
// If PHP crashes, it usually prints a messy HTML error on the screen.
// Output buffering lets us "catch" that messy output, throw it away, 
// and replace it with a clean JSON error message so the App doesn't crash.
ob_start();

// Disable printing errors to the screen immediately
ini_set('display_errors', 0);
ini_set('html_errors', 0);
error_reporting(E_ALL);

// Convert standard PHP warnings into "Exceptions" so we can catch them in try-catch blocks
set_error_handler(function($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

// Top-Level Exception Handler: Catches any crash we missed elsewhere
set_exception_handler(function($e) {
    ob_clean(); // Clear any buffered output
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
    exit;
});

// Shutdown Function: Catches "Fatal Errors" (like missing semicolons or memory limits)
// that usually stop the script instantly. This ensures the app ALWAYS gets a JSON response.
register_shutdown_function(function() {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        ob_clean();
        header("Content-Type: application/json; charset=UTF-8");
        echo json_encode(['success' => false, 'message' => 'Fatal error: ' . $error['message']]);
    }
});

header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format

include 'db_connect.php';
include 'logs_crud.php';

// Create table if not exists
$createTableSql = "CREATE TABLE IF NOT EXISTS reaccess_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    reason TEXT NOT NULL,
    contact_phone VARCHAR(20),
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    processed_by INT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci";
$conn->exec($createTableSql);

// Handle GET requests
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = $_GET['action'] ?? 'get_pending';
    
    if ($action === 'get_pending') {
        // Admin: get all pending requests with patient info
        $sql = "SELECT 
                    r.*,
                    p.full_name as patient_name,
                    p.national_id,
                    p.phone_number as patient_phone,
                    p.consecutive_missed_appointments,
                    u.username
                FROM reaccess_requests r
                JOIN patients p ON r.patient_id = p.patient_id
                JOIN users u ON p.user_id = u.user_id
                WHERE r.status = 'pending'
                ORDER BY r.created_at DESC";
        
        $stmt = $conn->query($sql);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } elseif ($action === 'get_all') {
        // Admin: get all requests
        $sql = "SELECT 
                    r.*,
                    p.full_name as patient_name,
                    p.national_id
                FROM reaccess_requests r
                JOIN patients p ON r.patient_id = p.patient_id
                ORDER BY r.created_at DESC";
        
        $stmt = $conn->query($sql);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } elseif ($action === 'check_existing') {
        // Check if patient already has a pending request
        $patientId = $_GET['patient_id'] ?? null;
        if ($patientId) {
            $stmt = $conn->prepare("SELECT * FROM reaccess_requests WHERE patient_id = ? AND status = 'pending'");
            $stmt->execute([$patientId]);
            $existing = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(['has_pending' => $existing ? true : false, 'request' => $existing]);
        } else {
            echo json_encode(['error' => 'patient_id required']);
        }
    }
    exit;
}

// Handle POST requests
$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from the Flutter app
$action = $data['action'] ?? '';

switch ($action) {
    case 'submit':
        // Patient submits re-access request
        try {
            $patientId = $data['patient_id'];
            $reason = $data['reason'];
            $contactPhone = $data['contact_phone'] ?? null;
            
            // Check for existing pending request
            $checkStmt = $conn->prepare("SELECT * FROM reaccess_requests WHERE patient_id = ? AND status = 'pending'");
            $checkStmt->execute([$patientId]);
            if ($checkStmt->fetch()) {
                echo json_encode(['success' => false, 'message' => 'You already have a pending request']);
                exit;
            }
            
            $sql = "INSERT INTO reaccess_requests (patient_id, reason, contact_phone) VALUES (?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->execute([$patientId, $reason, $contactPhone]);
            
            // Get patient name for log
            $pStmt = $conn->prepare("SELECT full_name FROM patients WHERE patient_id = ?");
            $pStmt->execute([$patientId]);
            $pName = $pStmt->fetchColumn();
            addSystemLog($conn, 'reaccess_submitted', "Re-access request submitted by patient: " . $pName, null, $pName, 'patient', 'patient', $patientId);
            
            echo json_encode(['success' => true, 'message' => 'Request submitted successfully']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    case 'approve':
        // Admin approves request
        try {
            $conn->beginTransaction();
            
            $requestId = $data['request_id'];
            $adminResponse = $data['admin_response'] ?? 'Your request has been approved';
            $adminId = $data['admin_id'] ?? null;
            
            // Get patient_id from request
            $reqStmt = $conn->prepare("SELECT patient_id FROM reaccess_requests WHERE request_id = ?");
            $reqStmt->execute([$requestId]);
            $request = $reqStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$request) {
                throw new Exception("Request not found");
            }
            
            // Update request status
            $updateReq = $conn->prepare(
                "UPDATE reaccess_requests SET status = 'approved', admin_response = ?, processed_at = NOW(), processed_by = ? WHERE request_id = ?"
            );
            $updateReq->execute([$adminResponse, $adminId, $requestId]);
            
            // Reset patient account
            $updatePatient = $conn->prepare(
                "UPDATE patients SET account_status = 'active', consecutive_missed_appointments = 0 WHERE patient_id = ?"
            );
            $updatePatient->execute([$request['patient_id']]);
            
            // Get patient name for log
            $pStmt = $conn->prepare("SELECT full_name FROM patients WHERE patient_id = ?");
            $pStmt->execute([$request['patient_id']]);
            $pName = $pStmt->fetchColumn();
            
            $conn->commit();
            
            // Log after commit
            try {
                addSystemLog($conn, 'reaccess_approved', "Re-access request approved for patient: " . $pName, $adminId, 'Admin', 'admin', 'patient', $request['patient_id']);
            } catch (Exception $logErr) {
                // Logging failed, but main operation succeeded - ignore
            }
            
            echo json_encode(['success' => true, 'message' => 'Request approved. Patient account reactivated.']);
        } catch (Exception $e) {
            if ($conn->inTransaction()) {
                $conn->rollBack();
            }
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    case 'reject':
        // Admin rejects request
        try {
            $requestId = $data['request_id'];
            $adminResponse = $data['admin_response'] ?? 'Your request has been rejected';
            $adminId = $data['admin_id'] ?? null;
            
            $sql = "UPDATE reaccess_requests SET status = 'rejected', admin_response = ?, processed_at = NOW(), processed_by = ? WHERE request_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->execute([$adminResponse, $adminId, $requestId]);
            
            // Get request info for log
            $rStmt = $conn->prepare("SELECT p.full_name, p.patient_id FROM reaccess_requests r JOIN patients p ON r.patient_id = p.patient_id WHERE r.request_id = ?");
            $rStmt->execute([$requestId]);
            $rInfo = $rStmt->fetch(PDO::FETCH_ASSOC);
            if ($rInfo) {
                addSystemLog($conn, 'reaccess_rejected', "Re-access request rejected for patient: " . $rInfo['full_name'], $adminId, 'Admin', 'admin', 'patient', $rInfo['patient_id']);
            }
            
            echo json_encode(['success' => true, 'message' => 'Request rejected']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>
