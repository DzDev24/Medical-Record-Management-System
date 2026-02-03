<?php
// get_patient_full_records.php


// 1. SETUP & HEADERS
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';

// Get the logged-in User ID
$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    echo json_encode(['error' => 'user_id required']);
    exit;
}

try {
    
    // 2. IDENTIFY PATIENT
    // The app knows "User ID 5", but the database tracks medical records by "Patient ID 101".
    // We must find the Patient profile linked to this User account.
    $patientStmt = $conn->prepare("SELECT * FROM patients WHERE user_id = ?");
    $patientStmt->execute([$userId]);
    $patient = $patientStmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$patient) {
        echo json_encode(['error' => 'Patient not found']);
        exit;
    }
    
    $patientId = $patient['patient_id'];
    
    
    // 3. FETCH CONSULTATION HISTORY (Master Record)
    // We fetch all past visits, joining with the Doctor table to get names.
    $consultationsSql = "SELECT 
                            c.consultation_id,
                            c.appointment_id,
                            c.visit_date,
                            c.diagnosis,
                            c.symptoms,
                            c.doctor_notes,
                            d.full_name as doctor_name,
                            a.appointment_date
                        FROM consultations c
                        LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
                        LEFT JOIN appointments a ON c.appointment_id = a.appointment_id
                        WHERE c.patient_id = ?
                        ORDER BY c.visit_date DESC"; // Newest visits first
    
    $consultationsStmt = $conn->prepare($consultationsSql);
    $consultationsStmt->execute([$patientId]);
    $consultations = $consultationsStmt->fetchAll(PDO::FETCH_ASSOC);
    
    
    // 4. NESTED DATA HYDRATION
    // We loop through each visit and fetch its specific details (medications, lab results).
    foreach ($consultations as &$consultation) {
        // Fetch Meds for this specific visit
        $prescStmt = $conn->prepare("SELECT * FROM prescriptions WHERE consultation_id = ?");
        $prescStmt->execute([$consultation['consultation_id']]);
        $consultation['prescriptions'] = $prescStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Fetch Lab Results for this specific visit
        $labStmt = $conn->prepare("SELECT * FROM lab_results WHERE consultation_id = ?");
        $labStmt->execute([$consultation['consultation_id']]);
        $consultation['lab_results'] = $labStmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    
    // 5. FLATTENED LISTS (For "All History" Views)
    // Sometimes the patient just wants to see "All my medicines" without clicking through every consultation.
    // We run separate queries to get these flat lists.
    
    // Get ALL prescriptions ever given to this patient
    $allPrescSql = "SELECT p.*, c.visit_date, d.full_name as doctor_name
                    FROM prescriptions p
                    JOIN consultations c ON p.consultation_id = c.consultation_id
                    LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
                    WHERE c.patient_id = ?
                    ORDER BY p.prescription_id DESC";
    $allPrescStmt = $conn->prepare($allPrescSql);
    $allPrescStmt->execute([$patientId]);
    $allPrescriptions = $allPrescStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get ALL lab results ever attached to this patient
    $allLabSql = "SELECT lr.*, c.visit_date, d.full_name as doctor_name
                  FROM lab_results lr
                  JOIN consultations c ON lr.consultation_id = c.consultation_id
                  LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
                  WHERE c.patient_id = ?
                  ORDER BY lr.test_date DESC";
    $allLabStmt = $conn->prepare($allLabSql);
    $allLabStmt->execute([$patientId]);
    $allLabResults = $allLabStmt->fetchAll(PDO::FETCH_ASSOC);
    
    
    // 6. FETCH APPOINTMENTS
    $appointmentsSql = "SELECT 
                            a.*,
                            d.full_name as doctor_name
                        FROM appointments a
                        LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
                        WHERE a.patient_id = ?
                        ORDER BY a.appointment_date DESC";
    $appointmentsStmt = $conn->prepare($appointmentsSql);
    $appointmentsStmt->execute([$patientId]);
    $appointments = $appointmentsStmt->fetchAll(PDO::FETCH_ASSOC);
    
    
    // 7. BUILD FINAL RESPONSE & STATS
    // We bundle everything into one big JSON object.
    // We also calculate "stats" here so the mobile app doesn't have to do math.
    echo json_encode([
        'success' => true,
        'patient' => $patient,
        'consultations' => $consultations,   // Nested Structure (Visit -> Meds)
        'prescriptions' => $allPrescriptions, // Flat List
        'lab_results' => $allLabResults,      // Flat List
        'appointments' => $appointments,
        'stats' => [
            'total_consultations' => count($consultations),
            'total_prescriptions' => count($allPrescriptions),
            'total_lab_results' => count($allLabResults),
            'total_appointments' => count($appointments),
            // Calculate how many appointments are in the future
            'upcoming_appointments' => count(array_filter($appointments, function($a) {
                return $a['status'] === 'scheduled' && strtotime($a['appointment_date']) > time();
            }))
        ]
    ]);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>