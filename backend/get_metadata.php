<?php
// get_metadata.php


// 1. HEADERS & SETUP
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';

try {
    // Initialize an empty array to hold our combined data
    $data = [];


    // 2. FETCH SPECIALTIES (For Doctors)
    // We rename the column to just 'id'. This makes the Flutter code easier 
    // because it can treat both specialties and departments as generic "items" with an 'id'.
    $stmt = $conn->query("SELECT specialty_id as id, name FROM specialties");
    
    // Store the result list in the 'specialties' key of our main array
    $data['specialties'] = $stmt->fetchAll(PDO::FETCH_ASSOC);

    
    // 3. FETCH DEPARTMENTS (For Nurses)
    // We do the same renaming here: "department_id as id"
    $stmt = $conn->query("SELECT department_id as id, name FROM departments");
    
    // Store the result list in the 'departments' key
    $data['departments'] = $stmt->fetchAll(PDO::FETCH_ASSOC);

    
    // 4. SEND BATCH RESPONSE
    // Convert the combined array into a single JSON object.
    echo json_encode($data);

} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>