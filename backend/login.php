<?php
// login.php - Central Authentication Handler

// 1. CONFIGURATION
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
include 'db_connect.php';
include 'logs_crud.php'; // For recording login events

// Get JSON Input from Flutter App
$input = json_decode(file_get_contents('php://input'), true);

$login_type = $input['login_type']; // Determines path: 'staff' vs 'patient'
$password = $input['password'];

// 2. USER RETRIEVAL LOGIC

if ($login_type == 'patient') {
    
    // PATH A: PATIENT LOGIN
    // Patients log in using National ID + Full Name (No username)
    $national_id = $input['national_id'];
    $full_name = $input['full_name'];

    // Join 'users' table with 'patients' table to find a match
    $sql = "SELECT u.user_id, u.password_hash, u.role, u.is_active, p.account_status, p.full_name
            FROM users u
            JOIN patients p ON u.user_id = p.user_id
            WHERE p.national_id = ? AND p.full_name = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->execute([$national_id, $full_name]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

} else {
    
    // PATH B: STAFF LOGIN (Admin/Doctor/Nurse)
    // Staff log in using Username
    $username = $input['username'];

    // Find User via Users Table
    $sql = "SELECT user_id, password_hash, role, is_active FROM users WHERE username = ?";
    $stmt = $conn->prepare($sql);
    $stmt->execute([$username]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // If found, we need to fetch their "Real Name" for the UI greeting.
    // The 'users' table only has 'admin1', but we want "Dr. Smith".
    if ($user) {
        $full_name = $username; // Default fallback
        
        if ($user['role'] == 'doctor') {
            $stmt = $conn->prepare("SELECT full_name FROM doctors WHERE user_id = ?");
            $stmt->execute([$user['user_id']]);
            $d = $stmt->fetch();
            if ($d) $full_name = $d['full_name'];
            
        } elseif ($user['role'] == 'nurse') {
            $stmt = $conn->prepare("SELECT full_name FROM nurses WHERE user_id = ?");
            $stmt->execute([$user['user_id']]);
            $n = $stmt->fetch();
            if ($n) $full_name = $n['full_name'];
            
        } elseif ($user['role'] == 'admin') {
            $full_name = "Administrator";
        }
        $user['full_name'] = $full_name;
    }
}


// 3. VERIFICATION & SECURITY CHECKS

if ($user) {
    // CHECK 1: Verify Password Hash
    // password_verify() checks the plain text input against the stored database hash
    if (password_verify($password, $user['password_hash'])) {
        
        // CHECK 2: Is Account Deactivated? (Soft Delete)
        if ($user['is_active'] == 0) {
            addSystemLog($conn, 'login_failed', "Login attempt for deactivated account: " . $user['full_name'], $user['user_id'], $user['full_name'], $user['role']);
            echo json_encode(["success" => false, "message" => "Account Deactivated"]);
            exit();
        }

        // CHECK 3: PATIENT RESTRICTION ("The Penalty Box")
        if ($user['role'] == 'patient') {
            // Ensure we have the account status (fetched differently depending on login path)
            if (!isset($user['account_status'])) {
                $stmt = $conn->prepare("SELECT account_status FROM patients WHERE user_id = ?");
                $stmt->execute([$user['user_id']]);
                $p = $stmt->fetch();
                $user['account_status'] = $p['account_status'];
            }

            // If Restricted (3+ missed appointments), BLOCK LOGIN
            if ($user['account_status'] == 'restricted') {
                // Fetch patient_id to allow them to submit a Re-Access Request
                $patientStmt = $conn->prepare("SELECT patient_id FROM patients WHERE user_id = ?");
                $patientStmt->execute([$user['user_id']]);
                $patientData = $patientStmt->fetch(PDO::FETCH_ASSOC);
                
                addSystemLog($conn, 'login_restricted', "Restricted patient login attempt: " . $user['full_name'], $user['user_id'], $user['full_name'], 'patient', 'patient', $patientData['patient_id']);
                
                // Return specific flag 'is_restricted' so Flutter shows the Appeal Dialog
                echo json_encode([
                    "success" => false, 
                    "message" => "Your account is restricted due to multiple missed appointments. Please request re-access.",
                    "is_restricted" => true,
                    "patient_id" => $patientData['patient_id'],
                    "name" => $user['full_name']
                ]);
                exit();
            }
        }

        // CHECK 4: Success!
        addSystemLog($conn, 'login_success', $user['full_name'] . " logged in successfully", $user['user_id'], $user['full_name'], $user['role']);
        
        echo json_encode([
            "success" => true,
            "message" => "Login Successful",
            "user_id" => $user['user_id'],
            "role"    => $user['role'],
            "name"    => $user['full_name']
        ]);

    } else {
        // Password Incorrect
        addSystemLog($conn, 'login_failed', "Invalid password attempt for: " . $user['full_name'], $user['user_id'], $user['full_name'], $user['role']);
        echo json_encode(["success" => false, "message" => "Invalid Password"]);
    }
} else {
    // User Not Found
    $attemptedUser = ($login_type == 'patient') ? ($input['full_name'] ?? 'Unknown') : ($input['username'] ?? 'Unknown');
    addSystemLog($conn, 'login_failed', "Login attempt failed - user not found: " . $attemptedUser, null, $attemptedUser, null);
    $msg = ($login_type == 'patient') ? "No patient found with these details" : "Username not found";
    echo json_encode(["success" => false, "message" => $msg]);
}
?>