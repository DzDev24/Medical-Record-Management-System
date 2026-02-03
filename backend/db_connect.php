<?php
$servername = "localhost";
$username = "root"; // default XAMPP username
$password = "";
$dbname = "medical_record_system";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password); // we use PDO for database connection because it supports prepared statements for security
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
    exit();
}
?>