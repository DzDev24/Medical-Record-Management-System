// ============================================
// MANAGE_PATIENTS_SCREEN.DART - Patient CRUD Operations
// ============================================
// This screen allows nurses to manage patient records.
// Features:
// - View list of all patients
// - Search patients by name
// - Add new patients with full medical information
// - Edit existing patient information (including password reset)
// - Delete patient records
// All operations sync with the PHP backend via ApiService.

import 'dart:ui'; // For blur effects
import 'package:flutter/material.dart'; // Core Flutter UI
import 'package:google_fonts/google_fonts.dart'; // Custom typography
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// ManagePatientsScreen - Nurse screen for managing patient records.
/// Provides full CRUD (Create, Read, Update, Delete) functionality for patients.
class ManagePatientsScreen extends StatefulWidget {
  const ManagePatientsScreen({super.key});

  @override
  _ManagePatientsScreenState createState() => _ManagePatientsScreenState();
}

/// State class for ManagePatientsScreen.
/// Handles patient data loading, CRUD operations, and UI state management.
class _ManagePatientsScreenState extends State<ManagePatientsScreen> with SingleTickerProviderStateMixin {
  // ==========================================
  // STATE VARIABLES
  // ==========================================
  
  List<dynamic> _patientsList = []; // List of patients from database
  bool _isLoading = true; // Shows loading indicator while fetching
  final TextEditingController _searchController = TextEditingController(); // Search input

  // Animation controllers for smooth entrance effects
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  /// Initialize state - set up animations and load patient data.
  @override
  void initState() {
    super.initState();
    // Set up fade-in entrance animation
    _animController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this, // TickerProvider for smooth animation
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(); // Start animation
    _loadPatients(); // Fetch patient list from API
  }

  /// Clean up controllers to prevent memory leaks.
  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Loads patients from the API.
  /// Optional query parameter for search functionality.
  void _loadPatients([String query = ""]) async {
    setState(() { _isLoading = true; });
    var data = await ApiService.getPatients(query: query); // API call
    setState(() {
      _patientsList = data;
      _isLoading = false;
    });
  }

  /// Shows a snackbar notification with success/error styling.
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating, // Float above content
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  // ===========================================
  // PATIENT DETAILS MODAL (Bottom Sheet)
  // ===========================================

  /// Shows a modal bottom sheet with detailed patient information.
  /// Displays avatar, all patient data fields, and Edit/Delete actions.
  /// 
  /// Parameters:
  ///   patient - Map containing patient data from API
  void _showPatientDetails(Map<String, dynamic> patient) {
    // Check patient account status (active or restricted)
    String status = patient['account_status'] ?? 'active';
    bool isRestricted = status == 'restricted';
    
    // showModalBottomSheet creates a sliding panel from the bottom
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent to show custom shape
      isScrollControlled: true, // Allows full-height control
      builder: (ctx) => Container(
        // Take 70% of screen height
        height: MediaQuery.of(context).size.height * 0.7,
        // Custom decoration with rounded top corners
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // --- DRAG HANDLE BAR ---
            // Small gray bar indicating the sheet can be dragged
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // --- SCROLLABLE CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // --- PATIENT AVATAR ---
                    // Gradient container with first letter of name
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.nursePrimary, AppTheme.nurseSecondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          patient['full_name'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // --- PATIENT NAME ---
                    Text(
                      patient['full_name'],
                      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    
                    // --- STATUS BADGE (Active/Restricted) ---
                    _buildStatusBadge(status),
                    SizedBox(height: 24),
                    
                    // --- INFO CARDS ---
                    // Each _buildDetailRow shows one piece of patient info
                    _buildDetailRow(Icons.credit_card, "National ID", patient['national_id'] ?? 'N/A'),
                    _buildDetailRow(Icons.cake, "Date of Birth", patient['date_of_birth'] ?? 'N/A'),
                    _buildDetailRow(Icons.person, "Gender", patient['gender'] ?? 'N/A'),
                    _buildDetailRow(Icons.water_drop, "Blood Type", patient['blood_type'] ?? 'N/A'),
                    _buildDetailRow(Icons.phone, "Phone", patient['phone_number'] ?? 'N/A'),
                    _buildDetailRow(Icons.home, "Address", patient['address'] ?? 'N/A'),
                    
                    // Show missed appointments count only for restricted patients
                    if (isRestricted)
                      _buildDetailRow(Icons.warning_amber, "Missed Appointments", 
                        patient['consecutive_missed_appointments']?.toString() ?? '0'),
                    
                    SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showEditPatientDialog(patient);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.info.withAlpha(51),
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                              _deletePatient(int.parse(patient['patient_id'].toString()), patient['full_name']);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withAlpha(51),
                                borderRadius: BorderRadius.circular(14),
                              ),
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
  
  // ===========================================
  // HELPER WIDGETS
  // ===========================================

  /// Builds a detail row for displaying patient information.
  /// Shows icon, label, and value in a styled container.
  /// 
  /// Parameters:
  ///   icon - Icon to display on the left
  ///   label - Small label text (e.g., "National ID")
  ///   value - Main value text (e.g., "123456789")
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12), // Space between rows
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite, // Semi-transparent background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon in colored container
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.nursePrimary.withAlpha(51), // 20% opacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.nursePrimary, size: 18),
          ),
          SizedBox(width: 14),
          // Label and value stacked vertically
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                SizedBox(height: 2),
                Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a status badge showing Active or Restricted status.
  /// Green for active, red for restricted accounts.
  Widget _buildStatusBadge(String status) {
    bool isActive = status == 'active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // Background color with low opacity
        color: (isActive ? AppTheme.success : AppTheme.error).withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        // Border for definition
        border: Border.all(color: (isActive ? AppTheme.success : AppTheme.error).withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Only take needed width
        children: [
          // Status icon
          Icon(
            isActive ? Icons.check_circle : Icons.block,
            color: isActive ? AppTheme.success : AppTheme.error,
            size: 16,
          ),
          SizedBox(width: 6),
          // Status text
          Text(
            isActive ? "Active Account" : "Restricted Account",
            style: TextStyle(
              color: isActive ? AppTheme.success : AppTheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // ADD PATIENT DIALOG
  // ===========================================

  /// Shows a dialog form to register a new patient.
  /// Collects: name, national ID, password, DOB, gender, blood type, phone, address.
  /// Uses Form with validation and dropdowns for gender/blood type.
  void _showAddPatientDialog() {
    // Form key for validation
    final formKey = GlobalKey<FormState>();
    
    // Text controllers for each input field
    TextEditingController fullNameCtrl = TextEditingController();
    TextEditingController nationalIdCtrl = TextEditingController();
    TextEditingController dobCtrl = TextEditingController();
    TextEditingController phoneCtrl = TextEditingController();
    TextEditingController addressCtrl = TextEditingController();
    TextEditingController passwordCtrl = TextEditingController();
    
    // Selected values for dropdown fields
    String? selectedGender;
    String? selectedBloodType;

    // Options for dropdown menus
    final genders = ['Male', 'Female'];
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        
        // Dialog title with icon
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.nursePrimary.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person_add, color: AppTheme.nursePrimary),
            ),
            SizedBox(width: 12),
            Text(
              "Register New Patient",
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(fullNameCtrl, "Full Name", Icons.person_outline),
                SizedBox(height: 14),
                _buildDialogTextField(nationalIdCtrl, "National ID", Icons.credit_card),
                SizedBox(height: 14),
                _buildDialogTextField(passwordCtrl, "Password", Icons.lock_outline, isPassword: true),
                SizedBox(height: 14),
                _buildDateField(dobCtrl, ctx),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Gender", genders, selectedGender, (v) => selectedGender = v)),
                    SizedBox(width: 12),
                    Expanded(child: _buildDropdown("Blood Type", bloodTypes, selectedBloodType, (v) => selectedBloodType = v)),
                  ],
                ),
                SizedBox(height: 14),
                _buildDialogTextField(phoneCtrl, "Phone (+123...)", Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.startsWith('+')) return 'Must start with +';
                    return null;
                  }
                ),
                SizedBox(height: 14),
                _buildDialogTextField(addressCtrl, "Address", Icons.home_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
          ),
          GestureDetector(
            onTap: () async {
              if (formKey.currentState!.validate() && selectedGender != null && selectedBloodType != null) {
                Navigator.pop(ctx);
                var res = await ApiService.addPatient(
                  fullName: fullNameCtrl.text,
                  nationalId: nationalIdCtrl.text,
                  password: passwordCtrl.text,
                  dateOfBirth: dobCtrl.text,
                  gender: selectedGender!,
                  bloodType: selectedBloodType!,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                );
                _showSnackBar(res['message'] ?? 'Patient added', res['success'] == true);
                if (res['success'] == true) _loadPatients();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.nursePrimary, AppTheme.nurseSecondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Register", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ================= EDIT PATIENT DIALOG (with password) =================
  void _showEditPatientDialog(Map<String, dynamic> patient) {
    final formKey = GlobalKey<FormState>();
    TextEditingController fullNameCtrl = TextEditingController(text: patient['full_name']);
    TextEditingController dobCtrl = TextEditingController(text: patient['date_of_birth'] ?? '');
    TextEditingController phoneCtrl = TextEditingController(text: patient['phone_number'] ?? '');
    TextEditingController addressCtrl = TextEditingController(text: patient['address'] ?? '');
    TextEditingController passwordCtrl = TextEditingController(); // Empty for optional password change
    String? selectedGender = patient['gender'];
    String? selectedBloodType = patient['blood_type'];

    final genders = ['Male', 'Female'];
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.nursePrimary.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit, color: AppTheme.nursePrimary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Edit Patient",
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(fullNameCtrl, "Full Name", Icons.person_outline),
                SizedBox(height: 14),
                _buildDialogTextField(passwordCtrl, "New Password", Icons.lock_outline,
                  isPassword: true,
                  validator: (v) => null, // Optional
                ),
                SizedBox(height: 14),
                _buildDateField(dobCtrl, ctx),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Gender", genders, selectedGender, (v) => selectedGender = v)),
                    SizedBox(width: 12),
                    Expanded(child: _buildDropdown("Blood Type", bloodTypes, selectedBloodType, (v) => selectedBloodType = v)),
                  ],
                ),
                SizedBox(height: 14),
                _buildDialogTextField(phoneCtrl, "Phone", Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.startsWith('+')) return 'Must start with +';
                    return null;
                  }
                ),
                SizedBox(height: 14),
                _buildDialogTextField(addressCtrl, "Address", Icons.home_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
          ),
          GestureDetector(
            onTap: () async {
              if (formKey.currentState!.validate() && selectedGender != null && selectedBloodType != null) {
                Navigator.pop(ctx);
                int patientId = int.parse(patient['patient_id'].toString());
                int userId = int.parse(patient['user_id'].toString());
                var res = await ApiService.updatePatient(
                  patientId: patientId,
                  userId: userId,
                  fullName: fullNameCtrl.text,
                  dateOfBirth: dobCtrl.text,
                  gender: selectedGender!,
                  bloodType: selectedBloodType!,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                  password: passwordCtrl.text, // Empty string if not changing
                );
                _showSnackBar(res['message'] ?? 'Patient updated', res['success'] == true);
                if (res['success'] == true) _loadPatients();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.nursePrimary, AppTheme.nurseSecondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _deletePatient(int patientId, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            SizedBox(width: 12),
            Text("Confirm Delete", style: GoogleFonts.inter(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete $name? This will also remove their login account.",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      var res = await ApiService.deletePatient(patientId);
      _showSnackBar(res['message'] ?? 'Patient deleted', res['success'] == true);
      if (res['success'] == true) _loadPatients();
    }
  }

  // ================= HELPER WIDGETS =================
  Widget _buildDialogTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool isPassword = false, String? Function(String?)? validator, int maxLines = 1}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.textPrimary),
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.nursePrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, BuildContext ctx) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: TextStyle(color: AppTheme.textPrimary),
      validator: (v) => v!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: "Date of Birth",
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: ctx,
          initialDate: DateTime(2000),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: AppTheme.nursePrimary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      dropdownColor: AppTheme.cardDark,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppTheme.glassWhite,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nurseGradient.first,
      body: GradientBackground(
        colors: AppTheme.nurseGradient,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom App Bar
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.nursePrimary.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.people, color: AppTheme.nursePrimary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Manage Patients",
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SolidCard(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      borderRadius: 16,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Search by name or National ID...",
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppTheme.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadPatients();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => _loadPatients(val),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Patients List
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: AppTheme.nursePrimary))
                        : _patientsList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _patientsList.length,
                                itemBuilder: (context, index) {
                                  var patient = _patientsList[index];
                                  return _buildPatientCard(patient);
                                },
                              ),
                  ),

                  // Add Button
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: GlassButton(
                      text: "Register New Patient",
                      onPressed: _showAddPatientDialog,
                      color: AppTheme.nursePrimary,
                      icon: Icons.person_add,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    String status = patient['account_status'] ?? 'active';
    bool isActive = status == 'active';
    
    return GestureDetector(
      onTap: () => _showPatientDetails(patient),
      child: SolidCard(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        borderColor: AppTheme.nursePrimary.withAlpha(38),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.nursePrimary, AppTheme.nurseSecondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      patient['full_name'][0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Status dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.success : AppTheme.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['full_name'],
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: AppTheme.textMuted, size: 14),
                      SizedBox(width: 6),
                      Text(
                        patient['national_id'] ?? 'N/A',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (patient['blood_type'] != null) ...[
                        Icon(Icons.water_drop, color: AppTheme.error, size: 14),
                        SizedBox(width: 4),
                        Text(patient['blood_type'], style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        SizedBox(width: 12),
                      ],
                      Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 14),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          patient['phone_number'] ?? 'N/A',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SolidCard(
        margin: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 60, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              "No Patients Found",
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "Register your first patient to get started",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
