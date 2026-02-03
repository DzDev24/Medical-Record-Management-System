<?php
// prescriptions_crud.php - CRUD operations for prescriptions


// 1. CONFIGURATION
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';

// 2. INPUT PARSING
// Standard pattern: Read raw input, decode JSON, and get the 'action'.
$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from app
// Fallback: If 'action' isn't in the JSON body, check the URL (e.g. ?action=get)
$action = $data['action'] ?? $_GET['action'] ?? '';

switch ($action) {
    // CASE 1: ADD PRESCRIPTION
    case 'add':
        try {
            // We insert a new row linked to the parent 'consultation_id'.
            // Note: We use '??' (Null Coalescing Operator) to provide empty strings 
            // if optional fields like 'duration' are missing.
            $sql = "INSERT INTO prescriptions (consultation_id, medication_name, dosage, frequency, duration) 
                    VALUES (?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['consultation_id'],
                $data['medication_name'] ?? '',
                $data['dosage'] ?? '',
                $data['frequency'] ?? '',
                $data['duration'] ?? ''
            ]);
            
            // Return the new ID so the UI can update the list instantly without reloading
            echo json_encode(['success' => true, 'message' => 'Prescription added', 'prescription_id' => $conn->lastInsertId()]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    // ------------------------------------------
    // CASE 2: UPDATE PRESCRIPTION
    // ------------------------------------------
    case 'update':
        try {
            // Standard update. We identify the row by 'prescription_id'.
            $sql = "UPDATE prescriptions SET medication_name = ?, dosage = ?, frequency = ?, duration = ? WHERE prescription_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['medication_name'] ?? '',
                $data['dosage'] ?? '',
                $data['frequency'] ?? '',
                $data['duration'] ?? '',
                $data['prescription_id']
            ]);
            echo json_encode(['success' => true, 'message' => 'Prescription updated']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    // ------------------------------------------
    // CASE 3: DELETE PRESCRIPTION
    // ------------------------------------------
    case 'delete':
        try {
            // Simple deletion. Since Prescriptions are "Leaf Nodes" (they don't have children),
            // we can delete them directly without worrying about cascading errors.
            $stmt = $conn->prepare("DELETE FROM prescriptions WHERE prescription_id = ?");
            $stmt->execute([$data['prescription_id']]);
            echo json_encode(['success' => true, 'message' => 'Prescription deleted']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    // ------------------------------------------
    // CASE 4: GET PRESCRIPTIONS
    // ------------------------------------------
    case 'get':
        // Fetch all meds linked to a specific consultation
        // We accept consultation_id from either POST body or GET URL
        $consultationId = $data['consultation_id'] ?? $_GET['consultation_id'] ?? null;
        
        if ($consultationId) {
            $stmt = $conn->prepare("SELECT * FROM prescriptions WHERE consultation_id = ?");
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