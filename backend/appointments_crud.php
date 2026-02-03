<?php
// appointments_crud.php - CRUD operations for appointments


// 1. SYSTEM CONFIGURATION

error_reporting(0); // Turn off error display so that PHP warnings don't mess up our JSON output.
ini_set('display_errors', 0);


header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';
include 'logs_crud.php'; // We include this to record audit logs


// 2. GET REQUESTS (FETCHING DATA)

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = $_GET['action'] ?? 'get';
    
    // SCENARIO A: Fetch a list of appointments
    if ($action === 'get') {
        // Collect filters. If a filter is null, we ignore it.
        $doctorUserId = $_GET['doctor_user_id'] ?? null; // This is the 'user_id' from the login table
        $patientId = $_GET['patient_id'] ?? null; // This is the 'patient_id' from the patients table
        $status = $_GET['status'] ?? null; //'scheduled', 'completed', 'missed'
        
        $conditions = []; // Holds SQL conditions
        $params = []; // Holds parameters for prepared statement
        
        // COMPLEXITY 1: User ID vs Doctor ID
        // The app sends the 'user_id' (from login), but appointments are linked to 'doctor_id'.
        // We must first find the doctor_id associated with this user.
        if ($doctorUserId) {
            $doctorStmt = $conn->prepare("SELECT doctor_id FROM doctors WHERE user_id = ?");
            $doctorStmt->execute([$doctorUserId]);
            $doctorRow = $doctorStmt->fetch(PDO::FETCH_ASSOC); // Get the doctor_id
            if ($doctorRow) {
                $conditions[] = "a.doctor_id = ?";
                $params[] = $doctorRow['doctor_id'];
            }
        }
        
        if ($patientId) { 
            $conditions[] = "a.patient_id = ?";
            $params[] = $patientId;
        }
        
        if ($status) {
            $conditions[] = "a.status = ?";
            $params[] = $status;
        }
        
        // DYNAMIC QUERY BUILDING:
        // If we have conditions, add "WHERE ... AND ...". If not, leave it empty.
        $whereClause = count($conditions) > 0 ? "WHERE " . implode(" AND ", $conditions) : "";
        
        // We use LEFT JOIN to pull in the Patient Name and Doctor Name instead of just IDs.
        // We also fetch 'account_status' so the UI can show a red flag if the patient is restricted.
        $sql = "SELECT 
                    a.appointment_id,
                    a.patient_id,
                    a.doctor_id,
                    a.appointment_date,
                    a.reason_for_visit,
                    a.status,
                    a.created_at,
                    p.full_name as patient_name,
                    p.phone_number as patient_phone,
                    p.account_status as patient_account_status, 
                    d.full_name as doctor_name
                FROM appointments a
                LEFT JOIN patients p ON a.patient_id = p.patient_id
                LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
                $whereClause
                ORDER BY a.appointment_date DESC";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute($params);
        $appointments = $stmt->fetchAll(PDO::FETCH_ASSOC); // Fetch all matching records
        
        echo json_encode($appointments); // Return the list of appointments as JSON

    } elseif ($action === 'get_patients') {
        // SCENARIO B: Populate dropdown menu
        // Returns a simple list of all patients so the doctor can select one.
        $sql = "SELECT patient_id, full_name, phone_number, account_status FROM patients ORDER BY full_name";
        $stmt = $conn->query($sql);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC)); // Return as JSON
    }
    exit;
}


// 3. POST REQUESTS (MODIFYING DATA)

$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON sent by the app
$action = $data['action'] ?? ''; // What action to perform: add, update, update_status, delete

switch ($action) {
    
    // CASE 1: ADD NEW APPOINTMENT
    
    case 'add':
        try {
            // Step 1: Get the Doctor ID again
            $userId = $data['doctor_user_id'];
            $doctorStmt = $conn->prepare("SELECT doctor_id FROM doctors WHERE user_id = ?");
            $doctorStmt->execute([$userId]);
            $doctorRow = $doctorStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$doctorRow) {
                echo json_encode(['success' => false, 'message' => 'Doctor not found']);
                exit;
            }
            
            // Step 2: RESTRICTION CHECK
            // If the patient has been banned (restricted), stop immediately.
            $patientStmt = $conn->prepare("SELECT account_status FROM patients WHERE patient_id = ?");
            $patientStmt->execute([$data['patient_id']]);
            $patient = $patientStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($patient && $patient['account_status'] === 'restricted') { // Patient is restricted
                echo json_encode(['success' => false, 'message' => 'Cannot create appointment: Patient account is restricted']);
                exit;
            }
            
            // Step 3: CONFLICT DETECTION
            // We need to check if the doctor is already busy.
            // Logic: Is there any 'scheduled' appointment where the time difference 
            // is less than 15 minutes from the requested time?
            
            $appointmentDate = $data['appointment_date'];
            
            // SQL EXPLANATION:
            // TIMESTAMPDIFF(MINUTE, time1, time2) returns difference in minutes.
            // ABS() makes negative numbers positive (checking both before and after).
            // So: "Is the new time within +/- 14 minutes of an existing appointment?"
            $conflictStmt = $conn->prepare(
                "SELECT appointment_id, appointment_date, p.full_name as patient_name 
                 FROM appointments a 
                 LEFT JOIN patients p ON a.patient_id = p.patient_id
                 WHERE a.doctor_id = ? 
                 AND a.status = 'scheduled'
                 AND ABS(TIMESTAMPDIFF(MINUTE, a.appointment_date, ?)) < 15" //check for time conflict
            );
            $conflictStmt->execute([$doctorRow['doctor_id'], $appointmentDate]);
            $conflict = $conflictStmt->fetch(PDO::FETCH_ASSOC); // Fetch any conflicting appointment
            
            if ($conflict) {
                // Formatting date nicely for the error message
                $conflictTime = date('M d, Y H:i', strtotime($conflict['appointment_date']));
                echo json_encode([
                    'success' => false, 
                    'message' => "Time conflict: You already have an appointment with {$conflict['patient_name']} at {$conflictTime}"
                ]);
                exit;
            }
            
            // Step 4: No conflicts? Insert the record.
            $sql = "INSERT INTO appointments (patient_id, doctor_id, appointment_date, reason_for_visit, status) 
                    VALUES (?, ?, ?, ?, 'scheduled')";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['patient_id'],
                $doctorRow['doctor_id'],
                $data['appointment_date'],
                $data['reason_for_visit'] ?? ''
            ]);
            
            $appointmentId = $conn->lastInsertId(); // Get the new appointment ID
            
            // Step 5: Create a System Log (Audit Trail)
            addSystemLog($conn, 'appointment_created', "New appointment scheduled for " . date('M d, Y H:i', strtotime($data['appointment_date'])), null, null, null, 'appointment', $appointmentId);
            
            echo json_encode(['success' => true, 'message' => 'Appointment created', 'appointment_id' => $appointmentId]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    
    // CASE 2: UPDATE APPOINTMENT (Reschedule)
    
    case 'update':
        try {
            $appointmentId = $data['appointment_id']; // ID of appointment to update
            $appointmentDate = $data['appointment_date']; // New date/time
            
            // Get current appointment details
            $currentStmt = $conn->prepare("SELECT doctor_id FROM appointments WHERE appointment_id = ?");
            $currentStmt->execute([$appointmentId]);
            $current = $currentStmt->fetch(PDO::FETCH_ASSOC); // Fetch current record
            
            if (!$current) {
                echo json_encode(['success' => false, 'message' => 'Appointment not found']); //appointment not found
                exit;
            }
            
            // CONFLICT CHECK (Update Version)
            // This is almost identical to 'add', BUT we must exclude the current appointment ID, if we dont an appointment will always conflict with itself.

            $conflictStmt = $conn->prepare(
                "SELECT appointment_id, appointment_date, p.full_name as patient_name 
                 FROM appointments a 
                 LEFT JOIN patients p ON a.patient_id = p.patient_id
                 WHERE a.doctor_id = ? 
                 AND a.appointment_id != ? -- Exclude current appointment
                 AND a.status = 'scheduled'
                 AND ABS(TIMESTAMPDIFF(MINUTE, a.appointment_date, ?)) < 15"
            );
            $conflictStmt->execute([$current['doctor_id'], $appointmentId, $appointmentDate]);
            $conflict = $conflictStmt->fetch(PDO::FETCH_ASSOC); // Fetch any conflicting appointment
            
            if ($conflict) {
                $conflictTime = date('M d, Y H:i', strtotime($conflict['appointment_date']));
                echo json_encode([
                    'success' => false, 
                    'message' => "Time conflict: You already have an appointment with {$conflict['patient_name']} at {$conflictTime}"
                ]);
                exit;
            }
            
            // Update the record
            $sql = "UPDATE appointments SET appointment_date = ?, reason_for_visit = ? WHERE appointment_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $appointmentDate,
                $data['reason_for_visit'] ?? '', //optional
                $appointmentId
            ]);
            echo json_encode(['success' => true, 'message' => 'Appointment updated']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    
    // CASE 3: UPDATE STATUS ("THREE STRIKES RULE")
    // This handles completing or missing appointments.
   
    case 'update_status':
        try {
            // DATABASE TRANSACTION START
            //modifying two tables: 'appointments' AND 'patients'.
            // They must happen together or not at all.
            $conn->beginTransaction();
            
            $newStatus = $data['status']; // 'missed' or 'completed'
            $appointmentId = $data['appointment_id'];
            
            // Get patient ID associated with this appointment
            $apptStmt = $conn->prepare("SELECT patient_id FROM appointments WHERE appointment_id = ?");
            $apptStmt->execute([$appointmentId]);
            $appt = $apptStmt->fetch(PDO::FETCH_ASSOC); // Fetch appointment record
            
            if (!$appt) { //appointment not found
                throw new Exception("Appointment not found");
            }
            
            // 1. Update the appointment status (e.g., to 'missed' or 'completed')
            $sql = "UPDATE appointments SET status = ? WHERE appointment_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->execute([$newStatus, $appointmentId]);
            
            // 2. APPLY PENALTY LOGIC
            $patientRestricted = false;
            $patientName = '';

            if ($newStatus === 'missed') {
                //Patient missed the appointment.
                //Increment "consecutive_missed_appointments" counter.
                $updatePatient = $conn->prepare(
                    "UPDATE patients SET consecutive_missed_appointments = consecutive_missed_appointments + 1 WHERE patient_id = ?"
                );
                $updatePatient->execute([$appt['patient_id']]);
                
                // CHECK: Did they hit the limit of 3?
                $checkPatient = $conn->prepare("SELECT consecutive_missed_appointments, full_name FROM patients WHERE patient_id = ?");
                $checkPatient->execute([$appt['patient_id']]);
                $patientData = $checkPatient->fetch(PDO::FETCH_ASSOC);
                
                if ($patientData && $patientData['consecutive_missed_appointments'] >= 3) { //if 3 or more missed appointments
                    // STRIKE 3: Restrict the account.
                    // This prevents them from booking any new appointments (see Case 1 logic).
                    $restrictPatient = $conn->prepare("UPDATE patients SET account_status = 'restricted' WHERE patient_id = ?");
                    $restrictPatient->execute([$appt['patient_id']]);
                    $patientRestricted = true;
                    $patientName = $patientData['full_name'] ?? '';
                }

            } elseif ($newStatus === 'completed') {
                //if Patient attended the appointment.
                //Reset their missed counter to 0.
                $resetMissed = $conn->prepare("UPDATE patients SET consecutive_missed_appointments = 0 WHERE patient_id = ?");
                $resetMissed->execute([$appt['patient_id']]);
            }
            
            // COMMIT TRANSACTION
            // Save both the appointment status change AND the patient penalty/reset.
            $conn->commit();
            
            // 3. LOGGING
            if ($newStatus === 'missed') {
                try { addSystemLog($conn, 'appointment_missed', "Appointment marked as missed", null, null, null, 'appointment', $appointmentId); } catch (Exception $logEx) {} // Log the missed appointment
                
                // If they were just restricted, log that specific event too
                if ($patientRestricted) {
                    try { addSystemLog($conn, 'patient_restricted', "Patient account restricted due to 3+ missed appointments: " . $patientName, null, null, null, 'patient', $appt['patient_id']); } catch (Exception $logEx) {}
                }
            }
            
            echo json_encode(['success' => true, 'message' => 'Status updated']); // Inform the app of success

        } catch (Exception $e) {
            // ROLLBACK: If anything failed, undo changes to both tables.
            if ($conn->inTransaction()) {
                $conn->rollBack();
            }
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    
    // CASE 4: DELETE APPOINTMENT

    case 'delete':
        try {
            $sql = "DELETE FROM appointments WHERE appointment_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->execute([$data['appointment_id']]);
            echo json_encode(['success' => true, 'message' => 'Appointment deleted']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>