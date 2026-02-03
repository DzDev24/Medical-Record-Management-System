<?php
// consultations_crud.php - CRUD operations for consultations


// CONFIGURATION

header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';


// GET REQUESTS (FETCH DATA)

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = $_GET['action'] ?? 'get';
    
    //Get a Patient's Full Medical History
    if ($action === 'get') {
        $patientId = $_GET['patient_id'] ?? null;
        
        if (!$patientId) {
            echo json_encode(['error' => 'patient_id required']);
            exit;
        }
        
        // STEP 1: Fetch the Main Consultation Records
        // We calculate counts (prescription_count, lab_result_count) using sub-queries 
        // so the UI can show badges like "3 Medicines" on the list view.
        $sql = "SELECT 
                    c.consultation_id,
                    c.appointment_id,
                    c.patient_id,
                    c.doctor_id,
                    c.visit_date,
                    c.diagnosis,
                    c.symptoms,
                    c.doctor_notes,
                    d.full_name as doctor_name,
                    a.appointment_date,
                    (SELECT COUNT(*) FROM prescriptions p WHERE p.consultation_id = c.consultation_id) as prescription_count,
                    (SELECT COUNT(*) FROM lab_results lr WHERE lr.consultation_id = c.consultation_id) as lab_result_count
                FROM consultations c
                LEFT JOIN doctors d ON c.doctor_id = d.doctor_id -- to get doctor's name
                LEFT JOIN appointments a ON c.appointment_id = a.appointment_id -- to get appointment date
                WHERE c.patient_id = ? -- Filter by Patient ID
                ORDER BY c.visit_date DESC";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute([$patientId]);
        $consultations = $stmt->fetchAll(PDO::FETCH_ASSOC); // Fetch as associative array
        
        // STEP 2: HYDRATE DATA (Nested Data Fetching)
        // We loop through every consultation and manually fetch its related items (prescriptions, lab results).
        // This builds a complete JSON object like: { diagnosis: "Flu", prescriptions: [...], lab_results: [...] }
        foreach ($consultations as &$consultation) {
            // Fetch Prescriptions for this specific ID
            $prescStmt = $conn->prepare("SELECT * FROM prescriptions WHERE consultation_id = ?");
            $prescStmt->execute([$consultation['consultation_id']]);
            $consultation['prescriptions'] = $prescStmt->fetchAll(PDO::FETCH_ASSOC); // Fetch as associative array
            
            // Fetch Lab Results for this specific ID
            $labStmt = $conn->prepare("SELECT * FROM lab_results WHERE consultation_id = ?");
            $labStmt->execute([$consultation['consultation_id']]);
            $consultation['lab_results'] = $labStmt->fetchAll(PDO::FETCH_ASSOC); // Fetch as associative array
        }
        
        echo json_encode($consultations); // Return the full data as JSON
    }
    exit;
}


// POST REQUESTS (MODIFY DATA)

$data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from the Flutter app
$action = $data['action'] ?? '';

switch ($action) {
    
    // ADD CONSULTATION (Complex Transaction)
    
    case 'add':
        try {
            // START TRANSACTION
            // We are inserting into THREE tables at once: 
            // 1. consultations, 2. prescriptions, 3. lab_results
            // They must all succeed together.
            $conn->beginTransaction();
            
            // 1. Security Check: Resolve UserID to DoctorID
            $userId = $data['doctor_id']; // This is actually user_id from Flutter
            $doctorStmt = $conn->prepare("SELECT doctor_id FROM doctors WHERE user_id = ?");
            $doctorStmt->execute([$userId]);
            $doctorRow = $doctorStmt->fetch(PDO::FETCH_ASSOC); 
            
            if (!$doctorRow) {
                throw new Exception("Doctor not found for user_id: $userId");
            }
            
            $actualDoctorId = $doctorRow['doctor_id'];
            
            // 2. Insert the Parent Record (Consultation)
            $sql = "INSERT INTO consultations (patient_id, doctor_id, diagnosis, symptoms, doctor_notes, appointment_id, visit_date) 
                    VALUES (?, ?, ?, ?, ?, ?, NOW())";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['patient_id'],
                $actualDoctorId,
                $data['diagnosis'] ?? '',
                $data['symptoms'] ?? '',
                $data['doctor_notes'] ?? '',
                $data['appointment_id']
            ]);
            
            // We need this new consultation ID to link the prescriptions/labs to it
            $consultationId = $conn->lastInsertId();
            
            // 3. Insert Prescriptions (Loop)
            if (!empty($data['prescriptions'])) {
                $prescSql = "INSERT INTO prescriptions (consultation_id, medication_name, dosage, frequency, duration) VALUES (?, ?, ?, ?, ?)";
                $prescStmt = $conn->prepare($prescSql);
                
                // Loop through the array sent from Flutter
                foreach ($data['prescriptions'] as $presc) {
                    $prescStmt->execute([
                        $consultationId, // Link to parent
                        $presc['medication_name'] ?? '',
                        $presc['dosage'] ?? '',
                        $presc['frequency'] ?? '',
                        $presc['duration'] ?? ''
                    ]);
                }
            }
            
            // 4. Insert Lab Results (Loop)
            if (!empty($data['lab_results'])) {
                $labSql = "INSERT INTO lab_results (consultation_id, test_name, result_summary, result_file_path, test_date) VALUES (?, ?, ?, ?, ?)";
                $labStmt = $conn->prepare($labSql);
                
                foreach ($data['lab_results'] as $lab) {
                    $labStmt->execute([
                        $consultationId, // Link to parent
                        $lab['test_name'] ?? '',
                        $lab['result_summary'] ?? '',
                        $lab['result_file_path'] ?? null, // File path uploaded previously
                        $lab['test_date'] ?? date('Y-m-d')
                    ]);
                }
            }
            
            // COMMIT: Save all 3 steps to the database
            $conn->commit();
            echo json_encode(['success' => true, 'message' => 'Consultation added', 'consultation_id' => $consultationId]);
        } catch (Exception $e) {
            $conn->rollBack();
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    // ------------------------------------------
    // UPDATE CONSULTATION (Basic Info Only)
    // ------------------------------------------
    case 'update':
        try {
            $sql = "UPDATE consultations SET diagnosis = ?, symptoms = ?, doctor_notes = ? WHERE consultation_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->execute([
                $data['diagnosis'] ?? '',
                $data['symptoms'] ?? '',
                $data['doctor_notes'] ?? '',
                $data['consultation_id']
            ]);
            echo json_encode(['success' => true, 'message' => 'Consultation updated']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    // ------------------------------------------
    // DELETE CONSULTATION (Cascading Delete)
    // ------------------------------------------
    case 'delete':
        try {
            $conn->beginTransaction();
            
            
            // We cannot delete the Consultation first because the Prescriptions depend on it.
            // We must delete the "Children" (details) before the "Parent" (master).
            
            // 1. Delete associated prescriptions
            $prescDel = $conn->prepare("DELETE FROM prescriptions WHERE consultation_id = ?");
            $prescDel->execute([$data['consultation_id']]);
            
            // 2. Delete associated lab results
            $labDel = $conn->prepare("DELETE FROM lab_results WHERE consultation_id = ?");
            $labDel->execute([$data['consultation_id']]);
            
            // 3. Finally, delete the consultation itself
            $consDel = $conn->prepare("DELETE FROM consultations WHERE consultation_id = ?");
            $consDel->execute([$data['consultation_id']]);
            
            $conn->commit();
            echo json_encode(['success' => true, 'message' => 'Consultation deleted']);
        } catch (Exception $e) {
            $conn->rollBack();
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>