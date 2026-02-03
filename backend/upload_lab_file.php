<?php
// upload_lab_file.php - Handle file uploads for lab results

// 1. CONFIGURATION
header("Access-Control-Allow-Origin: *"); // Allow emulator or device to access this script
header("Access-Control-Allow-Methods: POST, OPTIONS"); // Allow POST requests (and OPTIONS for checks)
header("Access-Control-Allow-Headers: Content-Type"); // Allow Content-Type header

// check: Browsers/Apps sometimes send an 'OPTIONS' request first
// to see if the server allows uploads. We respond 'OK' immediately.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 2. DIRECTORY SETUP
// Define where files will live on the server.
// __DIR__ gives the current script's folder path.
$uploadDir = __DIR__ . '/uploads/lab_results/';

// Auto-create the folder if it doesn't exist yet
if (!file_exists($uploadDir)) {
    // 0777 allows read/write permissions (standard for upload folders)
    mkdir($uploadDir, 0777, true);
}

// 3. UPLOAD LOGIC
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Check if the file payload exists
    if (!isset($_FILES['file'])) {
        echo json_encode(['success' => false, 'message' => 'No file uploaded']);
        exit;
    }

    $file = $_FILES['file']; // Get file metadata (name, tmp_name, size, etc.)
    
    // ==========================================
    // 4. SECURITY VALIDATION
    // ==========================================
    // We only allow specific, safe file types.
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
    
    // VERIFY MIME TYPE:
    // We don't just trust the file extension (e.g., user could rename .exe to .jpg).
    // 'finfo' reads the actual binary header of the file to confirm what it is.
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!in_array($mimeType, $allowedTypes)) {
        echo json_encode(['success' => false, 'message' => 'Invalid file type. Only PDF, JPG, PNG, GIF allowed.']);
        exit;
    }

    // VERIFY SIZE: Limit to 10MB to prevent server overload
    if ($file['size'] > 10 * 1024 * 1024) {
        echo json_encode(['success' => false, 'message' => 'File too large. Max 10MB.']);
        exit;
    }

    // ==========================================
    // 5. FILE SAVING
    // ==========================================
    // Generate a unique filename to prevent overwriting.
    // Logic: 'lab_' + Timestamp + RandomHex + Extension
    // Example: lab_17098234_a1b2c3d4.pdf
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $newFilename = 'lab_' . time() . '_' . bin2hex(random_bytes(8)) . '.' . $extension;
    
    $targetPath = $uploadDir . $newFilename; // Absolute path for saving

    // Move the file from the temporary PHP folder to our permanent 'uploads' folder
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        
        // Return the RELATIVE path.
        // The database only needs 'uploads/lab_results/file.pdf', not the full C:/xampp/... path.
        $relativePath = 'uploads/lab_results/' . $newFilename;
        
        echo json_encode([
            'success' => true, 
            'message' => 'File uploaded successfully',
            'file_path' => $relativePath,
            'file_name' => $file['name']
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to save file']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?>