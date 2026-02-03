// ============================================
// PATIENT_MEDICAL_RECORDS_SCREEN.DART - Patient's Medical Records View
// ============================================
// This screen allows PATIENTS to view their own medical history.
// Accessed from the PatientHome screen via "Records" quick action button.
// 
// Features:
// - Tab-based navigation: Consultations, Prescriptions, Lab Results
// - View past consultations with diagnoses and doctor notes
// - View all prescriptions (medication, dosage, frequency, duration)
// - View lab results and open attached files (PDFs/images)
// 
// NOTE: This is a READ-ONLY view for patients. They CANNOT edit any records.
// Only doctors can add consultations/prescriptions/lab results.

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Custom typography (Inter font)
import 'package:intl/intl.dart'; // Date formatting (e.g., "Jan 01, 2024")
import 'package:url_launcher/url_launcher.dart'; // Opens lab result files in browser
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// PatientMedicalRecordsScreen - Allows patients to view their complete medical history.
/// Read-only access to consultations, prescriptions, and lab results.
/// This is a StatefulWidget because it needs to manage:
/// 1. Tab controller state (which tab is currently selected)
/// 2. Loading state (showing spinner vs data)
/// 3. Fetched data from API
class PatientMedicalRecordsScreen extends StatefulWidget {
  final int userId; // Patient's user ID - used to fetch their records from API
  final String patientName; // Displayed in header bar

  // Constructor - requires both userId and patientName to be passed
  const PatientMedicalRecordsScreen({
    super.key, // Flutter 3 shorthand for key parameter
    required this.userId, // 'required' ensures this must be provided
    required this.patientName,
  });

  // Creates the mutable state for this widget
  @override
  _PatientMedicalRecordsScreenState createState() => _PatientMedicalRecordsScreenState();
}

/// State class - manages data loading, tab navigation, and UI state.
/// 'SingleTickerProviderStateMixin' is required for TabController animation.
/// A Ticker is like a clock that ticks every frame - needed for smooth tab animations.
class _PatientMedicalRecordsScreenState extends State<PatientMedicalRecordsScreen> with SingleTickerProviderStateMixin {
  
  // ===========================================
  // STATE VARIABLES
  // ===========================================
  
  // TabController manages which tab is selected and handles swipe animations
  // 'late' means it will be initialized in initState() before first use
  late TabController _tabController;
  
  // Loading flag - when true, shows a spinner instead of the data
  bool _isLoading = true;
  
  // All medical records from API stored here
  // Structure: { 'consultations': [...], 'prescriptions': [...], 'lab_results': [...] }
  Map<String, dynamic> _data = {};
  
  // Error message if API call fails - shown to user
  String? _error;

  // ===========================================
  // LIFECYCLE METHODS
  // ===========================================

  /// initState() is called once when the widget is first created.
  /// This is where we set up controllers and fetch initial data.
  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    
    // Create TabController with 3 tabs (Consultations, Prescriptions, Lab Results)
    // 'vsync: this' connects it to this State's ticker for smooth animations
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch medical records from API
    _loadData();
  }

  /// dispose() is called when the widget is removed from the tree.
  /// IMPORTANT: Always dispose controllers to prevent memory leaks!
  @override
  void dispose() {
    _tabController.dispose(); // Free up TabController resources
    super.dispose(); // Always call super.dispose() last
  }

  // ===========================================
  // DATA LOADING
  // ===========================================

  /// Fetches all medical records for this patient from the API.
  /// This is an async function - it returns a Future and uses 'await'.
  Future<void> _loadData() async {
    // Show loading spinner by setting _isLoading to true
    setState(() => _isLoading = true);
    
    try {
      // await pauses execution until the API call completes
      // widget.userId accesses the userId from the parent StatefulWidget
      var result = await ApiService.getPatientFullRecords(widget.userId);
      
      // Update state with the fetched data
      // setState() tells Flutter to rebuild the UI
      setState(() {
        _data = result; // API returns { consultations: [...], prescriptions: [...], lab_results: [...] }
        _isLoading = false; // Hide loading spinner
        _error = result['error']; // Will be null if successful
      });
    } catch (e) {
      // catch block handles any errors (network issues, server errors, etc.)
      setState(() {
        _isLoading = false;
        _error = e.toString(); // Convert error to string for display
      });
    }
  }

  // ===========================================
  // BUILD METHOD - Main UI Construction
  // ===========================================

  /// build() is called every time setState() is called.
  /// It returns the widget tree that Flutter renders on screen.
  @override
  Widget build(BuildContext context) {
    // Scaffold is the base layout structure for a screen
    return Scaffold(
      // Allow body to extend behind the app bar (for gradient effect)
      extendBodyBehindAppBar: true,
      
      // Body uses our custom GradientBackground widget from app_theme.dart
      body: GradientBackground(
        colors: AppTheme.patientGradient, // Purple gradient for patient screens
        
        // SafeArea ensures content doesn't overlap with system UI (notch, status bar)
        child: SafeArea(
          // Column arranges children vertically (header, tabs, content)
          child: Column(
            children: [
              // Header with back button, title, and refresh button
              _buildHeader(),
              
              // Tab bar for switching between sections
              _buildTabBar(),
              
              // Expanded takes up remaining space in the Column
              Expanded(
                // Conditional rendering based on state:
                // 1. If loading, show spinner
                // 2. If error, show error message
                // 3. Otherwise, show tab content
                child: _isLoading
                    // CircularProgressIndicator is a spinning loading indicator
                    ? Center(child: CircularProgressIndicator(color: AppTheme.patientPrimary))
                    : _error != null
                        // Center widget centers its child both horizontally and vertically
                        ? Center(child: Text(_error!, style: TextStyle(color: AppTheme.error)))
                        // TabBarView shows different content for each tab
                        : TabBarView(
                            controller: _tabController, // Links to our TabController
                            // Children match the order of tabs in TabBar
                            children: [
                              _buildConsultationsTab(), // First tab content
                              _buildPrescriptionsTab(), // Second tab content
                              _buildLabResultsTab(), // Third tab content
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================
  // HEADER WIDGET
  // ===========================================

  /// Builds the header row with back button, title, and refresh button.
  Widget _buildHeader() {
    // Padding adds space around its child
    return Padding(
      padding: EdgeInsets.all(16), // 16 pixels on all sides
      
      // Row arranges children horizontally
      child: Row(
        children: [
          // --- BACK BUTTON ---
          // GestureDetector makes any widget tappable
          GestureDetector(
            // onTap callback fires when user taps
            onTap: () => Navigator.pop(context), // Go back to previous screen
            
            // Container is a box that can have decoration, padding, etc.
            child: Container(
              padding: EdgeInsets.all(10),
              
              // BoxDecoration adds visual styling (color, border, rounded corners)
              decoration: BoxDecoration(
                color: AppTheme.glassWhite, // Semi-transparent white
                borderRadius: BorderRadius.circular(12), // Rounded corners
                border: Border.all(color: AppTheme.glassBorder), // Border
              ),
              
              // Icon widget displays a material icon
              child: Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 22),
            ),
          ),
          
          // SizedBox adds fixed-size space between widgets
          SizedBox(width: 16),
          
          // --- TITLE SECTION ---
          // Expanded makes this widget take up all remaining horizontal space
          Expanded(
            // Column for vertical text arrangement
            child: Column(
              // Align text to the left
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main title with custom Google Fonts styling
                Text(
                  "Medical Records", 
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Subtitle showing patient name (from widget parameter)
                Text(
                  widget.patientName, 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // --- REFRESH BUTTON ---
          // IconButton is a pre-built tappable icon with ripple effect
          IconButton(
            onPressed: _loadData, // Calls our data loading function
            icon: Icon(Icons.refresh, color: AppTheme.patientPrimary),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // TAB BAR WIDGET
  // ===========================================

  /// Builds the tab bar for switching between Consultations, Prescriptions, Lab Results.
  Widget _buildTabBar() {
    return Container(
      // EdgeInsets.symmetric allows different horizontal and vertical padding
      margin: EdgeInsets.symmetric(horizontal: 16),
      
      // Dark card background for the tab bar
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      
      // TabBar is Flutter's built-in tab navigation widget
      child: TabBar(
        controller: _tabController, // Links to our TabController
        
        // Styling for selected and unselected tabs
        labelColor: AppTheme.patientPrimary, // Selected tab text color
        unselectedLabelColor: AppTheme.textMuted, // Unselected tab text color
        indicatorColor: AppTheme.patientPrimary, // Underline color
        indicatorSize: TabBarIndicatorSize.tab, // Indicator spans full tab width
        
        // Tab definitions - each Tab can have icon and/or text
        tabs: [
          Tab(icon: Icon(Icons.medical_services, size: 20), text: "Consultations"),
          Tab(icon: Icon(Icons.medication, size: 20), text: "Prescriptions"),
          Tab(icon: Icon(Icons.science, size: 20), text: "Lab Results"),
        ],
      ),
    );
  }

  // ===========================================
  // CONSULTATIONS TAB
  // ===========================================

  /// Builds the Consultations tab content - list of all consultations.
  Widget _buildConsultationsTab() {
    // Get consultations array from data, default to empty list if null
    List consultations = _data['consultations'] ?? [];
    
    // If no consultations, show empty state
    if (consultations.isEmpty) {
      return _buildEmptyState("No consultations yet", Icons.medical_services);
    }

    // RefreshIndicator enables pull-to-refresh gesture
    return RefreshIndicator(
      onRefresh: _loadData, // Function to call when user pulls to refresh
      
      // ListView.builder efficiently builds list items on demand
      // Only builds visible items, important for performance with long lists
      child: ListView.builder(
        padding: EdgeInsets.all(16), // Padding around the list
        itemCount: consultations.length, // Total number of items
        
        // itemBuilder is called for each visible item
        // 'index' is the position (0, 1, 2, ...)
        itemBuilder: (context, index) {
          var c = consultations[index]; // Get consultation at this index
          return _buildConsultationCard(c); // Build card widget for it
        },
      ),
    );
  }

  /// Builds a single consultation card widget.
  /// Shows diagnosis, doctor name, date, symptoms, and badges for prescriptions/lab results.
  Widget _buildConsultationCard(Map<String, dynamic> consultation) {
    // Parse the visit date string into a DateTime object
    // tryParse returns null if parsing fails
    DateTime? visitDate = DateTime.tryParse(consultation['visit_date'] ?? '');
    
    // Format the date nicely (e.g., "Jan 15, 2024")
    // DateFormat is from the intl package
    String formattedDate = visitDate != null 
        ? DateFormat('MMM dd, yyyy').format(visitDate) 
        : 'Unknown';
    
    // Get nested arrays for prescriptions and lab results
    List prescriptions = consultation['prescriptions'] ?? [];
    List labResults = consultation['lab_results'] ?? [];

    // GestureDetector makes the entire card tappable
    return GestureDetector(
      // Show details bottom sheet when tapped
      onTap: () => _showConsultationDetails(consultation),
      
      child: Container(
        margin: EdgeInsets.only(bottom: 12), // Space below each card
        padding: EdgeInsets.all(16), // Inner padding
        
        // Card styling with dark background and subtle border
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          // withAlpha sets transparency (0-255, lower = more transparent)
          border: Border.all(color: AppTheme.patientPrimary.withAlpha(30)),
        ),
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align children to left
          children: [
            // --- TOP ROW: Icon, diagnosis, doctor, date ---
            Row(
              children: [
                // Medical icon in colored circle
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.patientPrimary.withAlpha(30), // Light purple background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services, color: AppTheme.patientPrimary, size: 22),
                ),
                
                SizedBox(width: 12), // Spacing
                
                // Diagnosis and doctor name (expands to fill available space)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diagnosis text with ellipsis if too long
                      Text(
                        consultation['diagnosis'] ?? 'No diagnosis', 
                        style: TextStyle(
                          color: AppTheme.textPrimary, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 15,
                        ),
                        maxLines: 1, // Limit to one line
                        overflow: TextOverflow.ellipsis, // Show "..." if truncated
                      ),
                      // Doctor name
                      Text(
                        "Dr. ${consultation['doctor_name'] ?? 'Unknown'}", 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Date on the right side
                Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
            
            // --- SYMPTOMS (if present) ---
            // The spread operator (...) with 'if' conditionally adds widgets
            if (consultation['symptoms'] != null) ...[
              SizedBox(height: 10),
              Text(
                consultation['symptoms'], 
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 2, // Limit to 2 lines
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            SizedBox(height: 10),
            
            // --- BOTTOM ROW: Badges for Rx count and Lab count ---
            Row(
              children: [
                // Prescription badge (only if there are prescriptions)
                if (prescriptions.isNotEmpty)
                  _buildBadge("${prescriptions.length} Rx", AppTheme.nursePrimary),
                  
                // Spacing between badges
                if (prescriptions.isNotEmpty && labResults.isNotEmpty) 
                  SizedBox(width: 8),
                  
                // Lab results badge (only if there are lab results)
                if (labResults.isNotEmpty)
                  _buildBadge("${labResults.length} Lab", AppTheme.warning),
                  
                // Spacer pushes the chevron to the right
                Spacer(),
                
                // Chevron icon indicating this card is tappable
                Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a modal bottom sheet with full consultation details.
  /// Bottom sheets slide up from the bottom of the screen.
  void _showConsultationDetails(Map<String, dynamic> consultation) {
    // Extract data from consultation object
    List prescriptions = consultation['prescriptions'] ?? [];
    List labResults = consultation['lab_results'] ?? [];
    DateTime? visitDate = DateTime.tryParse(consultation['visit_date'] ?? '');
    String formattedDate = visitDate != null 
        ? DateFormat('MMMM dd, yyyy').format(visitDate) // Full month name
        : 'Unknown';

    // showModalBottomSheet displays a sheet that slides up from bottom
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // We'll handle background ourselves
      isScrollControlled: true, // Allow the sheet to take up more height
      
      // Builder function returns the sheet content
      builder: (ctx) => Container(
        // Sheet takes up 80% of screen height
        height: MediaQuery.of(context).size.height * 0.8,
        
        // Rounded top corners with dark background
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        
        child: Column(
          children: [
            // --- DRAG HANDLE (visual indicator that sheet can be dragged) ---
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
              // SingleChildScrollView enables scrolling for content that might overflow
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER with icon and title ---
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.patientPrimary.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.medical_services, color: AppTheme.patientPrimary, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Consultation", 
                                style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),

                    // --- INFO SECTIONS using helper method ---
                    _buildInfoSection("Doctor", "Dr. ${consultation['doctor_name'] ?? 'Unknown'}", Icons.person),
                    _buildInfoSection("Diagnosis", consultation['diagnosis'] ?? 'N/A', Icons.medical_information),
                    _buildInfoSection("Symptoms", consultation['symptoms'] ?? 'N/A', Icons.sick),

                    // Doctor notes (only if not empty)
                    if (consultation['doctor_notes'] != null && consultation['doctor_notes'].toString().isNotEmpty)
                      _buildInfoSection("Doctor Notes", consultation['doctor_notes'], Icons.note),

                    // --- PRESCRIPTIONS SECTION (if any) ---
                    if (prescriptions.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        "Prescriptions", 
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      // .map() transforms each prescription into a widget
                      // The spread operator (...) unpacks the list into the Column
                      ...prescriptions.map((p) => _buildPrescriptionItem(p)),
                    ],

                    // --- LAB RESULTS SECTION (if any) ---
                    if (labResults.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        "Lab Results", 
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      ...labResults.map((lr) => _buildLabResultItem(lr)),
                    ],
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
  // REUSABLE UI COMPONENTS
  // ===========================================

  /// Builds an info section card with icon, title, and value.
  /// Used for Doctor, Diagnosis, Symptoms, Notes in the detail view.
  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite, // Semi-transparent background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        // crossAxisAlignment.start aligns items at the top
        // (important when value text wraps to multiple lines)
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.patientPrimary, size: 20),
          SizedBox(width: 12),
          // Expanded allows the text to wrap properly
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                SizedBox(height: 2),
                Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a prescription item card showing medication details.
  Widget _buildPrescriptionItem(Map<String, dynamic> p) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.nursePrimary.withAlpha(20), // Light cyan background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.nursePrimary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: AppTheme.nursePrimary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medication name in bold
                Text(
                  p['medication_name'] ?? '', 
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                // Dosage, frequency, and duration separated by bullet points
                Text(
                  "${p['dosage'] ?? ''} • ${p['frequency'] ?? ''} • ${p['duration'] ?? ''}", 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a lab result item card with optional file attachment button.
  Widget _buildLabResultItem(Map<String, dynamic> lr) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha(20), // Light orange background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: AppTheme.warning, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lr['test_name'] ?? '', 
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                // Only show summary if it exists and isn't empty
                if (lr['result_summary'] != null && lr['result_summary'].toString().isNotEmpty)
                  Text(
                    lr['result_summary'], 
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          // File attachment button (only if file path exists)
          if (lr['result_file_path'] != null && lr['result_file_path'].toString().isNotEmpty)
            GestureDetector(
              onTap: () => _openLabFile(lr['result_file_path']), // Open file function
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.info.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_file, color: AppTheme.info, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================
  // FILE HANDLING
  // ===========================================

  /// Opens a lab result file in the device's default browser/app.
  /// Handles both single files and JSON arrays of multiple files.
  void _openLabFile(String filePath) async {
    try {
      // Check if filePath is a JSON array (starts with '[')
      if (filePath.startsWith('[')) {
        // Parse the JSON array string into a list
        List files = [];
        try {
          // Manually parse simple JSON array format
          files = List.from(
            filePath
              .substring(1, filePath.length - 1) // Remove [ and ]
              .split(',') // Split by comma
              .map((s) => s.trim().replaceAll('"', '')) // Clean up each entry
          );
        } catch (_) {}
        
        if (files.isNotEmpty) {
          // If multiple files, show a dialog to let user choose
          if (files.length > 1) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.cardDark,
                title: Text("Select File", style: TextStyle(color: AppTheme.textPrimary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min, // Only take needed space
                  // Create a ListTile for each file
                  children: files.map((f) => ListTile(
                    // Show PDF icon for PDFs, image icon for others
                    leading: Icon(
                      f.toString().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image, 
                      color: AppTheme.info,
                    ),
                    // Show just the filename (after last /)
                    title: Text(
                      f.toString().split('/').last, 
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx); // Close dialog
                      _launchUrl("${ApiService.baseUrl}/${f.toString()}"); // Open file
                    },
                  )).toList(),
                ),
              ),
            );
          } else {
            // Single file in array - open directly
            _launchUrl("${ApiService.baseUrl}/${files.first}");
          }
        }
      } else {
        // Simple file path string - open directly
        _launchUrl("${ApiService.baseUrl}/$filePath");
      }
    } catch (e) {
      // Fallback: try to open as simple path
      _launchUrl("${ApiService.baseUrl}/$filePath");
    }
  }

  /// Launches a URL in the device's external browser/app.
  /// Uses the url_launcher package.
  Future<void> _launchUrl(String urlString) async {
    // Parse string into Uri object
    final Uri url = Uri.parse(urlString);
    
    // launchUrl opens the URL; returns false if it can't
    // LaunchMode.externalApplication opens in browser, not in-app webview
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Show error snackbar if launch failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open file"), 
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ===========================================
  // PRESCRIPTIONS TAB
  // ===========================================

  /// Builds the Prescriptions tab content - list of all prescriptions.
  Widget _buildPrescriptionsTab() {
    List prescriptions = _data['prescriptions'] ?? [];
    
    if (prescriptions.isEmpty) {
      return _buildEmptyState("No prescriptions yet", Icons.medication);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          var p = prescriptions[index];
          
          // Format the visit date
          DateTime? visitDate = DateTime.tryParse(p['visit_date'] ?? '');
          String formattedDate = visitDate != null 
              ? DateFormat('MMM dd, yyyy').format(visitDate) 
              : '';
          
          // Build prescription card
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.nursePrimary.withAlpha(30)),
            ),
            child: Row(
              children: [
                // Medication icon
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.nursePrimary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.medication, color: AppTheme.nursePrimary, size: 22),
                ),
                SizedBox(width: 12),
                
                // Medication details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['medication_name'] ?? '', 
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${p['dosage'] ?? ''} • ${p['frequency'] ?? ''}", 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      Text(
                        "Duration: ${p['duration'] ?? 'N/A'}", 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                
                // Date and doctor on the right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    SizedBox(height: 4),
                    Text(
                      "Dr. ${p['doctor_name'] ?? ''}", 
                      style: TextStyle(color: AppTheme.patientPrimary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================
  // LAB RESULTS TAB
  // ===========================================

  /// Builds the Lab Results tab content - list of all lab results.
  Widget _buildLabResultsTab() {
    List labResults = _data['lab_results'] ?? [];
    
    if (labResults.isEmpty) {
      return _buildEmptyState("No lab results yet", Icons.science);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: labResults.length,
        itemBuilder: (context, index) {
          var lr = labResults[index];
          
          // Format test date
          DateTime? testDate = DateTime.tryParse(lr['test_date'] ?? '');
          String formattedDate = testDate != null 
              ? DateFormat('MMM dd, yyyy').format(testDate) 
              : '';
          
          // Check if there's a file attachment
          bool hasFile = lr['result_file_path'] != null && 
                         lr['result_file_path'].toString().isNotEmpty;
          
          // Build lab result card
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withAlpha(30)),
            ),
            child: Row(
              children: [
                // Science icon
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.science, color: AppTheme.warning, size: 22),
                ),
                SizedBox(width: 12),
                
                // Test details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lr['test_name'] ?? '', 
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      if (lr['result_summary'] != null && lr['result_summary'].toString().isNotEmpty)
                        Text(
                          lr['result_summary'], 
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        "By Dr. ${lr['doctor_name'] ?? 'Unknown'}", 
                        style: TextStyle(color: AppTheme.patientPrimary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                
                // Date and view button on the right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    
                    // View button (only if file exists)
                    if (hasFile) ...[
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openLabFile(lr['result_file_path']),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Only take needed width
                            children: [
                              Icon(Icons.visibility, color: AppTheme.info, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "View", 
                                style: TextStyle(
                                  color: AppTheme.info, 
                                  fontSize: 11, 
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================
  // HELPER WIDGETS
  // ===========================================

  /// Builds a small badge chip with colored background.
  /// Used for showing "2 Rx" or "1 Lab" counts on consultation cards.
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30), // Light background
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text, 
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Builds an empty state widget shown when there's no data.
  /// Displays an icon and message centered on screen.
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 48),
          SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
