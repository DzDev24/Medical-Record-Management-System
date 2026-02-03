<?php
// get_patient_appointments.php


// 1. HEADERS & SETUP
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';

// Get the User ID passed from the mobile app (e.g., ?user_id=5)
$userId = $_GET['user_id'] ?? null;

//If no ID is sent, return an empty list immediately.
if (!$userId) {
    echo json_encode([]);
    exit;
}

try {
    
    // 2. ID TRANSLATION (The "Bridge")
    // The mobile app only knows the 'user_id' (from the login session).
    // However, the appointments table links to 'patient_id'.
    // We must first look up which patient profile belongs to this user.
    $patientStmt = $conn->prepare("SELECT patient_id FROM patients WHERE user_id = ?");
    $patientStmt->execute([$userId]);
    $patient = $patientStmt->fetch(PDO::FETCH_ASSOC);
    
    //If this user isn't a patient (e.g., a doctor trying to use this API), stop.
    if (!$patient) {
        echo json_encode([]);
        exit;
    }
    
    $patientId = $patient['patient_id'];
    
    // 3. FETCH APPOINTMENTS
    // We use a LEFT JOIN to pull the Doctor's Name.
    $sql = "SELECT 
                a.appointment_id,
                a.patient_id,
                a.doctor_id,
                a.appointment_date,
                a.reason_for_visit,
                a.status,
                a.created_at,
                d.full_name as doctor_name
            FROM appointments a
            LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
            WHERE a.patient_id = ?
            ORDER BY a.appointment_date DESC"; // Show newest appointments first
    
    $stmt = $conn->prepare($sql);
    $stmt->execute([$patientId]);
    $appointments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Send the list back to Flutter
    echo json_encode($appointments);
    
} catch (Exception $e) {
    // On error, return empty list so the app doesn't crash
    echo json_encode([]);
}
?>