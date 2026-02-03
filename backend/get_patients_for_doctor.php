<?php
// get_patients_for_doctor.php


// 1. HEADERS & SETUP
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';


// 2. SEARCH PREPARATION
// Get the search text from the URL (e.g., ?query=Sarah)
$query = $_GET['query'] ?? "";

// Wrap it in wildcards (%) for SQL "partial match" searching
// "Sarah" becomes "%Sarah%" -> finds "Sarah Jones", "Dr. Sarah", etc.
$searchTerm = "%$query%";

// 3. THE QUERY (CLINICAL OVERVIEW)
// This query does more than just list names. It uses SUBQUERIES to calculate
// summary statistics on the fly.
$sql = "SELECT 
            p.patient_id, 
            p.national_id, 
            p.full_name, 
            p.date_of_birth, 
            p.gender, 
            p.blood_type, 
            p.phone_number, 
            p.address, 
            p.account_status,
            
            -- SUBQUERY 1: Count total past visits
            -- This lets the doctor see 'New Patient' (0 visits) vs 'Regular' (10+ visits)
            (SELECT COUNT(*) FROM consultations c WHERE c.patient_id = p.patient_id) as consultation_count,
            
            -- SUBQUERY 2: Find the most recent visit date
            -- Helpful for sorting or seeing who hasn't been seen in a while
            (SELECT MAX(c.visit_date) FROM consultations c WHERE c.patient_id = p.patient_id) as last_visit
            
        FROM patients p
        WHERE p.full_name LIKE ? OR p.national_id LIKE ?
        ORDER BY p.full_name ASC";

$stmt = $conn->prepare($sql);

// We pass $searchTerm twice because there are two '?' placeholders (Name OR ID)
$stmt->execute([$searchTerm, $searchTerm]);

// Return the list as JSON
echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
?>