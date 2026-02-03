<?php
// get_patients.php


// 1. HEADERS & CONFIGURATION
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format
header("Access-Control-Allow-Methods: GET, POST"); // Allow both GET (for reading) and POST (sometimes used for complex filter bodies)
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'db_connect.php';


// 2. INPUT HANDLING (Search Query)
$query = '';

// Check GET first (standard for search: ?query=John)
if (isset($_GET['query'])) {
    $query = trim($_GET['query']);
} 
// Fallback to POST (if the app sends a JSON body instead)
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true); // Read the raw JSON data sent from app
    if (isset($data['query'])) {
        $query = trim($data['query']);
    }
}

try {
    
    // 3. QUERY CONSTRUCTION
    // We select specific columns to avoid sending sensitive data (like password hashes) if they existed.
    // We JOIN with the 'users' table to get the 'user_id', which is often needed for linking.
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
                p.consecutive_missed_appointments,
                u.user_id
            FROM patients p
            JOIN users u ON p.user_id = u.user_id";

    // DYNAMIC FILTERING: Only add the WHERE clause if the user actually typed something.
    if (!empty($query)) {
        $sql .= " WHERE p.full_name LIKE :query OR p.national_id LIKE :query";
    }

    $sql .= " ORDER BY p.full_name ASC"; // Alphabetical order is standard for lists

    $stmt = $conn->prepare($sql);
    
    // Bind parameters securely if a search term exists
    if (!empty($query)) {
        $searchTerm = "%$query%"; // Add wildcards for partial matching
        $stmt->bindParam(':query', $searchTerm);
    }
    
    // Execute and Fetch
    $stmt->execute();
    $patients = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Return result as JSON
    echo json_encode($patients);

} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
