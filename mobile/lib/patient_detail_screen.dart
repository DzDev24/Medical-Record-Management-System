// ============================================
// PATIENT_DETAIL_SCREEN.DART - Full Patient Medical Profile
// ============================================
// This screen shows a detailed view of a patient's complete medical history.
// Accessed by doctors when they tap on a patient from DoctorPatientsScreen.
// Features:
// - Patient demographics (name, age, blood type, allergies)
// - Tab-based navigation: Overview, Consultations, Appointments
// - View past consultations with prescriptions and lab results
// - Schedule new appointments
// - Create new consultations with diagnoses, prescriptions, and lab results
// - Upload lab result files (images/PDFs)

import 'package:flutter/material.dart'; // Core Flutter UI
import 'package:google_fonts/google_fonts.dart'; // Custom typography
import 'package:file_picker/file_picker.dart'; // For uploading lab result files
import 'package:url_launcher/url_launcher.dart'; // For opening lab result files in browser
import 'package:intl/intl.dart'; // Date formatting
import 'dart:convert'; // For JSON encoding/decoding
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// PatientDetailScreen - Comprehensive patient medical profile for doctors.
/// Shows all patient data including demographics, consultations, and appointments.
/// Doctors can add new consultations and schedule appointments from here.
class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient; // Patient data object from database
  final int doctorId; // Logged-in doctor's ID (for creating consultations)
  final String doctorName; // Doctor's name (displayed in consultations)

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

/// State class for PatientDetailScreen.
/// Manages consultations, appointments, and tab navigation.
class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  // Tab controller for Overview/Consultations/Appointments tabs
  late TabController _tabController;
  
  // Data lists loaded from API
  List<dynamic> _consultations = []; // Patient's consultation history
  List<dynamic> _appointments = []; // Patient's appointment history
  bool _isLoading = true; // Shows loading spinner while fetching data

  /// Initialize state - set up tab controller and load data.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs
    _loadData(); // Fetch patient's consultations and appointments
  }

  /// Clean up resources.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads consultations and appointments for this patient from the API.
  void _loadData() async {
    setState(() { _isLoading = true; });
    // Get patient ID from the patient data object
    int patientId = int.parse(widget.patient['patient_id'].toString());
    // Fetch consultations and appointments in parallel
    var consultData = await ApiService.getPatientConsultations(patientId);
    var apptData = await ApiService.getAppointments(patientId: patientId);
    setState(() {
      _consultations = consultData;
      _appointments = apptData;
      _isLoading = false;
    });
  }

  /// Reloads consultations (alias for _loadData for clarity).
  void _loadConsultations() async {
    _loadData();
  }

  /// Shows a SnackBar notification with success/error styling.
  /// Used throughout the screen to provide feedback after API operations.
  /// 
  /// Parameters:
  ///   message - The text to display
  ///   isSuccess - true = green background, false = red background
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Green for success, red for error
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating, // Float above content
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16), // Margin from screen edges
      ),
    );
  }

  // ===========================================
  // ADD NEW CONSULTATION DIALOG
  // ===========================================

  /// Shows a dialog form to create a new medical consultation.
  /// This is a complex dialog that includes:
  /// - Optional link to existing appointment
  /// - Symptoms, diagnosis, and notes fields
  /// - Dynamic list of prescriptions (add/remove)
  /// - Dynamic list of lab results (add/remove)
  /// 
  /// Uses StatefulBuilder to allow updating the dialog's internal state
  /// (e.g., when adding/removing prescriptions or lab results).
  void _showAddConsultationDialog() async {
    // Check if patient account is restricted - don't allow consultations
    if (widget.patient['account_status'] == 'restricted') {
      _showSnackBar('Cannot add consultation: Patient account is restricted', false);
      return;
    }
    
    // Form key for validation
    final formKey = GlobalKey<FormState>();
    
    // Text controllers for form fields
    TextEditingController diagnosisCtrl = TextEditingController();
    TextEditingController symptomsCtrl = TextEditingController();
    TextEditingController notesCtrl = TextEditingController();
    
    // Dynamic lists that will be updated via setDialogState
    List<Map<String, String>> prescriptions = []; // Added prescriptions
    List<Map<String, String>> labResults = []; // Added lab results
    int? selectedAppointmentId; // Optional linked appointment
    
    // Fetch available appointments for this patient
    // (completed ones that can be linked to this consultation)
    int patientId = int.parse(widget.patient['patient_id'].toString());
    List<dynamic> availableAppointments = await ApiService.getAppointments(
      patientId: patientId, 
      status: 'completed',
    );

    // Show the dialog with StatefulBuilder for internal state management
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // setDialogState allows updating the dialog's state without
        // rebuilding the entire parent widget
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          
          // Dialog title with icon
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.doctorPrimary.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle, color: AppTheme.doctorPrimary),
              ),
              SizedBox(width: 12),
              Text("New Consultation", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Optional: Link to Appointment
                  if (availableAppointments.isNotEmpty) ...[
                    Text("Link to Appointment (optional)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: DropdownButton<int>(
                        value: selectedAppointmentId,
                        hint: Text("Walk-in (no appointment)", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        dropdownColor: AppTheme.cardDark,
                        underline: SizedBox(),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text("Walk-in (no appointment)", style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          ...availableAppointments.map<DropdownMenuItem<int>>((appt) {
                            String dateStr = appt['appointment_date'] ?? '';
                            DateTime? date = DateTime.tryParse(dateStr);
                            String formattedDate = date != null ? DateFormat('MMM dd, yyyy').format(date) : dateStr;
                            return DropdownMenuItem<int>(
                              value: appt['appointment_id'] is int ? appt['appointment_id'] : int.parse(appt['appointment_id'].toString()),
                              child: Text("$formattedDate - ${appt['reason_for_visit'] ?? 'Appointment'}", 
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) => setDialogState(() => selectedAppointmentId = val),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  _buildTextField(symptomsCtrl, "Symptoms", Icons.sick, maxLines: 2),
                  SizedBox(height: 14),
                  _buildTextField(diagnosisCtrl, "Diagnosis", Icons.medical_information, maxLines: 2),
                  SizedBox(height: 14),
                  _buildTextField(notesCtrl, "Doctor Notes", Icons.note, maxLines: 3, required: false),
                  SizedBox(height: 20),
                  
                  // Prescriptions section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Prescriptions", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: AppTheme.doctorPrimary),
                        onPressed: () {
                          _showAddPrescriptionDialog((presc) {
                            setDialogState(() => prescriptions.add(presc));
                          });
                        },
                      ),
                    ],
                  ),
                  if (prescriptions.isEmpty)
                    Text("No prescriptions added", style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
                  else
                    ...prescriptions.asMap().entries.map((entry) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value['medication_name'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                Text("${entry.value['dosage']} - ${entry.value['frequency']}", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: AppTheme.error, size: 18),
                            onPressed: () => setDialogState(() => prescriptions.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    )),

                  SizedBox(height: 16),

                  // Lab Results section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Lab Results", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: AppTheme.info),
                        onPressed: () {
                          _showAddLabResultDialog((lab) {
                            setDialogState(() => labResults.add(lab));
                          });
                        },
                      ),
                    ],
                  ),
                  if (labResults.isEmpty)
                    Text("No lab results added", style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
                  else
                    ...labResults.asMap().entries.map((entry) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value['test_name'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                Text(entry.value['result_summary'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: AppTheme.error, size: 18),
                            onPressed: () => setDialogState(() => labResults.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  int patientId = int.parse(widget.patient['patient_id'].toString());
                  var res = await ApiService.addConsultation(
                    patientId: patientId,
                    doctorId: widget.doctorId,
                    diagnosis: diagnosisCtrl.text,
                    symptoms: symptomsCtrl.text,
                    doctorNotes: notesCtrl.text,
                    prescriptions: prescriptions,
                    labResults: labResults,
                    appointmentId: selectedAppointmentId,
                  );
                  _showSnackBar(res['message'] ?? 'Consultation added', res['success'] == true);
                  if (res['success'] == true) _loadConsultations();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // ADD PRESCRIPTION SUB-DIALOG
  // ===========================================

  /// Shows a sub-dialog to add a single prescription.
  /// Uses a callback pattern - onAdd is called with the prescription data.
  /// This allows the parent dialog to update its state.
  /// 
  /// Parameters:
  ///   onAdd - Callback function called with prescription data as a Map
  void _showAddPrescriptionDialog(Function(Map<String, String>) onAdd) {
    // Text controllers for prescription fields
    TextEditingController medCtrl = TextEditingController(); // Medication name
    TextEditingController dosageCtrl = TextEditingController(); // Dosage (e.g., "500mg")
    TextEditingController freqCtrl = TextEditingController(); // Frequency (e.g., "3x daily")
    TextEditingController durCtrl = TextEditingController(); // Duration (e.g., "7 days")

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // White for visibility
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add Prescription", style: TextStyle(color: AppTheme.textPrimary)),
        
        // Form fields for prescription details
        content: Column(
          mainAxisSize: MainAxisSize.min, // Only take needed space
          children: [
            _buildSmallTextField(medCtrl, "Medication Name"),
            SizedBox(height: 10),
            _buildSmallTextField(dosageCtrl, "Dosage (e.g., 500mg)"),
            SizedBox(height: 10),
            _buildSmallTextField(freqCtrl, "Frequency (e.g., 3x daily)"),
            SizedBox(height: 10),
            _buildSmallTextField(durCtrl, "Duration (e.g., 7 days)"),
          ],
        ),
        
        actions: [
          // Cancel button - neutral gray styling
          GestureDetector(
            onTap: () => Navigator.pop(ctx), // Close without saving
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0), // Light gray
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 1),
          
          // Add button - blue gradient styling
          GestureDetector(
            onTap: () {
              // Only add if medication name is provided
              if (medCtrl.text.isNotEmpty) {
                // Call callback with prescription data as Map
                onAdd({
                  'medication_name': medCtrl.text,
                  'dosage': dosageCtrl.text,
                  'frequency': freqCtrl.text,
                  'duration': durCtrl.text,
                });
                Navigator.pop(ctx); // Close dialog
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLabResultDialog(Function(Map<String, String>) onAdd) {
    TextEditingController testNameCtrl = TextEditingController();
    TextEditingController resultCtrl = TextEditingController();
    List<Map<String, String>> uploadedFiles = []; // {path, name}

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Add Lab Result", style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmallTextField(testNameCtrl, "Test Name (e.g., Blood Test)"),
                SizedBox(height: 10),
                _buildSmallTextField(resultCtrl, "Result Summary"),
                SizedBox(height: 16),
                
                // File attachments section
                Text("Attachments (Optional)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                
                // List of uploaded files
                ...uploadedFiles.asMap().entries.map((entry) => Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(entry.value['name']!, style: TextStyle(color: AppTheme.success, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          setDialogState(() => uploadedFiles.removeAt(entry.key));
                        },
                      ),
                    ],
                  ),
                )),
                
                // Add file button
                GestureDetector(
                  onTap: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
                        allowMultiple: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        for (var file in result.files) {
                          if (file.path != null) {
                            setDialogState(() {
                              uploadedFiles.add({'name': file.name, 'path': 'uploading'});
                            });
                            var uploadRes = await ApiService.uploadLabFile(file.path!);
                            if (uploadRes['success'] == true) {
                              setDialogState(() {
                                uploadedFiles[uploadedFiles.length - 1] = {
                                  'name': file.name,
                                  'path': uploadRes['file_path'],
                                };
                              });
                            } else {
                              setDialogState(() => uploadedFiles.removeLast());
                              _showSnackBar(uploadRes['message'] ?? 'Upload failed', false);
                            }
                          }
                        }
                      }
                    } catch (e) {
                      _showSnackBar('Error: $e', false);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, color: AppTheme.info, size: 20),
                        SizedBox(width: 8),
                        Text("Attach Files (PDF/Images)", style: TextStyle(color: AppTheme.info, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel button - neutral gray
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(width: 1),
            // Add button - blue gradient
            GestureDetector(
              onTap: () {
                if (testNameCtrl.text.isNotEmpty) {
                  Map<String, String> data = {
                    'test_name': testNameCtrl.text,
                    'result_summary': resultCtrl.text,
                    'test_date': DateTime.now().toString().substring(0, 10),
                  };
                  if (uploadedFiles.isNotEmpty) {
                    // Store file paths as JSON array
                    data['result_file_path'] = jsonEncode(uploadedFiles.map((f) => f['path']).toList());
                  }
                  onAdd(data);
                  Navigator.pop(ctx);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EDIT PRESCRIPTION =================
  void _showEditPrescriptionDialog(Map<String, dynamic> prescription) {
    TextEditingController medCtrl = TextEditingController(text: prescription['medication_name'] ?? '');
    TextEditingController dosageCtrl = TextEditingController(text: prescription['dosage'] ?? '');
    TextEditingController freqCtrl = TextEditingController(text: prescription['frequency'] ?? '');
    TextEditingController durCtrl = TextEditingController(text: prescription['duration'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDarker,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Prescription", style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallTextField(medCtrl, "Medication Name"),
            SizedBox(height: 10),
            _buildSmallTextField(dosageCtrl, "Dosage"),
            SizedBox(height: 10),
            _buildSmallTextField(freqCtrl, "Frequency"),
            SizedBox(height: 10),
            _buildSmallTextField(durCtrl, "Duration"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Delete prescription
              var res = await ApiService.deletePrescription(int.parse(prescription['prescription_id'].toString()));
              _showSnackBar(res['message'] ?? 'Deleted', res['success'] == true);
              if (res['success'] == true) _loadConsultations();
            },
            child: Text("Delete", style: TextStyle(color: AppTheme.error)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () async {
              if (medCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                var res = await ApiService.updatePrescription(
                  prescriptionId: int.parse(prescription['prescription_id'].toString()),
                  medicationName: medCtrl.text,
                  dosage: dosageCtrl.text,
                  frequency: freqCtrl.text,
                  duration: durCtrl.text,
                );
                _showSnackBar(res['message'] ?? 'Updated', res['success'] == true);
                if (res['success'] == true) _loadConsultations();
              }
            },
            child: Text("Save", style: TextStyle(color: AppTheme.success)),
          ),
        ],
      ),
    );
  }

  // ================= EDIT LAB RESULT =================
  void _showEditLabResultDialog(Map<String, dynamic> labResult) {
    TextEditingController testNameCtrl = TextEditingController(text: labResult['test_name'] ?? '');
    TextEditingController resultCtrl = TextEditingController(text: labResult['result_summary'] ?? '');
    
    // Parse existing files from result_file_path (could be JSON array or single path)
    List<String> existingFiles = _parseFilePaths(labResult['result_file_path']);
    List<Map<String, String>> newFiles = []; // {path, name}

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDarker,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Edit Lab Result", style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmallTextField(testNameCtrl, "Test Name"),
                SizedBox(height: 10),
                _buildSmallTextField(resultCtrl, "Result Summary"),
                SizedBox(height: 16),
                
                // File attachments section
                Text("Attachments", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                
                // Existing files
                ...existingFiles.asMap().entries.map((entry) => Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text("File ${entry.key + 1}", style: TextStyle(color: AppTheme.success, fontSize: 13))),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          setDialogState(() => existingFiles.removeAt(entry.key));
                        },
                      ),
                    ],
                  ),
                )),
                
                // New files
                ...newFiles.asMap().entries.map((entry) => Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.info, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(entry.value['name']!, style: TextStyle(color: AppTheme.info, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          setDialogState(() => newFiles.removeAt(entry.key));
                        },
                      ),
                    ],
                  ),
                )),
                
                // Add files button (matching style with Add dialog)
                GestureDetector(
                  onTap: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
                        allowMultiple: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        for (var file in result.files) {
                          if (file.path != null) {
                            setDialogState(() {
                              newFiles.add({'name': file.name, 'path': 'uploading'});
                            });
                            var uploadRes = await ApiService.uploadLabFile(file.path!);
                            if (uploadRes['success'] == true) {
                              setDialogState(() {
                                newFiles[newFiles.length - 1] = {
                                  'name': file.name,
                                  'path': uploadRes['file_path'],
                                };
                              });
                            } else {
                              setDialogState(() => newFiles.removeLast());
                              _showSnackBar(uploadRes['message'] ?? 'Upload failed', false);
                            }
                          }
                        }
                      }
                    } catch (e) {
                      _showSnackBar('Error: $e', false);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, color: AppTheme.info, size: 20),
                        SizedBox(width: 8),
                        Text("Attach Files (PDF/Images)", style: TextStyle(color: AppTheme.info, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                var res = await ApiService.deleteLabResult(int.parse(labResult['result_id'].toString()));
                _showSnackBar(res['message'] ?? 'Deleted', res['success'] == true);
                if (res['success'] == true) _loadConsultations();
              },
              child: Text("Delete", style: TextStyle(color: AppTheme.error)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
            TextButton(
              onPressed: () async {
                if (testNameCtrl.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  // Combine existing and new files
                  List<String> allFiles = [...existingFiles, ...newFiles.map((f) => f['path']!)];
                  var res = await ApiService.updateLabResult(
                    resultId: int.parse(labResult['result_id'].toString()),
                    testName: testNameCtrl.text,
                    resultSummary: resultCtrl.text,
                    resultFilePath: jsonEncode(allFiles), // Always pass JSON array, even if empty
                  );
                  _showSnackBar(res['message'] ?? 'Updated', res['success'] == true);
                  if (res['success'] == true) _loadConsultations();
                }
              },
              child: Text("Save", style: TextStyle(color: AppTheme.success)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to parse file paths (handles both JSON array and single path)
  List<String> _parseFilePaths(dynamic filePath) {
    if (filePath == null || filePath.toString().isEmpty) return [];
    String pathStr = filePath.toString();
    if (pathStr.startsWith('[')) {
      try {
        return List<String>.from(jsonDecode(pathStr));
      } catch (e) {
        return [pathStr];
      }
    }
    return [pathStr];
  }

  // Show view files dialog
  void _showViewFilesDialog(List<String> filePaths) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Text("Attached Files", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ...filePaths.asMap().entries.map((entry) {
              String fileName = entry.value.split('/').last;
              bool isPdf = fileName.toLowerCase().endsWith('.pdf');
              return GestureDetector(
                onTap: () async {
                  String fullUrl = '${ApiService.baseUrl}/${entry.value}';
                  Uri uri = Uri.parse(fullUrl);
                  try {
                    // Try in-app browser first (works on emulators)
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  } catch (e) {
                    // Fallback to platform default
                    try {
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    } catch (e2) {
                      _showSnackBar('Could not open file', false);
                    }
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(14),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? AppTheme.error : AppTheme.info, size: 28),
                      SizedBox(width: 12),
                      Expanded(child: Text(fileName, style: TextStyle(color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                      Icon(Icons.open_in_new, color: AppTheme.textMuted, size: 20),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showConsultationDetails(Map<String, dynamic> consultation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.doctorPrimary.withAlpha(51),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.medical_services, color: AppTheme.doctorPrimary, size: 28),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Consultation", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(consultation['visit_date']?.toString().substring(0, 10) ?? 'N/A', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Doctor
                    _buildInfoCard(Icons.person, "Doctor", consultation['doctor_name'] ?? 'Unknown'),

                    // Appointment Info
                    _buildInfoCard(
                      Icons.calendar_today, 
                      "Appointment", 
                      consultation['appointment_id'] != null && consultation['appointment_date'] != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(consultation['appointment_date']))
                        : "Walk-in (no appointment)"
                    ),

                    // Symptoms
                    _buildInfoCard(Icons.sick, "Symptoms", consultation['symptoms'] ?? 'N/A'),

                    // Diagnosis
                    _buildInfoCard(Icons.medical_information, "Diagnosis", consultation['diagnosis'] ?? 'N/A'),

                    // Notes
                    if (consultation['doctor_notes'] != null && consultation['doctor_notes'].toString().isNotEmpty)
                      _buildInfoCard(Icons.note, "Doctor Notes", consultation['doctor_notes']),

                    SizedBox(height: 16),

                    // Prescriptions
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.medication, color: AppTheme.success, size: 20),
                              ),
                              SizedBox(width: 10),
                              Text("Prescriptions", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (consultation['prescriptions'] == null || (consultation['prescriptions'] as List).isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text("No prescriptions", style: TextStyle(color: AppTheme.textMuted)),
                            )
                          else
                            ...(consultation['prescriptions'] as List).map((p) => Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.medication_outlined, color: AppTheme.success, size: 22),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['medication_name'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                        Text("${p['dosage'] ?? ''} - ${p['frequency'] ?? ''} - ${p['duration'] ?? ''}", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: AppTheme.info, size: 20),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showEditPrescriptionDialog(p);
                                    },
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Lab Results
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.science, color: AppTheme.info, size: 20),
                              ),
                              SizedBox(width: 10),
                              Text("Lab Results", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (consultation['lab_results'] == null || (consultation['lab_results'] as List).isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text("No lab results", style: TextStyle(color: AppTheme.textMuted)),
                            )
                          else
                            ...(consultation['lab_results'] as List).map((lr) => Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.science_outlined, color: AppTheme.info, size: 22),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lr['test_name'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                        Text(lr['result_summary'] ?? 'N/A', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                        if (lr['test_date'] != null)
                                          Text("Date: ${lr['test_date']}", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                        if (lr['result_file_path'] != null && lr['result_file_path'].toString().isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              List<String> files = _parseFilePaths(lr['result_file_path']);
                                              if (files.isNotEmpty) {
                                                _showViewFilesDialog(files);
                                              }
                                            },
                                            child: Container(
                                              margin: EdgeInsets.only(top: 6),
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.success.withAlpha(30),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.folder_open, color: AppTheme.success, size: 14),
                                                  SizedBox(width: 4),
                                                  Text("View Files (${_parseFilePaths(lr['result_file_path']).length})", style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: AppTheme.info, size: 20),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showEditLabResultDialog(lr);
                                    },
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showEditConsultationDialog(consultation);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(color: AppTheme.info.withAlpha(51), borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, color: AppTheme.info, size: 20),
                                  SizedBox(width: 8),
                                  Text("Edit", style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _deleteConsultation(int.parse(consultation['consultation_id'].toString()));
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(color: AppTheme.error.withAlpha(51), borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete, color: AppTheme.error, size: 20),
                                  SizedBox(width: 8),
                                  Text("Delete", style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditConsultationDialog(Map<String, dynamic> consultation) {
    final formKey = GlobalKey<FormState>();
    TextEditingController diagnosisCtrl = TextEditingController(text: consultation['diagnosis'] ?? '');
    TextEditingController symptomsCtrl = TextEditingController(text: consultation['symptoms'] ?? '');
    TextEditingController notesCtrl = TextEditingController(text: consultation['doctor_notes'] ?? '');
    List<Map<String, String>> newPrescriptions = [];
    List<Map<String, String>> newLabResults = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Edit Consultation", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(symptomsCtrl, "Symptoms", Icons.sick, maxLines: 2),
                  SizedBox(height: 14),
                  _buildTextField(diagnosisCtrl, "Diagnosis", Icons.medical_information, maxLines: 2),
                  SizedBox(height: 14),
                  _buildTextField(notesCtrl, "Doctor Notes", Icons.note, maxLines: 3, required: false),
                  
                  SizedBox(height: 20),
                  
                  // Add New Prescriptions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Add Prescriptions", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: AppTheme.success, size: 24),
                        onPressed: () {
                          _showAddPrescriptionDialog((presc) {
                            setDialogState(() => newPrescriptions.add(presc));
                          });
                        },
                      ),
                    ],
                  ),
                  if (newPrescriptions.isEmpty)
                    Text("No new prescriptions", style: TextStyle(color: AppTheme.textMuted, fontSize: 12))
                  else
                    ...newPrescriptions.asMap().entries.map((entry) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value['medication_name'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                                Text("${entry.value['dosage']} - ${entry.value['frequency']}", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => setDialogState(() => newPrescriptions.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    )),
                  
                  SizedBox(height: 16),
                  
                  // Add New Lab Results Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Add Lab Results", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: AppTheme.info, size: 24),
                        onPressed: () {
                          _showAddLabResultDialogForEdit((lab) {
                            setDialogState(() => newLabResults.add(lab));
                          });
                        },
                      ),
                    ],
                  ),
                  if (newLabResults.isEmpty)
                    Text("No new lab results", style: TextStyle(color: AppTheme.textMuted, fontSize: 12))
                  else
                    ...newLabResults.asMap().entries.map((entry) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value['test_name'] ?? '', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                                if (entry.value['result_file_path'] != null && entry.value['result_file_path']!.isNotEmpty)
                                  Text("Files attached", style: TextStyle(color: AppTheme.success, fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => setDialogState(() => newLabResults.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
            GestureDetector(
              onTap: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  
                  // Update consultation
                  var res = await ApiService.updateConsultation(
                    consultationId: int.parse(consultation['consultation_id'].toString()),
                    diagnosis: diagnosisCtrl.text,
                    symptoms: symptomsCtrl.text,
                    doctorNotes: notesCtrl.text,
                  );
                  
                  // Add new prescriptions directly to DB
                  int consultationId = int.parse(consultation['consultation_id'].toString());
                  for (var presc in newPrescriptions) {
                    await ApiService.addPrescription(
                      consultationId: consultationId,
                      medicationName: presc['medication_name'] ?? '',
                      dosage: presc['dosage'] ?? '',
                      frequency: presc['frequency'] ?? '',
                      duration: presc['duration'] ?? '',
                    );
                  }
                  
                  // Add new lab results directly to DB
                  for (var lab in newLabResults) {
                    await ApiService.addLabResult(
                      consultationId: consultationId,
                      testName: lab['test_name'] ?? '',
                      resultSummary: lab['result_summary'] ?? '',
                      resultFilePath: lab['result_file_path'],
                    );
                  }
                  
                  _showSnackBar(res['message'] ?? 'Updated', res['success'] == true);
                  _loadConsultations();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified add lab result dialog for use in edit consultation (returns data instead of calling API)
  void _showAddLabResultDialogForEdit(Function(Map<String, String>) onAdd) {
    TextEditingController testNameCtrl = TextEditingController();
    TextEditingController resultCtrl = TextEditingController();
    List<Map<String, String>> uploadedFiles = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDarker,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Add Lab Result", style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmallTextField(testNameCtrl, "Test Name"),
                SizedBox(height: 10),
                _buildSmallTextField(resultCtrl, "Result Summary"),
                SizedBox(height: 16),
                Text("Attachments", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                ...uploadedFiles.asMap().entries.map((entry) => Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(entry.value['name']!, style: TextStyle(color: AppTheme.success, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => setDialogState(() => uploadedFiles.removeAt(entry.key)),
                      ),
                    ],
                  ),
                )),
                GestureDetector(
                  onTap: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
                        allowMultiple: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        for (var file in result.files) {
                          if (file.path != null) {
                            setDialogState(() => uploadedFiles.add({'name': file.name, 'path': 'uploading'}));
                            var uploadRes = await ApiService.uploadLabFile(file.path!);
                            if (uploadRes['success'] == true) {
                              setDialogState(() {
                                uploadedFiles[uploadedFiles.length - 1] = {'name': file.name, 'path': uploadRes['file_path']};
                              });
                            } else {
                              setDialogState(() => uploadedFiles.removeLast());
                            }
                          }
                        }
                      }
                    } catch (e) {
                      // ignore
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, color: AppTheme.info, size: 20),
                        SizedBox(width: 8),
                        Text("Attach Files (PDF/Images)", style: TextStyle(color: AppTheme.info, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
            TextButton(
              onPressed: () {
                if (testNameCtrl.text.isNotEmpty) {
                  Map<String, String> data = {
                    'test_name': testNameCtrl.text,
                    'result_summary': resultCtrl.text,
                    'test_date': DateTime.now().toString().substring(0, 10),
                  };
                  if (uploadedFiles.isNotEmpty) {
                    data['result_file_path'] = jsonEncode(uploadedFiles.map((f) => f['path']).toList());
                  }
                  onAdd(data);
                  Navigator.pop(ctx);
                }
              },
              child: Text("Add", style: TextStyle(color: AppTheme.info)),
            ),
          ],
        ),
      ),
    );
  }


  void _deleteConsultation(int consultationId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            SizedBox(width: 12),
            Text("Delete Consultation?", style: GoogleFonts.inter(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text("This will also delete all associated prescriptions.", style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(10)),
              child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      var res = await ApiService.deleteConsultation(consultationId);
      _showSnackBar(res['message'] ?? 'Deleted', res['success'] == true);
      if (res['success'] == true) _loadConsultations();
    }
  }

  /// Builds a styled information card for displaying key-value pairs.
  /// Used in consultation details to show doctor, symptoms, diagnosis, etc.
  /// 
  /// Parameters:
  ///   icon - Icon to display on the left
  ///   label - Small label text (e.g., "Doctor", "Diagnosis")
  ///   value - Main value text to display
  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12), // Space below each card
      padding: EdgeInsets.all(14), // Inner padding
      decoration: BoxDecoration(
        color: Color(0xFFF1F5F9), // Light gray background for contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1),
      ),
      // Row layout: icon | text content
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top
        children: [
          // Icon container with colored background
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.doctorPrimary.withAlpha(51), // 20% opacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.doctorPrimary, size: 18),
          ),
          SizedBox(width: 14), // Horizontal spacing
          
          // Text content: label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small muted label
                Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                SizedBox(height: 2),
                // Larger value text
                Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled TextFormField with validation support.
  /// Used in consultation dialogs for symptoms, diagnosis, notes.
  /// 
  /// Parameters:
  ///   ctrl - TextEditingController for the input
  ///   label - Label text shown above the field
  ///   icon - Prefix icon
  ///   maxLines - Number of lines (default 1)
  ///   required - Whether field is required (adds validation)
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.textPrimary),
      // Validation function - returns error message if empty and required
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label, // Floating label
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        filled: true,
        fillColor: Color(0xFFF1F5F9), // Light gray for visibility
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Border styling for different states
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.doctorPrimary, width: 2)),
      ),
    );
  }

  /// Builds a simpler styled TextField (no validation).
  /// Used in prescription/lab result dialogs for quick input.
  Widget _buildSmallTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint, // Placeholder text
        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        filled: true,
        fillColor: Color(0xFFF1F5F9), // Light gray for visibility
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.doctorPrimary, width: 2)),
      ),
    );
  }

  // ===========================================
  // MAIN BUILD METHOD
  // ===========================================

  /// Main build method - constructs the patient detail screen.
  /// Uses TabController for 3-tab navigation: Overview, Consultations, Appointments.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color for overscroll edges
      backgroundColor: AppTheme.doctorGradient.first,
      
      // GradientBackground provides the gradient backdrop
      body: GradientBackground(
        colors: AppTheme.doctorGradient, // Blue gradient for doctor screens
        child: SafeArea(
          // Column layout: app bar | tabs | tab content
          child: Column(
            children: [
              // --- CUSTOM APP BAR ---
              // Shows back button, patient avatar, name, and account status
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button - glassmorphism styled
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Navigate back
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Patient avatar - gradient circle with first letter
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(widget.patient['full_name'][0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 12),
                    
                    // Patient name and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Patient name (truncated if too long)
                              Expanded(
                                child: Text(widget.patient['full_name'], style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              ),
                              // Status indicator dot (green = active, red = restricted)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: widget.patient['account_status'] == 'restricted' ? AppTheme.error : AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              // Status label
                              Text(
                                widget.patient['account_status'] == 'restricted' ? 'Restricted' : 'Active',
                                style: TextStyle(
                                  color: widget.patient['account_status'] == 'restricted' ? AppTheme.error : AppTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // National ID below name
                          Text("ID: ${widget.patient['national_id'] ?? 'N/A'}", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- TAB BAR ---
              // 3 tabs: Overview, Consultations, Appointments
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark, // Dark background for tab bar
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController, // Tab controller from initState
                  labelColor: AppTheme.doctorPrimary, // Selected tab color
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.doctorPrimary, // Underline indicator
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: "Overview"),
                    Tab(text: "Consultations"),
                    Tab(text: "Appointments"),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildConsultationsTab(),
                    _buildAppointmentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.patient['account_status'] == 'restricted' 
        ? null  // Hide FAB for restricted patients
        : FloatingActionButton.extended(
            onPressed: _showAddConsultationDialog,
            backgroundColor: AppTheme.doctorPrimary,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text("New Consultation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
    );
  }

  // ===========================================
  // TAB BUILDERS
  // ===========================================

  /// Builds the Overview tab content.
  /// Shows patient demographics in a clean card layout.
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // SolidCard contains all patient details
          SolidCard(
            child: Column(
              children: [
                // Each _buildDetailRow shows one piece of patient info
                _buildDetailRow(Icons.person, "Full Name", widget.patient['full_name']),
                _buildDetailRow(Icons.credit_card, "National ID", widget.patient['national_id'] ?? 'N/A'),
                _buildDetailRow(Icons.cake, "Date of Birth", widget.patient['date_of_birth'] ?? 'N/A'),
                _buildDetailRow(Icons.person_outline, "Gender", widget.patient['gender'] ?? 'N/A'),
                _buildDetailRow(Icons.water_drop, "Blood Type", widget.patient['blood_type'] ?? 'N/A'),
                _buildDetailRow(Icons.phone, "Phone", widget.patient['phone_number'] ?? 'N/A'),
                _buildDetailRow(Icons.home, "Address", widget.patient['address'] ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single detail row for the Overview tab.
  /// Shows icon, label, and value with a bottom border separator.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        // Bottom border for visual separation between rows
        border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Icon on the left
          Icon(icon, color: AppTheme.doctorPrimary, size: 20),
          SizedBox(width: 14),
          // Label and value stacked vertically
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Consultations tab content.
  /// Shows a list of past consultations or an empty state.
  /// Each consultation card is tappable to view full details.
  Widget _buildConsultationsTab() {
    // Show loading spinner while data is being fetched
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.doctorPrimary));
    }

    // Empty state when no consultations exist
    if (_consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Only take needed space
          children: [
            Icon(Icons.medical_services_outlined, size: 60, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text("No Consultations", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text("Add a new consultation to get started", style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    // ListView.builder efficiently builds items on demand
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _consultations.length, // Number of consultations
      itemBuilder: (context, index) {
        var c = _consultations[index]; // Current consultation data
        
        // GestureDetector makes the card tappable
        return GestureDetector(
          onTap: () => _showConsultationDetails(c), // Open details bottom sheet
          child: SolidCard(
            margin: EdgeInsets.only(bottom: 12), // Space between cards
            borderColor: AppTheme.doctorPrimary.withAlpha(38), // Light blue border
            child: Row(
              children: [
                // Medical icon in colored container
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.doctorPrimary.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services, color: AppTheme.doctorPrimary),
                ),
                SizedBox(width: 14),
                
                // Consultation info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diagnosis (primary text, truncated if too long)
                      Text(c['diagnosis'] ?? 'No diagnosis', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      // Visit date
                      Text(c['visit_date']?.toString().substring(0, 10) ?? 'N/A', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      // Prescription and lab result counts
                      Row(
                        children: [
                          // Show prescription count if any (e.g., "2 Rx")
                          if ((c['prescription_count'] ?? 0) > 0)
                            Text("${c['prescription_count']} Rx", style: TextStyle(color: AppTheme.success, fontSize: 12)),
                          // Separator dot between counts
                          if ((c['prescription_count'] ?? 0) > 0 && (c['lab_result_count'] ?? 0) > 0)
                            Text(" • ", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          // Show lab result count if any (e.g., "1 Lab")
                          if ((c['lab_result_count'] ?? 0) > 0)
                            Text("${c['lab_result_count']} Lab", style: TextStyle(color: AppTheme.info, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Chevron indicating tappable
                Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the Appointments tab content.
  /// Shows appointment history with status colors and pull-to-refresh.
  Widget _buildAppointmentsTab() {
    // Show loading spinner while data is being fetched
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.doctorPrimary));
    }
    
    // Empty state when no appointments exist
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: AppTheme.textMuted, size: 48),
            SizedBox(height: 12),
            Text("No appointments found", style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    // RefreshIndicator enables pull-to-refresh functionality
    return RefreshIndicator(
      onRefresh: () async => _loadData(), // Reload data when pulled
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appt = _appointments[index]; // Current appointment
          String status = appt['status'] ?? 'scheduled';
          
          // Parse and format the appointment date
          String dateStr = appt['appointment_date'] ?? '';
          DateTime? date = DateTime.tryParse(dateStr);
          String formattedDate = date != null 
            ? DateFormat('MMM dd, yyyy - HH:mm').format(date) 
            : dateStr;

          // Determine color and icon based on appointment status
          Color statusColor;
          IconData statusIcon;
          switch (status) {
            case 'scheduled':
              statusColor = AppTheme.info; // Blue for scheduled
              statusIcon = Icons.schedule;
              break;
            case 'completed':
              statusColor = AppTheme.success; // Green for completed
              statusIcon = Icons.check_circle;
              break;
            case 'missed':
              statusColor = AppTheme.error; // Red for missed
              statusIcon = Icons.cancel;
              break;
            case 'cancelled':
              statusColor = AppTheme.textMuted; // Gray for cancelled
              statusIcon = Icons.block;
              break;
            default:
              statusColor = AppTheme.textSecondary;
              statusIcon = Icons.help;
          }

          // Appointment card with status-colored styling
          return Container(
            margin: EdgeInsets.only(bottom: 10), // Space between cards
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withAlpha(50)), // Status-colored border
            ),
            child: Row(
              children: [
                // Status icon in colored container
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30), // 12% opacity
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                SizedBox(width: 12),
                
                // Appointment details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formatted date/time
                      Text(formattedDate, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      // Reason for visit (if provided)
                      if (appt['reason_for_visit'] != null && appt['reason_for_visit'].toString().isNotEmpty)
                        Text(appt['reason_for_visit'], style: TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      // Doctor name
                      Text("Dr. ${appt['doctor_name'] ?? 'Unknown'}", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
