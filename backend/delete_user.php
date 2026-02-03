<?php
// delete_user.php


// 1. SETUP & HEADERS


header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Content-Type: application/json; charset=UTF-8"); // Tell the app that the response will be in JSON format

include 'db_connect.php';


// 2. INPUT HANDLING

// Retrieve the raw POST data from the request body
$data = json_decode(file_get_contents('php://input'), true);

// Extract the ID of the user to be deleted
$user_id = $data['user_id'];

try {
    
    // 3. EXECUTE DELETION
    $stmt = $conn->prepare("DELETE FROM users WHERE user_id = ?");
    
    // The execute() function replaces the '?' with the actual $user_id safely.
    $stmt->execute([$user_id]);
    
    
    // 4. RETURN RESPONSE
    // Send a success signal back to the Flutter app so it can remove the item from the list UI.
    echo json_encode(["success" => true, "message" => "User deleted"]);

} catch (Exception $e) {
    // If the database blocks the deletion
    // catch the error and send it back to the app.
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>