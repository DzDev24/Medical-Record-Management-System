<?php
// get_staff.php

// 1. HEADERS
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';


// 2. INPUTS
// We get the role to know WHICH table to look in (doctors vs nurses).
$role = $_GET['role']; 

// We get the search term (optional). Default is empty string "".
$search = $_GET['search'] ?? ""; 
$searchTerm = "%$search%"; // Add wildcards for partial matching


// 3. DYNAMIC QUERY BUILDING
// Depending on the role, we construct a completely different SQL query.

if ($role == 'doctor') {
    // PATH A: Fetch Doctors
    // We join THREE tables:
    // 1. users (for login info/ID)
    // 2. doctors (for name & phone)
    // 3. specialties (to get "Cardiology" instead of just ID '5')
    
    // ALIASING: "s.name as extra_info"
    // We rename 'specialty name' to 'extra_info' so the app treats it generically.
    $sql = "SELECT u.user_id, u.username, d.full_name, d.phone_number, 
                   s.name as extra_info, d.specialty_id as extra_id 
            FROM users u 
            JOIN doctors d ON u.user_id = d.user_id 
            JOIN specialties s ON d.specialty_id = s.specialty_id
            WHERE u.role = 'doctor' AND (d.full_name LIKE ? OR u.username LIKE ?)";

} else {
    // PATH B: Fetch Nurses
    // We join users -> nurses -> departments.
    
    // ALIASING: "dep.name as extra_info"
    // We rename 'department name' to 'extra_info'.
    // Now, the mobile app receives 'extra_info' regardless of whether it's a doctor or nurse.
    $sql = "SELECT u.user_id, u.username, n.full_name, n.phone_number, 
                   dep.name as extra_info, n.department_id as extra_id
            FROM users u 
            JOIN nurses n ON u.user_id = n.user_id 
            JOIN departments dep ON n.department_id = dep.department_id
            WHERE u.role = 'nurse' AND (n.full_name LIKE ? OR u.username LIKE ?)";
}

// 4. EXECUTION
$stmt = $conn->prepare($sql);

// We pass $searchTerm twice because we have two '?' placeholders:
// 1. d.full_name LIKE ?
// 2. u.username LIKE ?
$stmt->execute([$searchTerm, $searchTerm]);

echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
?>