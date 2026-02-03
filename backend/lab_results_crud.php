<?php
// lab_results_crud.php - CRUD operations for lab results with file support

// 1. CONFIGURATION
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';

// Parse Input (supports both raw JSON body and GET parameters)
$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from app
$action = $data['action'] ?? $_GET['action'] ?? '';

switch ($action) {
    
    // CASE 1: ADD LAB RESULT
    case 'add':
        try {
            // 'result_file_path' stores the RELATIVE path (e.g., "uploads/lab_123.pdf")
            // The actual file upload is handled by a separate script (upload_lab_file.php)
            // which returns the path that we save here.
            $sql = "INSERT INTO lab_results (consultation_id, test_name, result_summary, result_file_path, test_date) 
                    VALUES (?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['consultation_id'],
                $data['test_name'] ?? '',
                $data['result_summary'] ?? '',
                $data['result_file_path'] ?? null, // Can be null if no file attached
                $data['test_date'] ?? date('Y-m-d')
            ]);
            echo json_encode(['success' => true, 'message' => 'Lab result added', 'result_id' => $conn->lastInsertId()]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    
    // CASE 2: UPDATE LAB RESULT
    case 'update':
        try {
            // LOGIC: Conditional Update
            // If the user uploaded a NEW file, we update the 'result_file_path' column.
            // If they just changed the text summary, we leave the file path alone.
            if (isset($data['result_file_path'])) {
                $sql = "UPDATE lab_results SET test_name = ?, result_summary = ?, result_file_path = ?, test_date = ? WHERE result_id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->execute([
                    $data['test_name'] ?? '',
                    $data['result_summary'] ?? '',
                    $data['result_file_path'],
                    $data['test_date'] ?? date('Y-m-d'),
                    $data['result_id']
                ]);
            } else {
                // No new file provided -> Keep existing file path
                $sql = "UPDATE lab_results SET test_name = ?, result_summary = ?, test_date = ? WHERE result_id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->execute([
                    $data['test_name'] ?? '',
                    $data['result_summary'] ?? '',
                    $data['test_date'] ?? date('Y-m-d'),
                    $data['result_id']
                ]);
            }
            echo json_encode(['success' => true, 'message' => 'Lab result updated']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    
    // CASE 3: DELETE LAB RESULT (File Cleanup)
    case 'delete':
        try {
            // STEP A: Fetch the file path BEFORE deleting the record.
            // Once the row is gone from SQL, we lose the filename.
            $stmt = $conn->prepare("SELECT result_file_path FROM lab_results WHERE result_id = ?");
            $stmt->execute([$data['result_id']]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // STEP B: Delete the database record
            $delStmt = $conn->prepare("DELETE FROM lab_results WHERE result_id = ?");
            $delStmt->execute([$data['result_id']]);
            
            // STEP C: Delete the actual file from the server disk
            // This frees up hard drive space.
            if ($row && $row['result_file_path']) {
                $filePath = __DIR__ . '/' . $row['result_file_path']; // __DIR__ gets current folder
                if (file_exists($filePath)) {
                    unlink($filePath); // 'unlink' is the PHP command to delete a file
                }
            }
            
            echo json_encode(['success' => true, 'message' => 'Lab result deleted']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    
    // CASE 4: GET LAB RESULTS
    case 'get':
        // Fetch all lab results linked to a specific consultation
        $consultationId = $data['consultation_id'] ?? $_GET['consultation_id'] ?? null;
        if ($consultationId) {
            $stmt = $conn->prepare("SELECT * FROM lab_results WHERE consultation_id = ? ORDER BY test_date DESC");
            $stmt->execute([$consultationId]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } else {
            echo json_encode([]);
        }
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>