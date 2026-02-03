<?php

// 1. API HEADERS


header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Return data in JSON format
include 'db_connect.php';

// 2. INPUT HANDLING


$data = json_decode(file_get_contents('php://input'), true); // Read the raw JSON sent by the mobile app

$username = $data['username']; 
$password = password_hash($data['password'], PASSWORD_DEFAULT);
$role = $data['role'];
$full_name = $data['full_name'];

$extra_id = $data['extra_id']; // If Role is Doctor, this is the 'Specialty ID', if Nurse, 'Department ID'.
$phone = $data['phone_number'];

try {
    
// 3. DATABASE TRANSACTION
    
    $conn->beginTransaction(); // 'beginTransaction' ensures that EITHER both inserts to tables succeed OR both fail.

    // STEP 1: Create the Login Account
    $stmt = $conn->prepare("INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)");
    $stmt->execute([$username, $password, $role]);
    
    
    // We need the ID of the user we just created to link it to their profile for foreign key linking.
    $user_id = $conn->lastInsertId();

    // STEP B: Create the Profile based on Role
    if ($role == 'doctor') {
        // Doctors get a 'specialty_id'
        $stmt = $conn->prepare("INSERT INTO doctors (user_id, full_name, specialty_id, phone_number) VALUES (?, ?, ?, ?)");
        $stmt->execute([$user_id, $full_name, $extra_id, $phone]);
    } else {
        // Nurses get a 'department_id'
        $stmt = $conn->prepare("INSERT INTO nurses (user_id, full_name, department_id, phone_number) VALUES (?, ?, ?, ?)");
        $stmt->execute([$user_id, $full_name, $extra_id, $phone]);
    }

   
    // 4. COMMIT CHANGES
    
    // If we reached this line, both inserts worked. Save changes permanently.
    $conn->commit();
    echo json_encode(["success" => true, "message" => "Staff added successfully"]);

} catch (Exception $e) {
    
    // 5. ROLLBACK ON ERROR
   
    // If an error occurred (e.g., username taken), undo ALL changes.
    $conn->rollBack();
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>