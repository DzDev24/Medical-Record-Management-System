<?php

// HEADERS & CONFIGURATION

header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
header("Access-Control-Allow-Methods: POST"); // Allow only POST requests
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With"); // Allow these headers
require_once 'db_connect.php'; // Include the database connection script


// INPUT HANDLING

// Read the raw JSON data sent from the Flutter app
// file_get_contents("php://input") reads the request body
$data = json_decode(file_get_contents("php://input"), true);


$required = ['full_name', 'national_id', 'password', 'date_of_birth', 'gender', 'blood_type', 'phone']; // List of fields that MUST be present

foreach ($required as $field) { // Loop through required fields to ensure none are missing
    if (empty($data[$field])) {
        echo json_encode(['success' => false, 'message' => "Missing required field: $field"]); // Stop execution and tell the app what is missing
        exit;
    }
}

// ==========================================
// DATA PREPARATION & SECURITY
// ==========================================

$full_name = trim($data['full_name']); // Clean up whitespace
$national_id = trim($data['national_id']);
$password = password_hash($data['password'], PASSWORD_DEFAULT); 
$dob = trim($data['date_of_birth']);
$gender = trim($data['gender']);
$blood_type = trim($data['blood_type']);
$phone = trim($data['phone']);
$address = isset($data['address']) ? trim($data['address']) : ''; // Optional field

try {
    // 1. Check if a user with this National ID already exists to prevent duplicates
    $checkStmt = $conn->prepare("SELECT user_id FROM users WHERE username = :national_id");
    $checkStmt->bindParam(':national_id', $national_id); 
    $checkStmt->execute();
    
    if ($checkStmt->rowCount() > 0) {
        echo json_encode(['success' => false, 'message' => 'A patient with this National ID already exists']); // Stop execution if duplicate found
        exit;
    }


    // DATABASE TRANSACTION (CRITICAL PART)

    // 'beginTransaction' ensures that EITHER both inserts succeed OR both fail.
    $conn->beginTransaction();

    // STEP 1: Create the User Account (Login Credentials)
    // We use the National ID as the username for patients
    $userStmt = $conn->prepare("INSERT INTO users (username, password_hash, role) VALUES (:username, :password, 'patient')");
    $userStmt->bindParam(':username', $national_id);
    $userStmt->bindParam(':password', $password);
    $userStmt->execute();
    
    // CAPTURE THE ID: Get the auto-generated ID of the user we just created
    $user_id = $conn->lastInsertId();

    // STEP 2: Create the Medical Record (Profile Info)
    // We link this record to the account using 'user_id'
    $patientStmt = $conn->prepare("INSERT INTO patients (user_id, national_id, full_name, date_of_birth, gender, blood_type, phone_number, address, account_status) 
                                   VALUES (:user_id, :national_id, :full_name, :dob, :gender, :blood_type, :phone, :address, 'active')");
    $patientStmt->bindParam(':user_id', $user_id); // Linking foreign key
    $patientStmt->bindParam(':national_id', $national_id); //bind param means to bind the variable to the placeholder in the SQL statement 
    $patientStmt->bindParam(':full_name', $full_name);
    $patientStmt->bindParam(':dob', $dob);
    $patientStmt->bindParam(':gender', $gender);
    $patientStmt->bindParam(':blood_type', $blood_type);
    $patientStmt->bindParam(':phone', $phone);
    $patientStmt->bindParam(':address', $address);
    $patientStmt->execute();

    // STEP 3: Commit the Transaction
    
    $conn->commit(); // If code reaches here, both inserts worked. Save changes permanently.
    
    echo json_encode(['success' => true, 'message' => 'Patient registered successfully', 'user_id' => $user_id]); // Inform the app of success

} catch (PDOException $e) {
    // STEP 4: Rollback on Error
    // If ANY error happened above, undo everything. 
    $conn->rollBack();
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]); // Inform the app of failure
}
?>