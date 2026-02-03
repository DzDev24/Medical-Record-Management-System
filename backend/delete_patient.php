<?php
// delete_patient.php


// Standard API headers to allow cross-origin requests (CORS) from your mobile app.
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
header("Access-Control-Allow-Methods: POST"); // Allow only POST requests
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'db_connect.php';


$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from app


// VALIDATION

if (empty($data['patient_id'])) {
    echo json_encode(['success' => false, 'message' => 'Patient ID is required']);
    exit;
}

$patient_id = intval($data['patient_id']);

try {
    
    // STEP 1: FIND THE LINKED USER ACCOUNT
    
    // Before we delete anything, we need to know which 'user_id' in the login table
    // corresponds to this patient.
    $stmt = $conn->prepare("SELECT user_id FROM patients WHERE patient_id = :patient_id");
    $stmt->bindParam(':patient_id', $patient_id);
    $stmt->execute();

    // Does this patient actually exist?
    if ($stmt->rowCount() == 0) {
        echo json_encode(['success' => false, 'message' => 'Patient not found']);
        exit;
    }
    
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $user_id = $row['user_id']; // Save this ID for Step 3

    
    // TRANSACTION START

    $conn->beginTransaction(); //use a transaction to ensure both deletions succeed or both fail.

    
    // STEP 2: DELETE PATIENT PROFILE
    //MUST delete the 'patients' record first because 'patients' table has a Foreign Key pointing to 'users'.
    $delPatient = $conn->prepare("DELETE FROM patients WHERE patient_id = :patient_id");
    $delPatient->bindParam(':patient_id', $patient_id);
    $delPatient->execute();

    
    // STEP 3: DELETE LOGIN ACCOUNT
    // Now that the dependency (child record) is gone, we can safely delete the parent record.
    $delUser = $conn->prepare("DELETE FROM users WHERE user_id = :user_id");
    $delUser->bindParam(':user_id', $user_id);
    $delUser->execute();

    // Commit: Make both deletions permanent
    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Patient deleted successfully']);

} catch (PDOException $e) {
    // Rollback: If anything fails, undelete everything
    $conn->rollBack();
    echo json_encode(['success' => false, 'message' => 'Delete failed: ' . $e->getMessage()]);
}
?>