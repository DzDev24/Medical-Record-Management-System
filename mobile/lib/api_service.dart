import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CHANGE THIS to your PC IP if using a real phone or 'localhost' if running on web
  static const String baseUrl = "http://10.0.2.2/medical_app";

  // ... inside ApiService class

  static Future<Map<String, dynamic>> login({ //  
    required String loginType, // 'staff' or 'patient'
    required String password,
    String? username,   // Only for Staff
    String? fullName,   // Only for Patient
    String? nationalId, // Only for Patient
  }) async {
    try {
      final response = await http.post( // Login endpoint
        Uri.parse("$baseUrl/login.php"),
        body: jsonEncode({
          "login_type": loginType, // distinguish between staff and patient
          "password": password,
          "username": username, // for staff login nullable because patients don't use it
          "full_name": fullName,  // for patient login nullable because staff don't use it
          "national_id": nationalId, // for patient login nullable because staff don't use it
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // return parsed JSON response
      } else {
        return {"success": false, "message": "Server Error"}; // handle non-200 responses
      }
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle network errors
    }
  }

  // ==========================================
  // PATIENT DATA
  // ==========================================
  // Get patient appointments (for patient view)
  static Future<List<dynamic>> getPatientAppointments(int userId) async { // userId is the patient's user ID
    try {
      final response = await http.get( // GET request to fetch appointments
        Uri.parse("$baseUrl/get_patient_appointments.php?user_id=$userId"), // pass userId as query parameter
      );

      if (response.statusCode == 200) {
        // Returns a List because the server sends an array [ ... ]
        return jsonDecode(response.body);
      } else {
        // Handle server errors or non-200 status codes
        print("API Error (getPatientAppointments): ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      // Handle network errors
      print("Error fetching appointments: $e");
      return [];
    }
  }

  // Get comprehensive patient records (for patient view)
  static Future<Map<String, dynamic>> getPatientFullRecords(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_patient_full_records.php?user_id=$userId"), // pass userId as query parameter
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Server error: ${response.statusCode}"}; // handle non-200 responses 200 means success and other codes mean errors
      }
    } catch (e) {
      return {"error": "Connection error: $e"}; // handle network errors
    }
  }



  // Fetch staff list
  static Future<List<dynamic>> getStaff(String role, {String query = ""}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_staff.php?role=$role&search=$query"), // role can be 'admin', 'doctor', 'nurse'
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Expecting a list of staff members
      }
      return [];
    } catch (e) { // Handle errors
      return [];
    }
  }



  // 1. Get Dropdown Options
  static Future<Map<String, dynamic>> getMetadata() async { // fetch departments, specialties, etc.
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_metadata.php")); // endpoint to get metadata
      if (response.statusCode == 200) { // success
        return jsonDecode(response.body); // return parsed JSON
      }
      return {};
    } catch (e) { // handle errors
      return {};
    }
  }

  // 2. Add Staff (Accepts extraId instead of extraInfo string)
  // NOTE: 'extraId' is a dynamic parameter that changes based on the 'role':
  // - For Doctors: It represents the 'Specialty ID'.
  // - For Nurses/Staff: It represents the 'Department ID'.
  // This allows us to use a single function for different staff types.
  static Future<Map<String, dynamic>> addStaff(String username, String password, String role, String fullName, String extraId, String phone) async { // extraId is department ID or specialty ID
    try {
      final response = await http.post( // POST request to add staff
        Uri.parse("$baseUrl/add_staff.php"), // endpoint to add staff
        body: jsonEncode({ // request body as JSON
          "username": username, // Staff username
          "password": password, 
          "role": role,
          "full_name": fullName,
          "extra_id": extraId, // Sending ID
          "phone_number": phone
        }),
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) { // handle errors
      return {"success": false, "message": "Connection Error"}; // return connection error message
    }
  }

  // 3. Update Staff (Accepts extraId)
  // ... inside ApiService class

  static Future<Map<String, dynamic>> updateStaff( // extraId is department ID or specialty ID extraid is used to identify the new department or specialty 
      int userId,
      String username,
      String password,
      String role,
      String fullName,
      String extraId,
      String phone
      ) async {
    try {
      final response = await http.post( // POST request to update staff
        Uri.parse("$baseUrl/update_staff.php"), // endpoint to update staff
        body: jsonEncode({
          "user_id": userId,
          "username": username, // Staff username
          "password": password, // Send empty string if no change
          "role": role, // Staff role
          "full_name": fullName, // Staff full name
          "extra_id": extraId, // Sending ID
          "phone_number": phone
        }),
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) { // handle errors
      return {"success": false, "message": "Connection Error"};
    }
  }

  // Delete staff
  static Future<Map<String, dynamic>> deleteUser(int userId) async { // userId of the staff to delete
    try { // POST request to delete staff
      final response = await http.post( // endpoint to delete staff
        Uri.parse("$baseUrl/delete_user.php"), // endpoint to delete user
        body: jsonEncode({"user_id": userId}), // request body with userId
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) { // handle errors
      return {"success": false, "message": "Connection Error"}; // return connection error message
    }
  }

  // ==========================================
  // PATIENT CRUD METHODS (Nurse functionality)
  // ==========================================


  // Fetches a list of patients from the database.
  // The '{String query = ""}' is an optional parameter. 
  // If we pass a name (e.g., "John"), it searches. If empty, it returns everyone.
  // Get all patients with optional search
  static Future<List<dynamic>> getPatients({String query = ""}) async {
    try {
      // We use a GET request because we are READING data, not changing it.
      // The '?query=$query' part sends the search text to the PHP server.
      final response = await http.get(
        Uri.parse("$baseUrl/get_patients.php?query=$query"),
      );
      // Check if the server responded successfully (Status Code 200 = OK)
      if (response.statusCode == 200) {
        // The server sends raw text (JSON). We must 'decode' it into a Dart List.
        return jsonDecode(response.body);
      }
      // If the server failed (e.g., 404 or 500 error), return an empty list to avoid crashing.
      return [];
    } catch (e) {
      // Catch network errors (like no WiFi) and print the error for debugging.
      print("Error fetching patients: $e");
      return [];
    }
  }

  // Add new patient
  static Future<Map<String, dynamic>> addPatient({ // required fields for new patient
    required String fullName, //
    required String nationalId,
    required String password,
    required String dateOfBirth,
    required String gender,
    required String bloodType,
    required String phone,
    String address = "", // optional address field
  }) async {
    try { // POST request to add new patient
      final response = await http.post( // endpoint to add patient
        Uri.parse("$baseUrl/add_patient.php"), // endpoint to add patient
        body: jsonEncode({ // request body as JSON
          "full_name": fullName,
          "national_id": nationalId,
          "password": password,
          "date_of_birth": dateOfBirth,
          "gender": gender,
          "blood_type": bloodType,
          "phone": phone,
          "address": address,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Update patient (with optional password change)
  static Future<Map<String, dynamic>> updatePatient({ // required fields for updating patient
    required int patientId, // patient ID to update
    required int userId, 
    required String fullName,
    required String dateOfBirth,
    required String gender,
    required String bloodType,
    required String phone,
    String address = "", // optional address field
    String password = "", // Empty = no change
  }) async {
    try {
      final response = await http.post( // POST request to update patient
        Uri.parse("$baseUrl/update_patient.php"), // endpoint to update patient
        body: jsonEncode({ // request body as JSON
          "patient_id": patientId, // patient ID to update
          "user_id": userId,
          "full_name": fullName,
          "date_of_birth": dateOfBirth,
          "gender": gender,
          "blood_type": bloodType,
          "phone": phone,
          "address": address,
          "password": password,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Delete patient
  static Future<Map<String, dynamic>> deletePatient(int patientId) async { // patient ID to delete
    try { // POST request to delete patient
      final response = await http.post( // endpoint to delete patient
        Uri.parse("$baseUrl/delete_patient.php"), // endpoint to delete patient
        body: jsonEncode({"patient_id": patientId}), // request body with patientId
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) { // handle errors
      return {"success": false, "message": "Connection Error: $e"}; // return connection error message
    }
  }

  // ==========================================
  // DOCTOR FUNCTIONALITY - Patient Records
  // ==========================================

  // Get patients for doctor to view (all patients)
  static Future<List<dynamic>> getPatientsForDoctor({String query = ""}) async { // optional search query
    try { // GET request to fetch patients for doctor
      final response = await http.get( // endpoint to get patients for doctor
        Uri.parse("$baseUrl/get_patients_for_doctor.php?query=$query"), // pass search query as parameter
      ); 
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // return parsed JSON response 
      }
      return [];
    } catch (e) {
      // handle errors
      print("Error fetching patients for doctor: $e");
      return [];
    }
  }

  // Get patient consultations
  static Future<List<dynamic>> getPatientConsultations(int patientId) async { // patient ID to fetch consultations for
    try { // GET request to fetch consultations for a patient
      final response = await http.get( // endpoint to get patient consultations
        Uri.parse("$baseUrl/consultations_crud.php?action=get&patient_id=$patientId"), // pass patientId as parameter
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // return parsed JSON response
      }
      return [];
    } catch (e) {
      // handle errors
      print("Error fetching consultations: $e");
      return [];
    }
  }

  // Add consultation
  static Future<Map<String, dynamic>> addConsultation({ // required fields for new consultation
    required int patientId, // patient ID
    required int doctorId,
    required String diagnosis,
    required String symptoms,
    required String doctorNotes,
    int? appointmentId,
    List<Map<String, String>>? prescriptions, // optional prescriptions as list of maps
    List<Map<String, String>>? labResults, // optional lab results as list of maps
  }) async {
    try { // POST request to add new consultation
      final response = await http.post( // endpoint to add consultation
        Uri.parse("$baseUrl/consultations_crud.php"), // endpoint to add consultation
        body: jsonEncode({ // request body as JSON
          "action": "add",
          "patient_id": patientId, // patient ID
          "doctor_id": doctorId,
          "diagnosis": diagnosis,
          "symptoms": symptoms,
          "doctor_notes": doctorNotes,
          "appointment_id": appointmentId,
          "prescriptions": prescriptions ?? [], // default to empty list if null
          "lab_results": labResults ?? [], // default to empty list if null
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Update consultation
  static Future<Map<String, dynamic>> updateConsultation({ // required fields for updating consultation
    required int consultationId, // consultation ID to update
    required String diagnosis, 
    required String symptoms,
    required String doctorNotes,
  }) async {
    try { // POST request to update consultation
      final response = await http.post( // endpoint to update consultation
        Uri.parse("$baseUrl/consultations_crud.php"), // endpoint to update consultation
        body: jsonEncode({ // request body as JSON
          "action": "update",
          "consultation_id": consultationId,
          "diagnosis": diagnosis,
          "symptoms": symptoms,
          "doctor_notes": doctorNotes,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Delete consultation
  static Future<Map<String, dynamic>> deleteConsultation(int consultationId) async { // consultation ID to delete
    try { // POST request to delete consultation
      final response = await http.post( // endpoint to delete consultation
        Uri.parse("$baseUrl/consultations_crud.php"), // endpoint to delete consultation
        body: jsonEncode({ // request body as JSON
          "action": "delete",
          "consultation_id": consultationId,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Add prescription to consultation
  static Future<Map<String, dynamic>> addPrescription({ // required fields for new prescription
    required int consultationId, 
    required String medicationName,
    required String dosage,
    required String frequency,
    required String duration,
  }) async {
    try {
      final response = await http.post( // POST request to add prescription
        Uri.parse("$baseUrl/prescriptions_crud.php"), // endpoint to add prescription
        body: jsonEncode({ // request body as JSON
          "action": "add",
          "consultation_id": consultationId,
          "medication_name": medicationName,
          "dosage": dosage,
          "frequency": frequency,
          "duration": duration,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) { 
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Delete prescription
  static Future<Map<String, dynamic>> deletePrescription(int prescriptionId) async { // prescription ID to delete
    try { // POST request to delete prescription
      final response = await http.post( // endpoint to delete prescription
        Uri.parse("$baseUrl/prescriptions_crud.php"), // endpoint to delete prescription
        body: jsonEncode({ // request body as JSON
          "action": "delete",
          "prescription_id": prescriptionId,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // ==========================================
  // LAB RESULTS METHODS
  // ==========================================

  // Upload file for lab result
  static Future<Map<String, dynamic>> uploadLabFile(String filePath) async { // local file path to upload
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/upload_lab_file.php")); // endpoint to upload lab file multipart request because we are sending a file
      request.files.add(await http.MultipartFile.fromPath('file', filePath)); // attach file to request
      var streamedResponse = await request.send(); // send request
      var response = await http.Response.fromStream(streamedResponse); // get response from stream
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Upload Error: $e"};
    }
  }

  // Add lab result with optional file path
  static Future<Map<String, dynamic>> addLabResult({ // required fields for new lab result
    required int consultationId, 
    required String testName,
    required String resultSummary,
    String? testDate,
    String? resultFilePath,
  }) async {
    try { // POST request to add lab result
      final response = await http.post( // endpoint to add lab result
        Uri.parse("$baseUrl/lab_results_crud.php"), // endpoint to add lab result
        body: jsonEncode({ // request body as JSON
          "action": "add",
          "consultation_id": consultationId,
          "test_name": testName,
          "result_summary": resultSummary,
          "test_date": testDate ?? DateTime.now().toString().substring(0, 10),
          "result_file_path": resultFilePath,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Update lab result
  static Future<Map<String, dynamic>> updateLabResult({ // required fields for updating lab result
    required int resultId,
    required String testName,
    required String resultSummary,
    String? testDate,
    String? resultFilePath,
  }) async {
    try { // Prepare request body
      Map<String, dynamic> body = { // request body as JSON
        "action": "update",
        "result_id": resultId,
        "test_name": testName,
        "result_summary": resultSummary,
        "test_date": testDate ?? DateTime.now().toString().substring(0, 10), // default to today if null
        // Always include result_file_path to allow clearing files (send empty array if null)
        "result_file_path": resultFilePath ?? "[]", // send empty array string if null
      };
      final response = await http.post( // POST request to update lab result
        Uri.parse("$baseUrl/lab_results_crud.php"), // endpoint to update lab result
        body: jsonEncode(body), // encode body as JSON
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Delete lab result
  static Future<Map<String, dynamic>> deleteLabResult(int resultId) async { // lab result ID to delete
    try { // POST request to delete lab result
      final response = await http.post( // endpoint to delete lab result
        Uri.parse("$baseUrl/lab_results_crud.php"), // endpoint to delete lab result
        body: jsonEncode({ // request body as JSON
          "action": "delete",
          "result_id": resultId,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  // Update prescription
  static Future<Map<String, dynamic>> updatePrescription({ // required fields for updating prescription
    required int prescriptionId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required String duration,
  }) async { // POST request to update prescription
    try { // endpoint to update prescription
      final response = await http.post(
        Uri.parse("$baseUrl/prescriptions_crud.php"), // endpoint to update prescription
        body: jsonEncode({
          "action": "update",
          "prescription_id": prescriptionId,
          "medication_name": medicationName,
          "dosage": dosage,
          "frequency": frequency,
          "duration": duration,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  // ============ APPOINTMENTS API ============

  static Future<List<dynamic>> getAppointments({ // optional filters
    int? doctorUserId, // filter by doctor user ID
    int? patientId, // filter by patient ID
    String? status, // filter by status: scheduled, completed, missed, cancelled
  }) async {
    try { // Build query parameters
      Map<String, String> params = {}; // initialize empty map
      if (doctorUserId != null) params['doctor_user_id'] = doctorUserId.toString(); // convert int to string
      if (patientId != null) params['patient_id'] = patientId.toString(); // convert int to string
      if (status != null) params['status'] = status; // status is already a string
      
      String queryString = Uri(queryParameters: params).query; // build query string from parameters
      final response = await http.get( // GET request to fetch appointments
        Uri.parse('$baseUrl/appointments_crud.php?$queryString'), // append query string to URL
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return []; // handle errors by returning empty list
    }
  }

  static Future<List<dynamic>> getPatientsList() async { // for appointment booking dropdown
    try { // GET request to fetch patients list
      final response = await http.get( // endpoint to get patients list
        Uri.parse('$baseUrl/appointments_crud.php?action=get_patients'), // action to get patients
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return []; // handle errors by returning empty list
    }
  }

  static Future<Map<String, dynamic>> addAppointment({ // required fields for new appointment
    required int patientId,
    required int doctorUserId,
    required String appointmentDate,
    String? reasonForVisit,
  }) async { // POST request to add new appointment
    try { // endpoint to add appointment
      final response = await http.post( // POST request to add appointment
        Uri.parse('$baseUrl/appointments_crud.php'), // endpoint to add appointment
        body: jsonEncode({ // request body as JSON
          "action": "add",
          "patient_id": patientId,
          "doctor_user_id": doctorUserId,
          "appointment_date": appointmentDate,
          "reason_for_visit": reasonForVisit ?? '',
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      // handle errors
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateAppointment({ // required fields for updating appointment
    required int appointmentId,
    required String appointmentDate,
    String? reasonForVisit,
  }) async { // POST request to update appointment
    try { // endpoint to update appointment
      final response = await http.post( // POST request to update appointment
        Uri.parse('$baseUrl/appointments_crud.php'), // endpoint to update appointment
        body: jsonEncode({ // request body as JSON
          "action": "update",
          "appointment_id": appointmentId,
          "appointment_date": appointmentDate,
          "reason_for_visit": reasonForVisit ?? '',
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({ // required fields for updating appointment status
    required int appointmentId,
    required String status, // scheduled, completed, missed, cancelled
  }) async {
    try { // POST request to update appointment status
      final response = await http.post( // endpoint to update appointment status
        Uri.parse('$baseUrl/appointments_crud.php'), // endpoint to update appointment status
        body: jsonEncode({ // request body as JSON
          "action": "update_status", 
          "appointment_id": appointmentId,
          "status": status,
        }), 
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  static Future<Map<String, dynamic>> deleteAppointment(int appointmentId) async { // appointment ID to delete
    try {
      final response = await http.post( // POST request to delete appointment
        Uri.parse('$baseUrl/appointments_crud.php'), // endpoint to delete appointment
        body: jsonEncode({ // request body as JSON
          "action": "delete",
          "appointment_id": appointmentId,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  // ==================== RE-ACCESS REQUESTS ====================

  // Submit re-access request (patient)
  static Future<Map<String, dynamic>> submitReaccessRequest({ // required fields for re-access request
    required int patientId,
    required String reason,
    String? contactPhone,
  }) async {
    try { // POST request to submit re-access request
      final response = await http.post( // endpoint to submit re-access request
        Uri.parse('$baseUrl/reaccess_crud.php'), // endpoint to submit re-access request
        body: jsonEncode({ // request body as JSON
          "action": "submit",
          "patient_id": patientId,
          "reason": reason,
          "contact_phone": contactPhone,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  // Get pending re-access requests (admin)
  static Future<List<dynamic>> getPendingReaccessRequests() async { // GET request to fetch pending re-access requests
    try {
      final response = await http.get( // endpoint to get pending re-access requests
        Uri.parse('$baseUrl/reaccess_crud.php?action=get_pending'), // action to get pending requests
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return []; // handle errors by returning empty list
    }
  }

  // Process re-access request (admin approve/reject)
  static Future<Map<String, dynamic>> processReaccessRequest({ // required fields for processing re-access request
    required int requestId,
    required bool approve,
    String? adminResponse,
    int? adminId,
  }) async {
    try { // POST request to process re-access request
      final response = await http.post( // endpoint to process re-access request
        Uri.parse('$baseUrl/reaccess_crud.php'), // endpoint to process re-access request
        body: jsonEncode({ // request body as JSON
          "action": approve ? "approve" : "reject",
          "request_id": requestId,
          "admin_response": adminResponse,
          "admin_id": adminId,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }

  // ==================== SYSTEM LOGS ====================

  // Get system logs (admin)
  static Future<Map<String, dynamic>> getSystemLogs({ // optional parameters for pagination and filtering
    int limit = 50, // number of logs to fetch
    int offset = 0, // offset for pagination
    String? filterType, // filter by action type
  }) async {
    try { // Build URL with query parameters
      String url = '$baseUrl/logs_crud.php?action=get_recent&limit=$limit&offset=$offset'; // base URL with limit and offset
      if (filterType != null) { // append filter type if provided
        url += '&filter_type=$filterType'; // append filter type to URL
      }
      final response = await http.get(Uri.parse(url)); // GET request to fetch system logs
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "logs": [], "message": "Connection Error: $e"}; // handle errors
    }
  }

  // Get log action types for filtering
  static Future<List<dynamic>> getLogActionTypes() async { // GET request to fetch log action types
    try {
      final response = await http.get( // GET request to fetch log action types
        Uri.parse('$baseUrl/logs_crud.php?action=get_action_types'), // action to get action types
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return []; // handle errors by returning empty list
    }
  }

  // Add system log entry
  static Future<Map<String, dynamic>> addSystemLog({ // required fields for new log entry
    required String actionType,
    required String description,
    int? userId,
    String? userName,
    String? userRole,
    String? targetType,
    int? targetId,
  }) async {
    try { // POST request to add system log entry
      final response = await http.post( // endpoint to add system log entry
        Uri.parse('$baseUrl/logs_crud.php'), // endpoint to add log entry
        body: jsonEncode({ // request body as JSON
          "action": "add",
          "action_type": actionType,
          "action_description": description,
          "user_id": userId,
          "user_name": userName,
          "user_role": userRole,
          "target_type": targetType,
          "target_id": targetId,
        }),
        headers: {"Content-Type": "application/json"}, // specify JSON content type
      );
      return jsonDecode(response.body); // return parsed JSON response
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"}; // handle errors
    }
  }
}