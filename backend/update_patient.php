<?php
// update_patient.php

// 1. HEADERS & SETUP
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
header("Access-Control-Allow-Methods: POST"); // Allow only POST requests
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'db_connect.php';

// Read JSON input
$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from app

// 2. VALIDATION
// We need the Patient ID to know WHO to update.
if (empty($data['patient_id'])) {
    echo json_encode(['success' => false, 'message' => 'Patient ID is required']);
    exit;
}

$patient_id = intval($data['patient_id']);
// We need user_id only if we are updating the password (since password lives in 'users' table)
$user_id = isset($data['user_id']) ? intval($data['user_id']) : null;

try {
    // 3. TRANSACTION START
    // We might update two tables (patients + users). Both must succeed.
    $conn->beginTransaction();

    // 4. DYNAMIC QUERY BUILDING
    // Instead of writing a massive "UPDATE patients SET name=?, phone=?, address=?..." query,
    // we build it piece by piece. If the app didn't send a new address, we don't touch the old one.
    
    $updates = []; // Stores strings like "full_name = :full_name"
    $params = [':patient_id' => $patient_id]; // Stores the actual values
    
    // Check each field. If it exists in the input, add it to the update list.
    if (isset($data['full_name']) && !empty($data['full_name'])) {
        $updates[] = "full_name = :full_name";
        $params[':full_name'] = trim($data['full_name']);
    }
    if (isset($data['date_of_birth']) && !empty($data['date_of_birth'])) {
        $updates[] = "date_of_birth = :dob";
        $params[':dob'] = trim($data['date_of_birth']);
    }
    if (isset($data['gender']) && !empty($data['gender'])) {
        $updates[] = "gender = :gender";
        $params[':gender'] = trim($data['gender']);
    }
    if (isset($data['blood_type']) && !empty($data['blood_type'])) {
        $updates[] = "blood_type = :blood_type";
        $params[':blood_type'] = trim($data['blood_type']);
    }
    if (isset($data['phone']) && !empty($data['phone'])) {
        $updates[] = "phone_number = :phone";
        $params[':phone'] = trim($data['phone']);
    }
    if (isset($data['address'])) {
        $updates[] = "address = :address";
        $params[':address'] = trim($data['address']);
    }

    // 5. EXECUTE DYNAMIC UPDATE
    // Only run the query if there are actual changes to make.
    if (!empty($updates)) {
        // implode(", ", $updates) turns the array into a comma-separated string.
        // Result: "UPDATE patients SET full_name = :full_name, phone_number = :phone WHERE patient_id = :patient_id"
        $sql = "UPDATE patients SET " . implode(", ", $updates) . " WHERE patient_id = :patient_id";
        $stmt = $conn->prepare($sql);
        $stmt->execute($params);
    }

    // ==========================================
    // 6. PASSWORD UPDATE (Optional)
    // ==========================================
    // Passwords live in the 'users' table, not 'patients'. 
    // We update this separately only if a new password was provided.
    if (!empty($data['password']) && $user_id) {
        $password_hash = password_hash($data['password'], PASSWORD_DEFAULT);
        $pwdStmt = $conn->prepare("UPDATE users SET password_hash = :password WHERE user_id = :user_id");
        $pwdStmt->bindParam(':password', $password_hash);
        $pwdStmt->bindParam(':user_id', $user_id);
        $pwdStmt->execute();
    }

    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Patient updated successfully']);

} catch (PDOException $e) {
    $conn->rollBack();
    echo json_encode(['success' => false, 'message' => 'Update failed: ' . $e->getMessage()]);
}
?>
