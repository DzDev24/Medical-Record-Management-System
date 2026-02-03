import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Used for formatting dates (e.g., "Jan 01, 2024")
import 'package:file_picker/file_picker.dart'; // Used to upload lab result PDF/Images
import 'app_theme.dart';
import 'api_service.dart';

/// ============================================================
/// DOCTOR APPOINTMENTS SCREEN
/// 
/// Purpose: 
/// 1. View all appointments (Today, Upcoming, History).
/// 2. Manage appointment status (Complete, Cancel, Missed).
/// 3. Create new consultations immediately after completing an appointment.
/// ============================================================

class DoctorAppointmentsScreen extends StatefulWidget {
  final int doctorUserId; // We need the logged-in doctor's ID to fetch THEIR appointments
  final String doctorName;

  const DoctorAppointmentsScreen({
    super.key,
    required this.doctorUserId,
    required this.doctorName,
  });

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  // Controller for tab navigation (if needed in future)
  late TabController _tabController;
  
  // RAW DATA: The complete list fetched from the API
  List<dynamic> appointments = [];
  List<dynamic> patients = [];
  
  // STATE VARIABLES
  bool isLoading = true; // Shows spinner while fetching data
  String _filterStatus = 'all'; // Controls which chips are selected (all, scheduled, completed...)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData(); // Trigger data fetch when screen opens
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================================================
  /// DATA FETCHING LOGIC
  /// ============================================================
  Future<void> _loadData() async {
    setState(() => isLoading = true); // Start loading
    
    // Fetch appointments and patients in parallel (conceptually)
    final appts = await ApiService.getAppointments(doctorUserId: widget.doctorUserId); // Fetch appointments
    final patientsList = await ApiService.getPatientsList(); // Fetch patients list
    
    // Update the UI with the fresh data
    setState(() {
      appointments = appts; // Update appointments list
      patients = patientsList; // Update patients list
      isLoading = false; // Stop loading
    });
  }

  /// ============================================================
  /// FILTERING LOGIC (Getters)
  /// These functions process the raw 'appointments' list based on criteria.
  /// ============================================================

  // Returns appointments based on the selected "Chip" (All, Scheduled, etc.)
  List<dynamic> get _filteredAppointments {
    if (_filterStatus == 'all') return appointments;
    return appointments.where((a) => a['status'] == _filterStatus).toList();
  }

  // Returns only appointments scheduled for the future
  List<dynamic> get _upcomingAppointments { // Future scheduled appointments
    final now = DateTime.now(); // Current date-time
    return appointments.where((a) { // Filter logic
      if (a['status'] != 'scheduled') return false; // Only scheduled appointments
      try {
        final date = DateTime.parse(a['appointment_date']); // Parse appointment date
        return date.isAfter(now); // Check if it's in the future
      } catch (e) {
        return false; // Invalid date format
      }
    }).toList(); 
  }

  // Returns only appointments scheduled exactly for Today
  List<dynamic> get _todayAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return appointments.where((a) {
      try {
        final date = DateTime.parse(a['appointment_date']);
        // Check if the Year, Month, and Day match exactly
        return DateTime(date.year, date.month, date.day).isAtSameMomentAs(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Helper to show success/error messages at the bottom of screen
  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  // Helper to choose color based on status text
  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled': return AppTheme.info;
      case 'completed': return AppTheme.success;
      case 'missed': return AppTheme.error;
      case 'cancelled': return AppTheme.textMuted;
      default: return AppTheme.textSecondary;
    }
  }

  // Helper to choose icon based on status text
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled': return Icons.schedule;
      case 'completed': return Icons.check_circle;
      case 'missed': return Icons.cancel;
      case 'cancelled': return Icons.block;
      default: return Icons.help;
    }
  }

  /// ============================================================
  /// UI BUILD METHOD
  /// ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Main scaffold
      backgroundColor: AppTheme.doctorGradient.first, // Background color
      body: GradientBackground(
        colors: AppTheme.doctorGradient, // Uses the Blue Doctor Theme
        child: SafeArea(
          child: Column(
            children: [
              // 1. APP BAR (Custom built row)
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 22),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Text(
                        "Appointments",
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Add Appointment Button (Gradient style)
                    GestureDetector(
                      onTap: () => _showAddAppointmentDialog(),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. DASHBOARD STATS (Horizontal Cards)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Uses _todayAppointments.length to show count
                    _buildStatCard("Today", _todayAppointments.length.toString(), Icons.today, AppTheme.doctorPrimary), // Today
                    SizedBox(width: 12),
                    _buildStatCard("Upcoming", _upcomingAppointments.length.toString(), Icons.upcoming, AppTheme.success), // Upcoming
                    SizedBox(width: 12),
                    _buildStatCard("Total", appointments.length.toString(), Icons.calendar_month, AppTheme.info), // Total
                  ],
                ),
              ),

              SizedBox(height: 16),

              // 3. FILTER CHIPS (Horizontal Scroll)
              Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('all', 'All'),
                    _buildFilterChip('scheduled', 'Scheduled'),
                    _buildFilterChip('completed', 'Completed'),
                    _buildFilterChip('missed', 'Missed'),
                    _buildFilterChip('cancelled', 'Cancelled'),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // 4. MAIN LIST VIEW
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: AppTheme.doctorPrimary))
                    : RefreshIndicator(
                        onRefresh: _loadData, // Pull down to refresh logic
                        child: _filteredAppointments.isEmpty
                            ? Center(
                                child: Column( // No appointments found
                                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                                  children: [
                                    Icon(Icons.event_busy, color: AppTheme.textMuted, size: 64),
                                    SizedBox(height: 16),
                                    Text("No appointments found", style: TextStyle(color: AppTheme.textMuted)),
                                  ],
                                ),
                              )
                            // ListView.builder is efficient for long lists
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  final appt = _filteredAppointments[index];
                                  return _buildAppointmentCard(appt);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to display the summary blocks (Today/Upcoming/Total)
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(30), // Low opacity background
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 6),
            Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // Widget for the selection pills (All, Scheduled...)
  Widget _buildFilterChip(String value, String label) {
    bool isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value), // Updates the filter
      child: Container(
        margin: EdgeInsets.only(right: 8), // Spacing between chips
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding inside chip
        decoration: BoxDecoration( // Chip styling
          color: isSelected ? AppTheme.doctorPrimary : AppTheme.glassWhite, // Background color based on selection
          borderRadius: BorderRadius.circular(20), // Rounded edges
          border: Border.all(color: isSelected ? AppTheme.doctorPrimary : AppTheme.glassBorder), // Border color
        ),
        child: Text( // Chip label
          label, // Display text
          style: TextStyle( // Text styling
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13, // Font size
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // The Card used inside the ListView
  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    String status = appt['status'] ?? 'scheduled'; // Default to 'scheduled' if null
    String dateStr = appt['appointment_date'] ?? ''; // ISO date string
    DateTime? date = DateTime.tryParse(dateStr); // Parse to DateTime
    String formattedDate = date != null ? DateFormat('MMM dd, yyyy - HH:mm').format(date) : dateStr; // Format for display
    bool isRestricted = appt['patient_account_status'] == 'restricted'; // Check if patient is restricted

    return GestureDetector(
      onTap: () => _showAppointmentDetails(appt), // Opens the Bottom Sheet
      child: Container( // Card styling
        margin: EdgeInsets.only(bottom: 12), // Spacing between cards
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColor(status).withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Icon
                Container( // Icon container
                  padding: EdgeInsets.all(10), // Padding around icon
                  decoration: BoxDecoration( // Container styling
                    color: _getStatusColor(status).withAlpha(30), // Light background based on status
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 24),
                ),
                SizedBox(width: 12), // Spacing between icon and text
                Expanded( // Patient name and date
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      // Patient Name & Restricted Tag
                      Row(
                        children: [
                          Text(
                            appt['patient_name'] ?? 'Unknown',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          if (isRestricted) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text("RESTRICTED", style: TextStyle(color: AppTheme.error, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                // Small Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Padding inside badge
                  decoration: BoxDecoration( // Badge styling
                    color: _getStatusColor(status).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text( // Status text
                    status.toUpperCase(),
                    style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // Reason for visit text
            if (appt['reason_for_visit'] != null && appt['reason_for_visit'].toString().isNotEmpty) ...[
              SizedBox(height: 12), // Spacing before reason
              Container( // Reason box
                padding: EdgeInsets.all(10), // Padding inside box
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, color: AppTheme.textMuted, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appt['reason_for_visit'],
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ============================================================
  /// BOTTOM SHEET DETAILS
  /// Shows full details and buttons to Complete/Edit/Delete
  /// ============================================================
  void _showAppointmentDetails(Map<String, dynamic> appt) {
    String status = appt['status'] ?? 'scheduled';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows sheet to take up more height
      builder: (ctx) => Container( // Main container for bottom sheet
        height: MediaQuery.of(context).size.height * 0.55, // 55% of screen height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container( // Small bar at top
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView( // Allows scrolling if content overflows
                padding: EdgeInsets.all(24), // Padding inside sheet
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appt['patient_name'] ?? 'Unknown',
                                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Details Section
                    _buildDetailRow(Icons.calendar_today, "Date & Time", _formatDateTime(appt['appointment_date'])),
                    _buildDetailRow(Icons.phone, "Patient Phone", appt['patient_phone'] ?? 'N/A'),
                    if (appt['reason_for_visit'] != null && appt['reason_for_visit'].toString().isNotEmpty)
                      _buildDetailRow(Icons.description, "Reason", appt['reason_for_visit']),

                    SizedBox(height: 24),

                    // ACTIONS: Only show these if appointment is 'Scheduled'
                    if (status == 'scheduled') ...[
                      Text("Update Status", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusButton("Completed", AppTheme.success, () => _updateStatus(appt, 'completed', ctx)),
                          SizedBox(width: 10),
                          _buildStatusButton("Missed", AppTheme.error, () => _updateStatus(appt, 'missed', ctx)),
                          SizedBox(width: 10),
                          _buildStatusButton("Cancel", AppTheme.textMuted, () => _updateStatus(appt, 'cancelled', ctx)),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],

                    // Edit / Delete Buttons
                    Row(
                      children: [
                        if (status == 'scheduled') // Only show Edit if scheduled
                          Expanded( // Edit Button
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _showEditAppointmentDialog(appt); // Opens edit dialog
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center contents
                                  children: [
                                    Icon(Icons.edit, color: AppTheme.info, size: 18),
                                    SizedBox(width: 8),
                                    Text("Edit", style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (status == 'scheduled') SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _deleteAppointment(appt, ctx),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14), // Delete Button
                              decoration: BoxDecoration( // Delete button styling
                                color: AppTheme.error.withAlpha(30), // Light red background
                                borderRadius: BorderRadius.circular(12), // Rounded corners
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center, // Center contents
                                children: [ // Delete icon and text
                                  Icon(Icons.delete, color: AppTheme.error, size: 18),
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

  // Helper row for details in the bottom sheet
  Widget _buildDetailRow(IconData icon, String label, String value) { // Detail row with icon, label, and value
    return Padding( // Padding around the row
      padding: EdgeInsets.only(bottom: 12), // Spacing between rows
      child: Row( // Main row
        crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
        children: [ // Icon and text
          Icon(icon, color: AppTheme.textMuted, size: 20), // Icon
          SizedBox(width: 12),
          Column( // Text column
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
            children: [ // Label and value
              Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              SizedBox(height: 2),
              Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, Color color, VoidCallback onTap) { // Button to update status
    return Expanded( // Takes equal space
      child: GestureDetector( // Tappable button
        onTap: onTap, // Calls the provided function
        child: Container( // Button styling
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10), // Rounded corners
            border: Border.all(color: color.withAlpha(50)), // Border color
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateStr) { // Formats ISO date string to readable format
    if (dateStr == null) return 'N/A'; // Handle null case
    try {
      final date = DateTime.parse(dateStr); // Parse to DateTime
      return DateFormat('EEEE, MMM dd, yyyy - HH:mm').format(date); // Format for display
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  /// ============================================================
  /// WORKFLOW LOGIC: Update Status -> Create Consultation
  /// This is the most complex logic flow in the screen.
  /// 1. Update status to 'completed'.
  /// 2. If successful, ask "Add Consultation?".
  /// 3. If yes, open the detailed consultation dialog.
  /// ============================================================
  Future<void> _updateStatus(Map<String, dynamic> appt, String newStatus, BuildContext modalContext) async {
    Navigator.pop(modalContext); // Close the details sheet
    
    // Call API to update status
    var res = await ApiService.updateAppointmentStatus(
      appointmentId: int.parse(appt['appointment_id'].toString()),
      status: newStatus,
    );
    _showSnackBar(res['message'] ?? 'Status updated', res['success'] == true);
    _loadData(); // Refresh list

    // TRIGGER LOGIC: If status is 'completed', prompt to start consultation
    if (newStatus == 'completed' && res['success'] == true) {
      bool? shouldCreateConsultation = await showDialog<bool>(
        context: context, // Confirmation dialog context
        builder: (ctx) => AlertDialog( // Confirmation dialog
          backgroundColor: Colors.white, // Dialog background color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners
          title: Row( // Title with icon
            children: [
              Icon(Icons.medical_services, color: AppTheme.success, size: 28), // Medical icon
              SizedBox(width: 12), // Spacing between icon and text
              Text("Add Consultation?", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text( // Dialog content
            "Would you like to create a consultation record for this appointment with ${appt['patient_name']}?", // Content text
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [ // Action buttons
            GestureDetector( // "Later" button
              onTap: () => Navigator.pop(ctx, false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Later", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(width: 1), // Spacing between buttons
            GestureDetector( // "Add Consultation" button
              onTap: () => Navigator.pop(ctx, true), // Returns true
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Add Consultation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

      if (shouldCreateConsultation == true) {
        _showAddConsultationDialog(appt);
      }
    }
  }

  /// ============================================================
  /// CONSULTATION FORM (Complex Dialog)
  /// Features:
  /// 1. Diagnosis/Symptoms inputs
  /// 2. Prescriptions List (Dynamic Add/Remove)
  /// 3. Lab Results List (Dynamic Add/Remove + File Upload)
  /// ============================================================
  void _showAddConsultationDialog(Map<String, dynamic> appt) { // Consultation dialog
    // Controllers for text inputs
    TextEditingController diagnosisCtrl = TextEditingController();
    TextEditingController symptomsCtrl = TextEditingController();
    TextEditingController notesCtrl = TextEditingController();
    
    // Local lists to hold added items before saving
    List<Map<String, String>> prescriptions = [];
    List<Map<String, dynamic>> labResults = [];

    showDialog( // Main consultation dialog
      context: context,
      builder: (ctx) => StatefulBuilder( // Allows dialog to rebuild
        // NOTE: StatefulBuilder is REQUIRED here so the Dialog can rebuild 
        // when we add a prescription or lab result (updating the UI inside the popup).
        builder: (context, setDialogState) => AlertDialog( // AlertDialog for consultation
          backgroundColor: Colors.white, // Dialog background color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row( // Title with icon
            children: [ // Title row
              Container( // Icon container
                padding: EdgeInsets.all(10), // Padding around icon
                decoration: BoxDecoration( // Container styling
                  color: AppTheme.doctorPrimary.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle, color: AppTheme.doctorPrimary), // Add consultation icon
              ),
              SizedBox(width: 12), // Spacing between icon and text
              Column( // Title text column
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                children: [ // Title texts
                  Text("New Consultation", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Patient: ${appt['patient_name']}", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ],
          ),
          content: SingleChildScrollView( // Allows scrolling if content overflows
            child: Column( // Main content column
              mainAxisSize: MainAxisSize.min, // Takes minimum space
              crossAxisAlignment: CrossAxisAlignment.start, // Align items to start
              children: [ // Consultation form fields
                _buildDialogTextField(diagnosisCtrl, "Diagnosis", Icons.local_hospital),
                SizedBox(height: 12),
                _buildDialogTextField(symptomsCtrl, "Symptoms", Icons.sick),
                SizedBox(height: 12),
                _buildDialogTextField(notesCtrl, "Doctor Notes", Icons.note, maxLines: 3),
                
                SizedBox(height: 20), // Spacing before dynamic sections
                
                // --- PRESCRIPTIONS SECTION ---
                Row( // Header row for prescriptions
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Prescriptions", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: AppTheme.doctorPrimary),
                      // Opens a sub-dialog to add a medicine
                      onPressed: () => _showAddPrescriptionDialog((presc) => setDialogState(() => prescriptions.add(presc))),
                    ),
                  ],
                ),
                // Render list of added prescriptions
                if (prescriptions.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ...prescriptions.asMap().entries.map((entry) => Container(
                    margin: EdgeInsets.only(bottom: 6),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.medication, color: AppTheme.doctorPrimary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text("${entry.value['medication_name']} - ${entry.value['dosage']}", 
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                        ),
                        GestureDetector(
                          onTap: () => setDialogState(() => prescriptions.removeAt(entry.key)),
                          child: Icon(Icons.close, color: AppTheme.error, size: 16),
                        ),
                      ],
                    ),
                  )),
                ],
                
                SizedBox(height: 16),
                
                // --- LAB RESULTS SECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [ // Header row for lab results
                    Text("Lab Results", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: AppTheme.info),
                      // Opens sub-dialog to add lab test + file
                      onPressed: () => _showAddLabResultDialog((lab) => setDialogState(() => labResults.add(lab))),
                    ),
                  ],
                ),
                if (labResults.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ...labResults.asMap().entries.map((entry) { // Render each lab result
                    List<PlatformFile> files = entry.value['files'] ?? [];
                    return Container(
                      margin: EdgeInsets.only(bottom: 6),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.science, color: AppTheme.info, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value['test_name'] ?? '', 
                                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                                if (files.isNotEmpty)
                                  Text("${files.length} file(s) attached", 
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setDialogState(() => labResults.removeAt(entry.key)),
                            child: Icon(Icons.close, color: AppTheme.error, size: 16),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            // Cancel
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
            // CREATE BUTTON (Handles Uploads + API Save)
            GestureDetector(
              onTap: () async {
                if (diagnosisCtrl.text.isEmpty || symptomsCtrl.text.isEmpty) {
                  _showSnackBar("Please fill diagnosis and symptoms", false);
                  return;
                }
                Navigator.pop(ctx); // Close dialog

                // 1. Upload files first (if any)
                List<Map<String, String>> processedLabResults = []; // To hold final lab results with uploaded file paths
                for (var lab in labResults) { // Process each lab result
                  List<PlatformFile> files = lab['files'] ?? []; // Files to upload
                  List<String> uploadedPaths = []; // To hold uploaded file paths
                  
                  for (var file in files) { // Upload each file
                    if (file.path != null) { // Ensure file path is valid
                      var uploadRes = await ApiService.uploadLabFile(file.path!);
                      if (uploadRes['success'] == true && uploadRes['file_path'] != null) {
                        uploadedPaths.add(uploadRes['file_path']);
                      }
                    }
                  }
                  
                  processedLabResults.add({
                    'test_name': lab['test_name'] ?? '',
                    'result_summary': lab['result_summary'] ?? '',
                    'result_file_path': uploadedPaths.isNotEmpty ? uploadedPaths.join(',') : '',
                  });
                }

                // 2. Save everything to backend
                var res = await ApiService.addConsultation(
                  patientId: int.parse(appt['patient_id'].toString()),
                  doctorId: widget.doctorUserId,
                  diagnosis: diagnosisCtrl.text,
                  symptoms: symptomsCtrl.text,
                  doctorNotes: notesCtrl.text,
                  appointmentId: int.parse(appt['appointment_id'].toString()),
                  prescriptions: prescriptions,
                  labResults: processedLabResults,
                );

                _showSnackBar(res['message'] ?? 'Consultation created', res['success'] == true);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // SUB-DIALOGS FOR CONSULTATION FORM
  // ===========================================

  /// Dialog to add a single prescription (medication, dosage, frequency, duration).
  /// Uses a callback function to pass data back to the parent dialog.
  /// 
  /// Parameters:
  ///   onAdd - Function called with the prescription data when "Add" is tapped
  void _showAddPrescriptionDialog(Function(Map<String, String>) onAdd) {
    // Create text controllers for each input field
    TextEditingController medCtrl = TextEditingController(); // Medication name
    TextEditingController dosageCtrl = TextEditingController(); // Dosage (e.g., "500mg")
    TextEditingController freqCtrl = TextEditingController(); // Frequency (e.g., "3 times a day")
    TextEditingController durationCtrl = TextEditingController(); // Duration (e.g., "7 days")

    // Show the dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // White background for visibility
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        
        // Dialog title
        title: Text(
          "Add Prescription", 
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        
        // Dialog content with form fields
        content: Column(
          mainAxisSize: MainAxisSize.min, // Only take needed space
          children: [
            // Reusable text field with icon and hint
            _buildDialogTextField(medCtrl, "Medication", Icons.medication, hintText: "e.g., Paracetamol"),
            SizedBox(height: 10),
            _buildDialogTextField(dosageCtrl, "Dosage", Icons.scale, hintText: "e.g., 500mg"),
            SizedBox(height: 10),
            _buildDialogTextField(freqCtrl, "Frequency", Icons.repeat, hintText: "e.g., 3 times a day"),
            SizedBox(height: 10),
            _buildDialogTextField(durationCtrl, "Duration", Icons.timer, hintText: "e.g., 7 days"),
          ],
        ),
        
        // Action buttons
        actions: [
          // Cancel button (gray)
          GestureDetector(
            onTap: () => Navigator.pop(ctx), // Close dialog without saving
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
          
          // Add button (blue gradient)
          GestureDetector(
            onTap: () {
              // Only add if medication name is provided
              if (medCtrl.text.isNotEmpty) {
                Navigator.pop(ctx); // Close dialog
                // Call the callback with prescription data as a Map
                onAdd({
                  'medication_name': medCtrl.text,
                  'dosage': dosageCtrl.text,
                  'frequency': freqCtrl.text,
                  'duration': durationCtrl.text,
                });
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

  /// Dialog to add a lab result with optional file attachments.
  /// Uses FilePicker to allow users to select PDF or image files.
  /// 
  /// Parameters:
  ///   onAdd - Function called with lab result data when "Add" is tapped
  void _showAddLabResultDialog(Function(Map<String, dynamic>) onAdd) {
    // Controllers for text inputs
    TextEditingController testCtrl = TextEditingController(); // Test name
    TextEditingController resultCtrl = TextEditingController(); // Result summary
    
    // List to hold selected files (PlatformFile is from file_picker package)
    List<PlatformFile> selectedFiles = [];

    // showDialog with StatefulBuilder allows updating the dialog's UI
    // (e.g., when files are selected, we need to refresh the file list)
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder provides setDialogState to update the dialog's internal state
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          
          title: Text(
            "Add Lab Result", 
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          // ScrollView in case content is long
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Test name input
                _buildDialogTextField(testCtrl, "Test Name", Icons.science, hintText: "e.g., Blood Test"),
                SizedBox(height: 10),
                
                // Result summary input (multiline)
                _buildDialogTextField(resultCtrl, "Result Summary", Icons.description, maxLines: 2, hintText: "e.g., Normal range"),
                SizedBox(height: 16),
                
                // --- FILE PICKER SECTION ---
                Text("Attach Files", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                
                // File picker button
                GestureDetector(
                  onTap: () async {
                    // FilePicker.platform.pickFiles opens the system file picker
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      allowMultiple: true, // Allow selecting multiple files
                      type: FileType.custom, // Only allow specific extensions
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'], // Allowed formats
                    );
                    
                    // If user selected files (didn't cancel)
                    if (result != null) {
                      // Update the dialog state to show selected files
                      setDialogState(() {
                        selectedFiles.addAll(result.files); // Add to our list
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withAlpha(30), // Light blue background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.info.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_file, color: AppTheme.info, size: 20),
                        SizedBox(width: 8),
                        Text("Select Files", style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                
                // --- SELECTED FILES LIST ---
                // Show list of selected files with remove option
                if (selectedFiles.isNotEmpty) ...[
                  SizedBox(height: 12),
                  // Map through selected files with index
                  ...selectedFiles.asMap().entries.map((entry) => Container(
                    margin: EdgeInsets.only(bottom: 6),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Icon based on file type (PDF = red, images = blue)
                        Icon(
                          entry.value.extension == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                          color: entry.value.extension == 'pdf' ? AppTheme.error : AppTheme.info,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        // File name (truncated if too long)
                        Expanded(
                          child: Text(
                            entry.value.name,
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Remove button
                        GestureDetector(
                          onTap: () => setDialogState(() => selectedFiles.removeAt(entry.key)),
                          child: Icon(Icons.close, color: AppTheme.error, size: 16),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          
          // Action buttons
          actions: [
            // Cancel button
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
            
            // Add button
            GestureDetector(
              onTap: () {
                if (testCtrl.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  // Pass back lab result data with files
                  onAdd({
                    'test_name': testCtrl.text,
                    'result_summary': resultCtrl.text,
                    'files': selectedFiles, // Files will be uploaded later
                  });
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

  /// Builds a reusable styled TextField for dialog forms.
  /// Provides consistent styling across all consultation form fields.
  /// 
  /// Parameters:
  ///   ctrl - TextEditingController to manage the input
  ///   label - Label text shown above the input
  ///   icon - Icon displayed as prefix
  ///   maxLines - Number of lines (default 1, use more for multiline)
  ///   hintText - Placeholder text shown when empty
  Widget _buildDialogTextField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, String? hintText}) {
    return TextField(
      controller: ctrl, // Controller to read/write text
      maxLines: maxLines, // Single or multiline
      style: TextStyle(color: AppTheme.textPrimary),
      
      // Input decoration defines the appearance
      decoration: InputDecoration(
        labelText: label, // Floating label
        labelStyle: TextStyle(color: AppTheme.textMuted),
        hintText: hintText, // Placeholder
        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20), // Icon on left
        filled: true, // Enable fill color
        fillColor: Color(0xFFF1F5F9), // Light gray background
        
        // Border styling for different states
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: AppTheme.info, width: 2), // Blue when focused
        ),
      ),
    );
  }

  // ===========================================
  // DELETE APPOINTMENT
  // ===========================================

  /// Shows a confirmation dialog before deleting an appointment.
  /// If confirmed, calls the API to delete and refreshes the list.
  Future<void> _deleteAppointment(Map<String, dynamic> appt, BuildContext modalContext) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        
        // Warning title
        title: Text(
          "Delete Appointment?", 
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        
        // Warning message
        content: Text(
          "This action cannot be undone.", 
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        
        // Action buttons
        actions: [
          // Cancel button - returns false
          GestureDetector(
            onTap: () => Navigator.pop(ctx, false),
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
          
          // Delete button - returns true
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    // If user confirmed deletion
    if (confirm == true) {
      Navigator.pop(modalContext); // Close the details bottom sheet
      
      // Call API to delete
      var res = await ApiService.deleteAppointment(int.parse(appt['appointment_id'].toString()));
      
      // Show feedback
      _showSnackBar(res['message'] ?? 'Deleted', res['success'] == true);
      
      // Refresh the appointment list
      _loadData();
    }
  }

  // Dialog to Create NEW Appointment
  void _showAddAppointmentDialog() {
    int? selectedPatientId;
    DateTime selectedDate = DateTime.now().add(Duration(days: 1)); // Default to tomorrow
    TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0); // Default 9 AM
    TextEditingController reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("New Appointment", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Dropdown (Filters out restricted patients if needed)
                Text("Select Patient", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButton<int>(
                    value: selectedPatientId,
                    hint: Text("Choose patient", style: TextStyle(color: AppTheme.textMuted)),
                    dropdownColor: Colors.white,
                    underline: SizedBox(),
                    isExpanded: true,
                    items: patients.map<DropdownMenuItem<int>>((p) {
                      bool isRestricted = p['account_status'] == 'restricted';
                      return DropdownMenuItem<int>(
                        value: p['patient_id'],
                        enabled: !isRestricted, // Disable selection if restricted
                        child: Row(
                          children: [
                            Text(
                              p['full_name'],
                              style: TextStyle(color: isRestricted ? AppTheme.textMuted : AppTheme.textPrimary),
                            ),
                            if (isRestricted) ...[
                              SizedBox(width: 8),
                              Text("(Restricted)", style: TextStyle(color: AppTheme.error, fontSize: 11)),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedPatientId = val),
                  ),
                ),

                SizedBox(height: 16),

                // Date Picker Logic
                Text("Date", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                        SizedBox(width: 10),
                        Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDate), style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Time Picker Logic
                Text("Time", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: AppTheme.textMuted, size: 18),
                        SizedBox(width: 10),
                        Text(selectedTime.format(context), style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Reason for Visit Input
                Text("Reason for Visit", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Optional description...",
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.glassWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.doctorPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
            GestureDetector(
              onTap: () async {
                if (selectedPatientId == null) {
                  _showSnackBar("Please select a patient", false);
                  return;
                }

                Navigator.pop(ctx);

                // Combine separate Date and Time into one ISO String for the database
                final appointmentDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                var res = await ApiService.addAppointment(
                  patientId: selectedPatientId!,
                  doctorUserId: widget.doctorUserId,
                  appointmentDate: appointmentDateTime.toIso8601String(),
                  reasonForVisit: reasonCtrl.text,
                );

                _showSnackBar(res['message'] ?? 'Created', res['success'] == true);
                _loadData(); // Refresh list
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Edit EXISTING Appointment
  void _showEditAppointmentDialog(Map<String, dynamic> appt) {
    DateTime selectedDate = DateTime.tryParse(appt['appointment_date'] ?? '') ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);
    TextEditingController reasonCtrl = TextEditingController(text: appt['reason_for_visit'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Edit Appointment", style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient (Read-only for editing)
                Text("Patient", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.textMuted, size: 18),
                      SizedBox(width: 10),
                      Text(appt['patient_name'] ?? 'Unknown', style: TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Date Picker (Editable)
                Text("Date", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute));
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                        SizedBox(width: 10),
                        Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDate), style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Time Picker (Editable)
                Text("Time", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: AppTheme.textMuted, size: 18),
                        SizedBox(width: 10),
                        Text(selectedTime.format(context), style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Reason (Editable)
                Text("Reason for Visit", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Optional description...",
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.glassWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.doctorPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);

                final appointmentDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                var res = await ApiService.updateAppointment(
                  appointmentId: int.parse(appt['appointment_id'].toString()),
                  appointmentDate: appointmentDateTime.toIso8601String(),
                  reasonForVisit: reasonCtrl.text,
                );

                _showSnackBar(res['message'] ?? 'Updated', res['success'] == true);
                _loadData();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}