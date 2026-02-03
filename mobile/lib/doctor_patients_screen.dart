// ============================================
// DOCTOR_PATIENTS_SCREEN.DART - Patient List for Doctors
// ============================================
// This screen allows doctors to view and search all patients in the system.
// Features:
// - View list of all patients
// - Search patients by name or national ID
// - Navigate to detailed patient view with medical history
// - Doctors can view records but cannot edit patient information
// (only nurses have edit access to patient data)

import 'package:flutter/material.dart'; // Core Flutter UI
import 'package:google_fonts/google_fonts.dart'; // Custom typography
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls
import 'patient_detail_screen.dart'; // Detailed patient view screen

/// DoctorPatientsScreen - Allows doctors to browse and search all patients.
/// Tapping a patient navigates to PatientDetailScreen for full medical history.
class DoctorPatientsScreen extends StatefulWidget {
  final int doctorId; // The logged-in doctor's ID (for consultations)
  final String doctorName; // Doctor's name (displayed in consultations)

  const DoctorPatientsScreen({super.key, required this.doctorId, required this.doctorName});

  @override
  _DoctorPatientsScreenState createState() => _DoctorPatientsScreenState();
}

/// State class for DoctorPatientsScreen.
/// Manages patient list, search functionality, and UI animations.
class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> with SingleTickerProviderStateMixin {
  // ==========================================
  // STATE VARIABLES
  // ==========================================
  
  List<dynamic> _patientsList = []; // List of patients from database
  bool _isLoading = true; // Shows loading indicator while fetching
  final TextEditingController _searchController = TextEditingController(); // Search input controller

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

  /// Loads patients from the API with optional search query.
  /// Called on initial load and when search text changes.
  void _loadPatients([String query = ""]) async {
    setState(() { _isLoading = true; });
    // Use getPatientsForDoctor API endpoint (read-only view)
    var data = await ApiService.getPatientsForDoctor(query: query);
    setState(() {
      _patientsList = data;
      _isLoading = false;
    });
  }

  /// Main build method - constructs the entire patient list screen UI.
  /// Uses LayoutBuilder for responsive sizing and FadeTransition for animation.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color for any edges visible during overscroll
      backgroundColor: AppTheme.doctorGradient.first,
      
      // GradientBackground is our custom widget from app_theme.dart
      body: GradientBackground(
        colors: AppTheme.doctorGradient, // Blue gradient for doctor screens
        
        // SafeArea keeps content away from system UI (notch, status bar)
        child: SafeArea(
          // LayoutBuilder provides constraints for responsive design
          // 'constraints' contains the available width and height
          child: LayoutBuilder(
            builder: (context, constraints) => FadeTransition(
              // FadeTransition applies the fade-in animation to all children
              opacity: _fadeAnimation, // 0.0 = invisible, 1.0 = fully visible
              
              // Column arranges children vertically: header, search, list
              child: Column(
                children: [
                  // --- CUSTOM APP BAR ---
                  // Built manually instead of using AppBar for more design control
                  Padding(
                    padding: EdgeInsets.all(16), // 16px padding on all sides
                    child: Row(
                      children: [
                        // Back button - glassmorphism styled container
                        GestureDetector(
                          onTap: () => Navigator.pop(context), // Go back to DoctorHome
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.glassWhite, // Semi-transparent white
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
                          ),
                        ),
                        SizedBox(width: 16), // Horizontal spacing
                        
                        // People icon in colored container
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.doctorPrimary.withAlpha(51), // 20% opacity blue
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.people, color: AppTheme.doctorPrimary),
                        ),
                        SizedBox(width: 12),
                        
                        // Title and subtitle (Expanded to fill remaining space)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
                            children: [
                              // Main title with Google Fonts styling
                              Text(
                                "My Patients",
                                style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Subtitle with muted color
                              Text(
                                "View and manage patient records",
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- SEARCH BAR ---
                  // Allows doctors to search patients by name or national ID
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16), // Only left/right padding
                    // SolidCard is our custom card widget from app_theme.dart
                    child: SolidCard(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      borderRadius: 16,
                      // TextField for search input
                      child: TextField(
                        controller: _searchController, // Controller to read/clear text
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Search patients by name or ID...",
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                          // Show clear button (X) only when there's text
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppTheme.textMuted),
                                  onPressed: () {
                                    _searchController.clear(); // Clear the text
                                    _loadPatients(); // Reload all patients
                                  },
                                )
                              : null, // No button when empty
                          border: InputBorder.none, // Remove default border
                        ),
                        // onChanged fires every time user types
                        // Immediately searches with new query
                        onChanged: (val) => _loadPatients(val),
                      ),
                    ),
                  ),

                  SizedBox(height: 16), // Vertical spacing

                  // --- PATIENTS LIST ---
                  // Expanded fills remaining vertical space
                  Expanded(
                    // Conditional rendering using ternary operators:
                    // if loading? show spinner : if empty? show empty state : show list
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: AppTheme.doctorPrimary))
                        : _patientsList.isEmpty
                            ? _buildEmptyState() // Custom empty state widget
                            // ListView.builder efficiently builds items on demand
                            // Only renders visible items for performance
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _patientsList.length, // Total number of patients
                                // itemBuilder creates each item as it scrolls into view
                                itemBuilder: (context, index) {
                                  var patient = _patientsList[index]; // Get patient at index
                                  return _buildPatientCard(patient); // Build card widget
                                },
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

  /// Builds a single patient card for the ListView.
  /// Shows patient avatar, name, national ID, blood type, and gender.
  /// Tapping navigates to PatientDetailScreen for full medical history.
  Widget _buildPatientCard(Map<String, dynamic> patient) {
    // GestureDetector makes the entire card tappable
    return GestureDetector(
      onTap: () {
        // Navigate to patient detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailScreen(
              patient: patient, // Pass patient data
              doctorId: widget.doctorId, // Pass doctor ID for consultations
              doctorName: widget.doctorName, // Pass doctor name
            ),
          ),
        // .then() is called when returning from detail screen
        // Reload the list in case data changed
        ).then((_) => _loadPatients(_searchController.text));
      },
      
      // SolidCard is our custom card widget from app_theme.dart
      child: SolidCard(
        margin: EdgeInsets.only(bottom: 12), // Space below each card
        padding: EdgeInsets.all(16), // Inner padding
        borderColor: AppTheme.doctorPrimary.withAlpha(38), // Light blue border
        
        // Row layout: avatar | info | chevron
        child: Row(
          children: [
            // --- PATIENT AVATAR ---
            // Shows first letter of name in a gradient circle
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                // Gradient from primary to secondary color
                gradient: LinearGradient(
                  colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                // First letter of name, uppercase
                child: Text(
                  patient['full_name'][0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 14), // Horizontal spacing

            // --- PATIENT INFO ---
            // Expanded fills available horizontal space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
                children: [
                  // Patient name (truncated if too long)
                  Text(
                    patient['full_name'],
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis, // Show "..." if too long
                  ),
                  SizedBox(height: 4),
                  
                  // National ID with icon
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: AppTheme.textMuted, size: 14),
                      SizedBox(width: 6),
                      Text(
                        patient['national_id'] ?? 'N/A', // 'N/A' if null
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  
                  // Blood type and gender (conditional rendering)
                  Row(
                    children: [
                      // Blood type (only if present)
                      // Spread operator (...[]) conditionally adds widgets
                      if (patient['blood_type'] != null) ...[
                        Icon(Icons.water_drop, color: AppTheme.error, size: 14),
                        SizedBox(width: 4),
                        Text(patient['blood_type'], style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        SizedBox(width: 12),
                      ],
                      // Gender with appropriate icon (only if present)
                      if (patient['gender'] != null) ...[
                        Icon(patient['gender'] == 'Male' ? Icons.male : Icons.female, 
                             color: AppTheme.textMuted, size: 14),
                        SizedBox(width: 4),
                        Text(patient['gender'], style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // --- CHEVRON ARROW ---
            // Indicates the card is tappable/navigable
            Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 24),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state widget shown when no patients are found.
  /// Displayed when the search returns no results or list is empty.
  Widget _buildEmptyState() {
    return Center(
      // SolidCard provides a styled container
      child: SolidCard(
        margin: EdgeInsets.all(40), // Large margin for centered appearance
        child: Column(
          mainAxisSize: MainAxisSize.min, // Only take up needed space
          children: [
            // Large people icon to indicate empty patient list
            Icon(Icons.people_outline, size: 60, color: AppTheme.textMuted),
            SizedBox(height: 16),
            // "No Patients Found" title
            Text(
              "No Patients Found",
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            // Helpful instruction text
            Text(
              "Search for patients to view their records",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
