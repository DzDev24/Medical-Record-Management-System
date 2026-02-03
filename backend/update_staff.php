<?php
// update_staff.php

// 1. CONFIGURATION
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';

$data = json_decode(file_get_contents('php://input'), true); // Read the raw JSON data sent from app

$user_id = $data['user_id'];
$username = $data['username'];
// NOTE: Password might be empty string "" if the admin didn't change it.
$password = $data['password']; 
$role = $data['role'];
$full_name = $data['full_name'];
$extra_id = $data['extra_id']; // Specialty ID (Doctor) OR Department ID (Nurse)
$phone = $data['phone_number'];

try {
    // 2. TRANSACTION START
    // We are updating 'users' table AND 'doctors'/'nurses' table.
    $conn->beginTransaction();

    // STEP A: Update Basic Login Info (Username)
    // We always update the username.
    $stmt = $conn->prepare("UPDATE users SET username = ? WHERE user_id = ?");
    $stmt->execute([$username, $user_id]);

    // STEP B: Update Password
    // If the Admin left the password field blank in the app, we skip this step.
    if (!empty($password)) {
        // Hash the new password before saving
        $hash = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE user_id = ?");
        $stmt->execute([$hash, $user_id]);
    }

    // STEP C: Update Profile Details
    if ($role == 'doctor') {
        // For Doctors, update 'specialty_id'
        $stmt = $conn->prepare("UPDATE doctors SET full_name = ?, specialty_id = ?, phone_number = ? WHERE user_id = ?");
        $stmt->execute([$full_name, $extra_id, $phone, $user_id]);
    } else {
        // For Nurses, update 'department_id'
        $stmt = $conn->prepare("UPDATE nurses SET full_name = ?, department_id = ?, phone_number = ? WHERE user_id = ?");
        $stmt->execute([$full_name, $extra_id, $phone, $user_id]);
    }

    // Commit changes
    $conn->commit();
    echo json_encode(["success" => true, "message" => "Account updated successfully"]);

} catch (Exception $e) {
    // Rollback if anything fails
    $conn->rollBack();
    
    // 3. ERROR HANDLING (Duplicate Username)
    // If the admin tried to change the username to one that already exists, 
    // SQL throws a 'Duplicate entry' error. We catch it here to give a message.
    if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
        echo json_encode(["success" => false, "message" => "Username already taken"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
    }
}
?>