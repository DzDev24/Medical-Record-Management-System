// ============================================
// PATIENT_APPOINTMENTS_SCREEN.DART - Patient's Appointments View
// ============================================
// This screen allows PATIENTS to view their appointment history.
// Accessed from the PatientHome screen via "Appointments" quick action button.
// 
// Features:
// - Tab navigation: Upcoming, Past, All appointments
// - Statistics summary card showing: upcoming, completed, missed counts
// - View appointment details including doctor, date, time, reason
// - Pull-to-refresh to reload latest appointment data
// - Color-coded status badges (blue=scheduled, green=completed, red=missed)
//
// NOTE: Patients can only VIEW appointments. They CANNOT schedule, 
// cancel, or modify appointments. Only doctors can manage appointments
// via the DoctorAppointmentsScreen.

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Custom typography (Inter font)
import 'package:intl/intl.dart'; // Date formatting (e.g., "Jan 01, 2024")
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// PatientAppointmentsScreen - View-only screen for patient appointment history.
/// This is a StatefulWidget because it needs to manage:
/// 1. Tab controller for switching between Upcoming/Past/All
/// 2. Loading state while fetching data
/// 3. Appointments list from API
class PatientAppointmentsScreen extends StatefulWidget {
  final int userId; // Patient's user ID - used to fetch their appointments from API
  final String patientName; // Displayed in header bar

  // Constructor with required parameters
  const PatientAppointmentsScreen({
    super.key, // Flutter 3 shorthand for key parameter
    required this.userId, // 'required' enforces this must be passed
    required this.patientName,
  });

  @override
  _PatientAppointmentsScreenState createState() => _PatientAppointmentsScreenState();
}

/// State class - manages tab navigation, data loading, filtering, and UI.
/// 'SingleTickerProviderStateMixin' provides a Ticker for TabController animations.
class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> with SingleTickerProviderStateMixin {
  
  // ===========================================
  // STATE VARIABLES
  // ===========================================
  
  // TabController manages which tab is selected and swipe animations
  // 'late' means it will be initialized in initState() before use
  late TabController _tabController;
  
  // Loading flag - when true, shows spinner instead of data
  bool _isLoading = true;
  
  // All appointments fetched from API (unfiltered)
  List<dynamic> _appointments = [];
  
  // Error message if API call fails
  String? _error;

  // ===========================================
  // LIFECYCLE METHODS
  // ===========================================

  /// initState() is called once when widget is first created.
  /// Used to initialize controllers and fetch data.
  @override
  void initState() {
    super.initState(); // Always call super first
    
    // Create TabController with 3 tabs (Upcoming, Past, All)
    // vsync: this connects to our mixin's ticker for smooth animations
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch appointments from API
    _loadData();
  }

  /// dispose() is called when widget is removed from tree.
  /// CRITICAL: Always dispose controllers to prevent memory leaks!
  @override
  void dispose() {
    _tabController.dispose(); // Free up resources
    super.dispose(); // Always call super last
  }

  // ===========================================
  // DATA LOADING
  // ===========================================

  /// Fetches all appointments for this patient from the API.
  /// This is async - uses 'await' to wait for the API response.
  Future<void> _loadData() async {
    // Set loading state to show spinner
    setState(() => _isLoading = true);
    
    try {
      // Call API with patient's user ID
      // widget.userId accesses the userId from the parent StatefulWidget
      var result = await ApiService.getPatientAppointments(widget.userId);
      
      // Update state with fetched data
      setState(() {
        _appointments = result; // Store the full list
        _isLoading = false; // Hide spinner
      });
    } catch (e) {
      // Handle any errors (network issues, server errors, etc.)
      setState(() {
        _isLoading = false;
        _error = e.toString(); // Convert exception to string for display
      });
    }
  }

  // ===========================================
  // FILTERING LOGIC
  // ===========================================

  /// Filters appointments based on the currently selected tab.
  /// 
  /// Parameters:
  ///   filter - String: 'upcoming', 'past', or 'all'
  /// 
  /// Returns:
  ///   Filtered list of appointments
  List<dynamic> _filterAppointments(String filter) {
    DateTime now = DateTime.now(); // Current date/time for comparison
    
    // Switch statement chooses behavior based on filter type
    switch (filter) {
      case 'upcoming':
        // Filter to only FUTURE SCHEDULED appointments
        // .where() is like a for loop with a condition
        return _appointments.where((a) {
          // Try to parse the appointment date string into DateTime
          DateTime? date = DateTime.tryParse(a['appointment_date'] ?? '');
          // Must be scheduled AND date must be in the future
          return a['status'] == 'scheduled' && date != null && date.isAfter(now);
        }).toList(); // Convert the iterable result back to a List
        
      case 'past':
        // Filter to appointments that are COMPLETED, MISSED, or CANCELLED
        return _appointments.where((a) {
          return a['status'] == 'completed' || 
                 a['status'] == 'missed' || 
                 a['status'] == 'cancelled';
        }).toList();
        
      case 'all':
      default:
        // Return all appointments unfiltered
        return _appointments;
    }
  }

  // ===========================================
  // BUILD METHOD - Main UI Construction
  // ===========================================

  /// build() is called whenever setState() is called.
  /// Returns the complete widget tree for this screen.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic page structure
    return Scaffold(
      // Allow content to extend behind app bar (for gradient effect)
      extendBodyBehindAppBar: true,
      
      // GradientBackground is our custom widget from app_theme.dart
      body: GradientBackground(
        colors: AppTheme.patientGradient, // Purple gradient for patient screens
        
        // SafeArea keeps content away from system UI (notch, status bar)
        child: SafeArea(
          // Column arranges children vertically: header, tabs, content
          child: Column(
            children: [
              // Header with back button, title, stats, and refresh
              _buildHeader(),
              
              // Tab bar for switching between Upcoming/Past/All
              _buildTabBar(),
              
              // Expanded fills remaining space with tab content
              Expanded(
                // Conditional rendering using ternary operators:
                // if loading? show spinner : if error? show error : show content
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: AppTheme.patientPrimary))
                    : _error != null
                        ? Center(child: Text(_error!, style: TextStyle(color: AppTheme.error)))
                        // TabBarView shows different content for each tab
                        : TabBarView(
                            controller: _tabController, // Link to our controller
                            // Children MUST match tab order in TabBar
                            children: [
                              // Each tab gets filtered appointments list
                              _buildAppointmentsList(_filterAppointments('upcoming')),
                              _buildAppointmentsList(_filterAppointments('past')),
                              _buildAppointmentsList(_filterAppointments('all')),
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
  // HEADER WIDGET (with stats)
  // ===========================================

  /// Builds the header section including:
  /// - Back button
  /// - Title and patient name
  /// - Refresh button
  /// - Statistics card showing upcoming/completed/missed counts
  Widget _buildHeader() {
    // Calculate counts for stats card
    int upcomingCount = _filterAppointments('upcoming').length;
    
    return Padding(
      padding: EdgeInsets.all(16), // 16px padding on all sides
      
      // Column for vertical layout (top row + stats card)
      child: Column(
        children: [
          // --- TOP ROW: Back button, title, refresh ---
          Row(
            children: [
              // Back button with glassmorphism styling
              GestureDetector(
                onTap: () => Navigator.pop(context), // Go back to previous screen
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite, // Semi-transparent white
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 22),
                ),
              ),
              
              SizedBox(width: 16), // Spacing between elements
              
              // Title and subtitle (Expanded to fill available space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
                  children: [
                    // Main title with Google Fonts styling
                    Text(
                      "My Appointments", 
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Patient name subtitle
                    Text(
                      widget.patientName, 
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              // Refresh button
              IconButton(
                onPressed: _loadData, // Reload data when pressed
                icon: Icon(Icons.refresh, color: AppTheme.patientPrimary),
              ),
            ],
          ),
          
          SizedBox(height: 16), // Space between row and stats card
          
          // --- STATISTICS CARD ---
          // GlassCard is our custom glassmorphism widget from app_theme.dart
          GlassCard(
            padding: EdgeInsets.all(16),
            // Row with three stat columns and dividers
            child: Row(
              // spaceAround distributes children with equal space around them
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Upcoming count (blue)
                _buildStat("Upcoming", upcomingCount.toString(), AppTheme.info),
                
                // Vertical divider
                _buildStatDivider(),
                
                // Completed count (green)
                // .where() filters and .length counts matching items
                _buildStat(
                  "Completed", 
                  _appointments.where((a) => a['status'] == 'completed').length.toString(), 
                  AppTheme.success,
                ),
                
                _buildStatDivider(),
                
                // Missed count (red)
                _buildStat(
                  "Missed", 
                  _appointments.where((a) => a['status'] == 'missed').length.toString(), 
                  AppTheme.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single statistic column (value + label).
  /// Used in the stats card for Upcoming, Completed, Missed.
  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        // Large colored number
        Text(
          value, 
          style: TextStyle(
            color: color, 
            fontSize: 24, 
            fontWeight: FontWeight.bold,
          ),
        ),
        // Small label below
        Text(
          label, 
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  /// Builds a vertical divider for the stats card.
  Widget _buildStatDivider() {
    return Container(
      width: 1, // 1 pixel wide vertical line
      height: 40,
      color: AppTheme.glassBorder, // Subtle gray color
    );
  }

  // ===========================================
  // TAB BAR WIDGET
  // ===========================================

  /// Builds the tab bar for switching between Upcoming/Past/All.
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16), // 16px left and right margin
      
      // Dark card background for the tab bar
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      
      // TabBar is Flutter's built-in tab navigation widget
      child: TabBar(
        controller: _tabController, // Links to our controller
        
        // Styling for selected and unselected tabs
        labelColor: AppTheme.patientPrimary, // Selected = purple
        unselectedLabelColor: AppTheme.textMuted, // Unselected = gray
        indicatorColor: AppTheme.patientPrimary, // Underline color
        indicatorSize: TabBarIndicatorSize.tab, // Indicator spans full tab width
        
        // Tab definitions
        tabs: [
          Tab(text: "Upcoming"),
          Tab(text: "Past"),
          Tab(text: "All"),
        ],
      ),
    );
  }

  // ===========================================
  // APPOINTMENTS LIST
  // ===========================================

  /// Builds the scrollable list of appointment cards.
  /// Takes a pre-filtered list as parameter.
  Widget _buildAppointmentsList(List<dynamic> appointments) {
    // If list is empty, show empty state
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            // Calendar icon indicating no appointments
            Icon(Icons.event_busy, color: AppTheme.textMuted, size: 48),
            SizedBox(height: 12),
            Text(
              "No appointments found", 
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    // RefreshIndicator enables pull-to-refresh gesture
    return RefreshIndicator(
      onRefresh: _loadData, // Function called when user pulls down
      
      // ListView.builder efficiently builds items on demand
      // Only renders visible items - important for performance
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: appointments.length, // Total number of items
        
        // itemBuilder creates each item as it scrolls into view
        // 'index' is the position in the list (0, 1, 2, ...)
        itemBuilder: (context, index) {
          var appt = appointments[index]; // Get appointment at this position
          return _buildAppointmentCard(appt); // Build card widget
        },
      ),
    );
  }

  // ===========================================
  // APPOINTMENT CARD
  // ===========================================

  /// Builds a single appointment card showing:
  /// - Status icon (color-coded)
  /// - Date and time
  /// - Doctor name
  /// - Reason for visit
  /// - Status badge
  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    // Extract status, default to 'scheduled' if null
    String status = appt['status'] ?? 'scheduled';
    
    // Parse date string into DateTime object
    DateTime? date = DateTime.tryParse(appt['appointment_date'] ?? '');
    
    // Format date and time for display
    String formattedDate = date != null 
        ? DateFormat('MMM dd, yyyy').format(date) // "Jan 15, 2024"
        : 'Unknown';
    String formattedTime = date != null 
        ? DateFormat('HH:mm').format(date) // "14:30"
        : '';
    
    // --- DETERMINE STATUS COLOR AND ICON ---
    // Different colors/icons help users quickly identify appointment status
    Color statusColor;
    IconData statusIcon;
    
    // Switch statement sets color and icon based on status
    switch (status) {
      case 'scheduled':
        statusColor = AppTheme.info; // Blue - pending/upcoming
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = AppTheme.success; // Green - done
        statusIcon = Icons.check_circle;
        break;
      case 'missed':
        statusColor = AppTheme.error; // Red - missed
        statusIcon = Icons.cancel;
        break;
      case 'cancelled':
        statusColor = AppTheme.textMuted; // Gray - cancelled
        statusIcon = Icons.block;
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.help;
    }

    // GestureDetector makes the entire card tappable
    return GestureDetector(
      // Show details bottom sheet when tapped
      onTap: () => _showAppointmentDetails(appt),
      
      child: Container(
        margin: EdgeInsets.only(bottom: 12), // Space below each card
        padding: EdgeInsets.all(16), // Inner padding
        
        // Card styling with dynamic border color based on status
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          // Border color matches status color (with low opacity)
          border: Border.all(color: statusColor.withAlpha(40)),
        ),
        
        // Row layout: icon | details | status badge
        child: Row(
          children: [
            // --- STATUS ICON ---
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30), // Light background matching status
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            
            SizedBox(width: 14), // Spacing
            
            // --- APPOINTMENT DETAILS ---
            // Expanded makes this section fill available horizontal space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
                children: [
                  // Date (bold)
                  Text(
                    formattedDate, 
                    style: TextStyle(
                      color: AppTheme.textPrimary, 
                      fontWeight: FontWeight.w600, 
                      fontSize: 15,
                    ),
                  ),
                  // Time
                  Text(
                    "at $formattedTime", 
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Doctor name (colored)
                  Text(
                    "Dr. ${appt['doctor_name'] ?? 'Unknown'}", 
                    style: TextStyle(color: AppTheme.patientPrimary, fontSize: 12),
                  ),
                  
                  // Reason for visit (only if present and not empty)
                  if (appt['reason_for_visit'] != null && 
                      appt['reason_for_visit'].toString().isNotEmpty)
                    Text(
                      appt['reason_for_visit'], 
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      maxLines: 1, // Limit to one line
                      overflow: TextOverflow.ellipsis, // Show "..." if too long
                    ),
                ],
              ),
            ),
            
            // --- STATUS BADGE ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              // Status text in uppercase (e.g., "SCHEDULED", "COMPLETED")
              child: Text(
                status.toUpperCase(), 
                style: TextStyle(
                  color: statusColor, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // APPOINTMENT DETAILS BOTTOM SHEET
  // ===========================================

  /// Shows a modal bottom sheet with full appointment details.
  /// Bottom sheets slide up from the bottom of the screen.
  void _showAppointmentDetails(Map<String, dynamic> appt) {
    // Parse and format date/time
    DateTime? date = DateTime.tryParse(appt['appointment_date'] ?? '');
    String formattedDate = date != null 
        ? DateFormat('EEEE, MMMM dd, yyyy').format(date) // "Monday, January 15, 2024"
        : 'Unknown';
    String formattedTime = date != null 
        ? DateFormat('HH:mm').format(date) 
        : '';
    String status = appt['status'] ?? 'scheduled';
    
    // Determine status color for header styling
    Color statusColor;
    switch (status) {
      case 'scheduled': statusColor = AppTheme.info; break;
      case 'completed': statusColor = AppTheme.success; break;
      case 'missed': statusColor = AppTheme.error; break;
      default: statusColor = AppTheme.textMuted;
    }

    // showModalBottomSheet displays a sheet that slides up from bottom
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // We style the container ourselves
      isScrollControlled: true, // Allows sheet to be larger than half screen
      
      // Builder function returns the sheet content
      builder: (ctx) => Container(
        // Sheet height = 50% of screen height
        height: MediaQuery.of(context).size.height * 0.5,
        
        // Styling: dark background with rounded top corners
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        
        child: Column(
          children: [
            // --- DRAG HANDLE (visual indicator sheet can be dragged) ---
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
              // SingleChildScrollView enables scrolling if content overflows
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER with icon, title, and status badge ---
                    Row(
                      children: [
                        // Calendar icon in colored circle
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.calendar_today, color: statusColor, size: 28),
                        ),
                        
                        SizedBox(width: 16),
                        
                        // Title and status badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Appointment Details", 
                                style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Status badge
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(), 
                                  style: TextStyle(
                                    color: statusColor, 
                                    fontSize: 11, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),

                    // --- DETAIL ROWS using helper method ---
                    _buildDetailRow(Icons.calendar_today, "Date", formattedDate),
                    _buildDetailRow(Icons.access_time, "Time", formattedTime),
                    _buildDetailRow(Icons.person, "Doctor", "Dr. ${appt['doctor_name'] ?? 'Unknown'}"),
                    
                    // Specialty (only if present)
                    if (appt['doctor_specialty'] != null)
                      _buildDetailRow(Icons.local_hospital, "Specialty", appt['doctor_specialty']),
                    
                    // Reason for visit (only if present and not empty)
                    if (appt['reason_for_visit'] != null && 
                        appt['reason_for_visit'].toString().isNotEmpty)
                      _buildDetailRow(Icons.description, "Reason", appt['reason_for_visit']),
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

  /// Builds a detail row with icon, label, and value.
  /// Used in the appointment details bottom sheet.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12), // Space below each row
      padding: EdgeInsets.all(14),
      
      // Glassmorphism-style card
      decoration: BoxDecoration(
        color: AppTheme.glassWhite, // Semi-transparent white
        borderRadius: BorderRadius.circular(12),
      ),
      
      child: Row(
        children: [
          // Icon on the left
          Icon(icon, color: AppTheme.patientPrimary, size: 20),
          SizedBox(width: 12),
          
          // Label and value stacked vertically
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small label text
                Text(
                  label, 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                // Larger value text
                Text(
                  value, 
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
