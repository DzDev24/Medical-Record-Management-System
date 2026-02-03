// ============================================
// MANAGE_STAFF_SCREEN.DART - Staff CRUD Operations
// ============================================
// This screen allows admins to manage staff members (doctors, nurses, admins).
// Features:
// - View list of staff filtered by role
// - Search staff by name or username
// - Add new staff with role-specific fields (specialty for doctors, department for nurses)
// - Edit existing staff information
// - Delete staff members
// All operations sync with the PHP backend via ApiService.

import 'dart:ui'; // For blur effects
import 'package:flutter/material.dart'; // Core Flutter UI
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// ManageStaffScreen - Admin screen for managing staff members.
/// The 'role' parameter determines which type of staff to display/manage.
class ManageStaffScreen extends StatefulWidget {
  final String role; // 'doctor', 'nurse', or 'admin' - determines which staff type to manage

  const ManageStaffScreen({super.key, required this.role});

  @override
  _ManageStaffScreenState createState() => _ManageStaffScreenState();
}

/// State class for ManageStaffScreen.
/// Handles data loading, CRUD operations, and UI state management.
class _ManageStaffScreenState extends State<ManageStaffScreen> with SingleTickerProviderStateMixin {
  // ==========================================
  // STATE VARIABLES
  // ==========================================
  
  List<dynamic> _staffList = []; // List of staff fetched from API
  List<dynamic> _specialties = []; // List of medical specialties (for doctors)
  List<dynamic> _departments = []; // List of hospital departments (for nurses)

  bool _isLoading = true; // Shows loading indicator while fetching data
  final TextEditingController _searchController = TextEditingController(); // Search input

  // Animation controllers for smooth entrance
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // ==========================================
  // COMPUTED PROPERTIES (Getters)
  // ==========================================
  // These change based on the role being managed.
  
  Color get _themeColor => AppTheme.adminPrimary;  // Admin screens always use green
  List<Color> get _gradientColors => AppTheme.adminGradient;  // Admin gradient
  String get _extraFieldLabel => widget.role == 'doctor' ? "Specialty" : "Department"; // Dynamic label
  IconData get _roleIcon => widget.role == 'doctor' ? Icons.medical_services : Icons.local_hospital;

  /// Initialize state - set up animations and fetch initial data.
  @override
  void initState() {
    super.initState();
    // Set up fade-in animation
    _animController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(); // Start animation
    _fetchData(); // Load staff list from API
  }

  /// Clean up resources to prevent memory leaks.
  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================
  // DATA LOADING
  // ===========================================

  /// Fetches initial data: metadata (specialties/departments) and staff list.
  /// Called once during initState to populate dropdowns and list.
  void _fetchData() async {
    setState(() { _isLoading = true; });

    // Fetch metadata (specialties for doctors, departments for nurses)
    var meta = await ApiService.getMetadata();
    if (meta.isNotEmpty) {
      _specialties = meta['specialties'] ?? []; // List of medical specialties
      _departments = meta['departments'] ?? []; // List of hospital departments
    }

    // Load staff list after metadata is ready
    _loadStaff();
  }

  /// Loads staff members from API filtered by role.
  /// Optional query parameter enables search functionality.
  void _loadStaff([String query = ""]) async {
    var data = await ApiService.getStaff(widget.role, query: query);
    setState(() {
      _staffList = data; // Update list
      _isLoading = false; // Hide spinner
    });
  }

  // ===========================================
  // VALIDATION HELPERS
  // ===========================================

  /// Validates phone number format.
  /// Must start with + followed by digits, dashes, or # symbols.
  bool _isPhoneValid(String phone) {
    final RegExp regex = RegExp(r'^\+[0-9\-#]+$');
    return regex.hasMatch(phone);
  }

  /// Returns dropdown menu items for specialty (doctors) or department (nurses).
  /// Built dynamically from the _specialties or _departments list.
  List<DropdownMenuItem<String>> _getDropdownItems() {
    // Select source list based on role type
    List<dynamic> source = widget.role == 'doctor' ? _specialties : _departments;
    // Map each item to a DropdownMenuItem
    return source.map((item) {
      return DropdownMenuItem<String>(
        value: item['id'].toString(), // Use ID as value
        child: Text(item['name']), // Display name
      );
    }).toList();
  }

  // ===========================================
  // STAFF DETAILS MODAL (Bottom Sheet)
  // ===========================================

  /// Shows a modal bottom sheet with detailed staff information.
  /// Displays avatar, username, specialty/department, phone, and Edit/Delete actions.
  void _showStaffDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent for custom shape
      isScrollControlled: true, // Enable full height control
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65, // 65% of screen
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // --- DRAG HANDLE BAR ---
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
                    // --- STAFF AVATAR ---
                    // Gradient circle with first letter of name
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_themeColor, _themeColor.withAlpha(178)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          item['full_name'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // --- STAFF NAME ---
                    Text(
                      item['full_name'],
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    
                    // --- ROLE BADGE ---
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _themeColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.role == 'doctor' ? "Doctor" : "Nurse",
                        style: TextStyle(color: _themeColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // --- INFO CARDS ---
                    _buildDetailRow(Icons.person_outline, "Username", item['username'] ?? 'N/A'),
                    _buildDetailRow(
                      widget.role == 'doctor' ? Icons.work_outline : Icons.apartment,
                      _extraFieldLabel,
                      item['extra_info'] ?? 'N/A',
                    ),
                    _buildDetailRow(Icons.phone, "Phone", item['phone_number'] ?? 'N/A'),
                    
                    SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showEditDialog(item);
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
                              _deleteUser(int.parse(item['user_id'].toString()), item['full_name']);
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
  
  /// Builds a detail row for displaying staff information.
  /// Shows icon, label, and value in a styled container.
  /// 
  /// Parameters:
  ///   icon - Icon to display on the left
  ///   label - Small label text (e.g., "Username")
  ///   value - Main value text (e.g., "john_doe")
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
              color: _themeColor.withAlpha(51), // 20% opacity of theme color
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _themeColor, size: 18),
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

  // ===========================================
  // ADD STAFF DIALOG
  // ===========================================

  /// Shows a dialog form to add a new staff member (doctor or nurse).
  /// Collects: username, password, full name, specialty/department, phone.
  /// Form validation ensures all required fields are filled.
  void _showAddDialog() {
    // Form key for validation
    final formKey = GlobalKey<FormState>();
    
    // Text controllers for input fields
    TextEditingController userCtrl = TextEditingController(); // Username
    TextEditingController passCtrl = TextEditingController(); // Password
    TextEditingController nameCtrl = TextEditingController(); // Full name
    TextEditingController phoneCtrl = TextEditingController(); // Phone number
    String? selectedExtraId; // Selected specialty or department ID

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // White for better form visibility
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        
        // Dialog title with role-appropriate icon
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_roleIcon, color: _themeColor),
            ),
            SizedBox(width: 12),
            Text(
              "Add New ${widget.role == 'doctor' ? 'Doctor' : 'Nurse'}",
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
            ),
          ],
        ),
        
        // Form content with text fields
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Only take needed height
              children: [
                _buildDialogTextField(userCtrl, "Username", Icons.person_outline),
                SizedBox(height: 16),
                _buildDialogTextField(passCtrl, "Password", Icons.lock_outline, isPassword: true),
                SizedBox(height: 16),
                _buildDialogTextField(nameCtrl, "Full Name", Icons.badge_outlined),
                SizedBox(height: 16),
                _buildDropdownField(selectedExtraId, (val) => selectedExtraId = val),
                SizedBox(height: 16),
                // Phone field with custom validation
                _buildDialogTextField(phoneCtrl, "Phone (+123...)", Icons.phone_outlined, 
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!_isPhoneValid(v)) return 'Must start with +';
                    return null;
                  }
                ),
              ],
            ),
          ),
        ),
        
        // Action buttons
        actions: [
          // Cancel button (red)
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
          // Add button (theme color)
          GestureDetector(
            onTap: () async {
              // Validate form and ensure dropdown selection
              if (formKey.currentState!.validate() && selectedExtraId != null) {
                Navigator.pop(ctx);
                // Call API to add staff member
                var res = await ApiService.addStaff(
                  userCtrl.text,
                  passCtrl.text,
                  widget.role,
                  nameCtrl.text,
                  selectedExtraId!,
                  phoneCtrl.text,
                );
                _showSnackBar(res['message'], res['success'] == true);
                _loadStaff(); // Refresh list
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_themeColor, _themeColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // EDIT STAFF DIALOG
  // ===========================================

  /// Shows a dialog form to edit an existing staff member.
  /// Pre-populates form with current values from the item parameter.
  /// Password field is optional - only updates if new value is provided.
  void _showEditDialog(Map<String, dynamic> item) {
    // Form key for validation
    final formKey = GlobalKey<FormState>();
    
    // Text controllers pre-populated with existing values
    TextEditingController userCtrl = TextEditingController(text: item['username']);
    TextEditingController passCtrl = TextEditingController(); // Empty - optional password change
    TextEditingController nameCtrl = TextEditingController(text: item['full_name']);
    TextEditingController phoneCtrl = TextEditingController(text: item['phone_number'] ?? "");

    // Pre-select current specialty/department
    String? selectedExtraId = item['extra_id'].toString();
    // Verify the ID exists in dropdown options
    bool idExists = _getDropdownItems().any((dd) => dd.value == selectedExtraId);
    if (!idExists) selectedExtraId = null; // Reset if not found

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        
        // Dialog title with staff name
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit, color: _themeColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Edit ${item['full_name']}",
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                overflow: TextOverflow.ellipsis, // Truncate if too long
              ),
            ),
          ],
        ),
        
        // Form content
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(userCtrl, "Username", Icons.person_outline),
                SizedBox(height: 16),
                // Password field with optional validation
                _buildDialogTextField(passCtrl, "New Password (optional)", Icons.lock_outline, 
                  isPassword: true, 
                  validator: (v) => null, // Always valid (optional)
                ),
                SizedBox(height: 16),
                _buildDialogTextField(nameCtrl, "Full Name", Icons.badge_outlined),
                SizedBox(height: 16),
                _buildDropdownField(selectedExtraId, (val) => selectedExtraId = val),
                SizedBox(height: 16),
                _buildDialogTextField(phoneCtrl, "Phone", Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!_isPhoneValid(v)) return 'Must start with +';
                    return null;
                  }
                ),
              ],
            ),
          ),
        ),
        
        // Action buttons
        actions: [
          // Cancel button
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
          // Save button
          GestureDetector(
            onTap: () async {
              if (formKey.currentState!.validate() && selectedExtraId != null) {
                Navigator.pop(ctx);
                // Parse user ID from item
                int uId = int.parse(item['user_id'].toString());
                // Call API to update staff
                var res = await ApiService.updateStaff(
                  uId,
                  userCtrl.text,
                  passCtrl.text, // Empty string if not changing
                  widget.role,
                  nameCtrl.text,
                  selectedExtraId!,
                  phoneCtrl.text,
                );
                _showSnackBar(res['message'], res['success'] == true);
                _loadStaff(); // Refresh list
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_themeColor, _themeColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // FORM FIELD BUILDERS
  // ===========================================

  /// Builds a styled TextFormField for dialog forms.
  /// 
  /// Parameters:
  ///   controller - TextEditingController for the input
  ///   label - Floating label text
  ///   icon - Prefix icon
  ///   isPassword - If true, obscures input text
  ///   validator - Optional custom validation function
  Widget _buildDialogTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool isPassword = false, String? Function(String?)? validator}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword, // Hide password input
      style: TextStyle(color: AppTheme.textPrimary),
      // Use provided validator or default "Required" check
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        filled: true,
        fillColor: Color(0xFFF1F5F9), // Light gray for visibility
        // Border styling for different states
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFCBD5E1)), // Subtle gray border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFCBD5E1)), // Subtle gray border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _themeColor, width: 2), // Theme color on focus
        ),
      ),
    );
  }

  /// Builds a styled dropdown field for specialty/department selection.
  Widget _buildDropdownField(String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: _extraFieldLabel, // "Specialty" or "Department"
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(
          widget.role == 'doctor' ? Icons.work_outline : Icons.apartment,
          color: AppTheme.textMuted,
        ),
        filled: true,
        fillColor: Color(0xFFF1F5F9), // Light gray for visibility
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFCBD5E1)), // Subtle gray border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFCBD5E1)), // Subtle gray border
        ),
      ),
      items: _getDropdownItems(), // Dynamically built from metadata
      onChanged: onChanged, // Update selection callback
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  void _deleteUser(int id, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            SizedBox(width: 12),
            Text("Confirm Delete", style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete $name? This action cannot be undone.",
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
      await ApiService.deleteUser(id);
      _showSnackBar("$name deleted successfully", true);
      _loadStaff();
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: _gradientColors,
        child: SafeArea(
          child: FadeTransition(
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
                          color: _themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_roleIcon, color: _themeColor),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Manage ${widget.role == 'doctor' ? 'Doctors' : 'Nurses'}",
                        style: TextStyle(
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
                  child: GlassCard(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 16,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Search by name...",
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: AppTheme.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadStaff();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _loadStaff(val),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Staff List
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: _themeColor))
                      : _staffList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _staffList.length,
                              itemBuilder: (context, index) {
                                var item = _staffList[index];
                                return _buildStaffCard(item);
                              },
                            ),
                ),

                // Add Button
                Padding(
                  padding: EdgeInsets.all(16),
                  child: GlassButton(
                    text: "Add New ${widget.role == 'doctor' ? 'Doctor' : 'Nurse'}",
                    onPressed: _showAddDialog,
                    color: _themeColor,
                    icon: Icons.person_add,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showStaffDetails(item),
      child: SolidCard(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        borderColor: _themeColor.withAlpha(38),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_themeColor, _themeColor.withAlpha(178)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  item['full_name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['full_name'],
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        widget.role == 'doctor' ? Icons.work_outline : Icons.apartment,
                        color: AppTheme.textMuted,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['extra_info'] ?? 'N/A',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 14),
                      SizedBox(width: 6),
                      Text(
                        item['phone_number'] ?? 'N/A',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron indicator
            Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        margin: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_roleIcon, size: 60, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              "No ${widget.role == 'doctor' ? 'Doctors' : 'Nurses'} Found",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Add your first ${widget.role} to get started",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}