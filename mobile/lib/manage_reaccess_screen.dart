// ============================================
// MANAGE_REACCESS_SCREEN.DART - Admin Re-Access Request Management
// ============================================
// This screen allows ADMINS to review and process re-access requests
// from restricted patients.
// 
// CONTEXT: When a patient misses 3+ appointments, their account becomes
// restricted (is_restricted = 1 in database). They can request re-access
// via RequestReaccessScreen. This admin screen lets administrators
// approve or reject those pending requests.
//
// Features:
// - View list of all pending re-access requests
// - See patient name, national ID, submission date, reason, contact info
// - See how many appointments the patient has missed
// - Approve request: removes restriction, patient can login again
// - Reject request: keeps restriction, patient cannot login
// - All actions are logged to system_logs table for auditing
//
// USER FLOW:
// 1. Restricted patient submits re-access request (RequestReaccessScreen)
// 2. Admin navigates here from AdminHome "Access Requests" button
// 3. Admin reviews the request details (reason, missed count, etc.)
// 4. Admin taps Approve or Reject button
// 5. Confirmation dialog appears with response message input
// 6. Admin confirms action
// 7. Database updates patient's is_restricted status (if approved)
// 8. Patient can now login again (if approved)

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Custom typography (Inter font)
import 'package:intl/intl.dart'; // Date formatting (e.g., "Jan 01, 2024 14:30")
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// ManageReaccessScreen - Admin screen to approve/reject patient re-access requests.
/// Only admins have access to this screen via the AdminHome menu.
/// 
/// This is a StatefulWidget because it needs to manage:
/// 1. List of pending requests from API
/// 2. Loading state while fetching
/// 3. Fade-in animation on screen load
class ManageReaccessScreen extends StatefulWidget {
  final int adminUserId; // ID of the logged-in admin (included in API logs)

  // Constructor - requires admin user ID for logging purposes
  const ManageReaccessScreen({super.key, required this.adminUserId});

  @override
  _ManageReaccessScreenState createState() => _ManageReaccessScreenState();
}

/// State class - manages request list, loading state, and actions.
/// 'SingleTickerProviderStateMixin' provides a Ticker for our fade animation.
class _ManageReaccessScreenState extends State<ManageReaccessScreen> with SingleTickerProviderStateMixin {
  
  // ===========================================
  // STATE VARIABLES
  // ===========================================
  
  // List of pending re-access requests from API
  // Each request is a Map containing: patient_name, national_id, reason, etc.
  List<dynamic> _requests = [];
  
  // Loading flag - shows spinner while fetching data
  bool _isLoading = true;
  
  // --- ANIMATION ---
  // AnimationController controls the timing of the fade animation
  late AnimationController _animController;
  // Animation<double> defines the animated value (0.0 to 1.0 for opacity)
  late Animation<double> _fadeAnimation;

  // ===========================================
  // LIFECYCLE METHODS
  // ===========================================

  /// initState() is called once when widget is first created.
  /// Sets up animations and fetches initial data.
  @override
  void initState() {
    super.initState(); // Always call super first
    
    // Create animation controller for fade-in effect
    // Duration: 500ms for a smooth entrance
    _animController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this, // Connect to our mixin's ticker
    );
    
    // Create tween animation from 0 (invisible) to 1 (fully visible)
    // CurvedAnimation adds easing for more natural motion
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    
    // Fetch pending requests from API
    _loadRequests();
  }

  /// dispose() is called when widget is removed from tree.
  /// CRITICAL: Always dispose controllers to prevent memory leaks!
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ===========================================
  // DATA LOADING
  // ===========================================

  /// Fetches all pending re-access requests from the API.
  /// Only returns requests with status = 'pending' (not yet processed).
  Future<void> _loadRequests() async {
    // Show loading spinner
    setState(() => _isLoading = true);
    
    // Call API to get pending requests
    var result = await ApiService.getPendingReaccessRequests();
    
    // Update state with fetched data
    setState(() {
      _requests = result; // List of pending request objects
      _isLoading = false; // Hide spinner
    });
    
    // Start the fade-in animation after data loads
    _animController.forward();
  }

  // ===========================================
  // UI FEEDBACK
  // ===========================================

  /// Shows a snackbar notification at the bottom of the screen.
  /// Used for success and error feedback after approve/reject actions.
  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Green for success, red for error
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  // ===========================================
  // REQUEST PROCESSING (APPROVE/REJECT)
  // ===========================================

  /// Processes a re-access request (approve or reject).
  /// Shows confirmation dialog, calls API, and refreshes the list.
  /// 
  /// Parameters:
  ///   requestId - ID of the request to process
  ///   approve - true to approve, false to reject
  Future<void> _processRequest(int requestId, bool approve) async {
    // Create text controller for the response message input
    TextEditingController responseCtrl = TextEditingController();
    
    // Pre-fill with a default message based on action type
    responseCtrl.text = approve 
        ? "Your request has been approved. You can now login and book appointments."
        : "Your request has been rejected. Please contact the clinic for more information.";

    // --- CONFIRMATION DIALOG ---
    // showDialog displays a modal dialog and returns a Future with the result
    bool? confirmed = await showDialog<bool>(
      context: context,
      // Builder returns the dialog widget
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // White background for better readability
        // RoundedRectangleBorder gives the dialog rounded corners
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        
        // Title with color based on action type (green for approve, red for reject)
        title: Text(
          approve ? "Approve Request" : "Reject Request",
          style: TextStyle(
            color: approve ? AppTheme.success : AppTheme.error, 
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Dialog content
        content: Column(
          mainAxisSize: MainAxisSize.min, // Only take needed space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation text
            Text(
              approve
                  ? "This will reactivate the patient's account and reset their missed appointments counter."
                  : "The patient's account will remain restricted.",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            
            SizedBox(height: 16),
            
            // Response message label
            Text(
              "Response message:", 
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            
            SizedBox(height: 8),
            
            // Response message input field
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9), // Light gray background
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFCBD5E1)),
              ),
              child: TextField(
                controller: responseCtrl,
                maxLines: 3, // Allow multiline input
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  border: InputBorder.none, // Remove default border
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
        
        // Dialog action buttons
        actions: [
          // --- CANCEL BUTTON (gray) ---
          GestureDetector(
            onTap: () => Navigator.pop(ctx, false), // Return false (not confirmed)
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0), // Light gray
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Cancel", 
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          SizedBox(width: 1), // Tiny spacing between buttons
          
          // --- APPROVE/REJECT BUTTON (green or red gradient) ---
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true), // Return true (confirmed)
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                // Gradient color based on action type
                gradient: LinearGradient(
                  colors: approve 
                      ? [AppTheme.success, Color(0xFF00C896)] // Green gradient
                      : [AppTheme.error, AppTheme.error.withOpacity(0.8)], // Red gradient
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                approve ? "Approve" : "Reject",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    // --- PROCESS IF CONFIRMED ---
    if (confirmed == true) {
      // Call API to process the request
      var result = await ApiService.processReaccessRequest(
        requestId: requestId,
        approve: approve,
        adminResponse: responseCtrl.text, // Message to show patient
        adminId: widget.adminUserId, // For logging who processed it
      );

      // Show feedback snackbar
      _showSnackBar(
        result['message'] ?? (approve ? 'Approved' : 'Rejected'), 
        result['success'] == true,
      );
      
      // Reload the list if successful (processed request will disappear)
      if (result['success'] == true) {
        _loadRequests();
      }
    }
  }

  // ===========================================
  // BUILD METHOD - Main UI Construction
  // ===========================================

  /// build() is called whenever setState() is called.
  /// Returns the complete widget tree for this screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Allow content to extend behind app bar
      extendBodyBehindAppBar: true,
      
      // GradientBackground is our custom widget from app_theme.dart
      body: GradientBackground(
        colors: AppTheme.adminGradient, // Green gradient for admin screens
        
        child: SafeArea(
          // FadeTransition animates the opacity using our _fadeAnimation
          child: FadeTransition(
            opacity: _fadeAnimation,
            
            // Column for vertical layout: header + content
            child: Column(
              children: [
                // Header with back button, title, and refresh
                _buildHeader(),
                
                // Main content area
                Expanded(
                  // Conditional rendering:
                  // 1. Loading? Show spinner
                  // 2. Empty list? Show empty state
                  // 3. Otherwise? Show request list
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
                      : _requests.isEmpty
                          ? _buildEmptyState()
                          // RefreshIndicator enables pull-to-refresh
                          : RefreshIndicator(
                              onRefresh: _loadRequests,
                              // ListView.builder efficiently builds items on demand
                              child: ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _requests.length,
                                // itemBuilder creates each card as it scrolls into view
                                itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================
  // HEADER WIDGET
  // ===========================================

  /// Builds the header with back button, title, pending count, and refresh button.
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      
      // Row for horizontal layout
      child: Row(
        children: [
          // --- BACK BUTTON ---
          GestureDetector(
            onTap: () => Navigator.pop(context), // Go back to AdminHome
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            ),
          ),
          
          SizedBox(width: 16),
          
          // --- TITLE AND COUNT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Re-Access Requests", 
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Show count of pending requests
                Text(
                  "${_requests.length} pending", 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // --- REFRESH BUTTON ---
          IconButton(
            onPressed: _loadRequests,
            icon: Icon(Icons.refresh, color: AppTheme.adminPrimary),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // EMPTY STATE
  // ===========================================

  /// Builds the empty state shown when there are no pending requests.
  /// Shows a success checkmark indicating all requests have been processed.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Green checkmark icon in circle
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(30), // Light green background
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: AppTheme.success, size: 48),
          ),
          
          SizedBox(height: 16),
          
          // Title
          Text(
            "No Pending Requests", 
            style: TextStyle(
              color: AppTheme.textPrimary, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 8),
          
          // Subtitle
          Text(
            "All re-access requests have been processed", 
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // REQUEST CARD
  // ===========================================

  /// Builds a single request card showing:
  /// - Patient info (name, national ID)
  /// - Missed appointment count
  /// - Reason for missing appointments
  /// - Contact info and submission date
  /// - Approve/Reject buttons
  Widget _buildRequestCard(Map<String, dynamic> request) {
    // Parse and format the submission date
    DateTime? createdAt = DateTime.tryParse(request['created_at'] ?? '');
    String formattedDate = createdAt != null 
        ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt) 
        : 'Unknown';
    
    // Get missed appointments count (safely parse as int)
    int missedCount = int.tryParse(
      request['consecutive_missed_appointments']?.toString() ?? '0'
    ) ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12), // Space between cards
      padding: EdgeInsets.all(16),
      
      // Card styling with warning-colored border (orange)
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withAlpha(40)),
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ROW: Icon, name, ID, missed badge ---
          Row(
            children: [
              // Warning icon (person with X)
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_off, color: AppTheme.warning, size: 24),
              ),
              
              SizedBox(width: 12),
              
              // Patient name and national ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['patient_name'] ?? 'Unknown', 
                      style: TextStyle(
                        color: AppTheme.textPrimary, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "ID: ${request['national_id'] ?? 'N/A'}", 
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Missed appointments count badge (red)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$missedCount missed", 
                  style: TextStyle(
                    color: AppTheme.error, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // --- REASON SECTION ---
          Container(
            width: double.infinity, // Full width
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  "Reason:", 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                SizedBox(height: 4),
                // Reason text from patient
                Text(
                  request['reason'] ?? '', 
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // --- CONTACT & DATE ROW ---
          Row(
            children: [
              // Phone icon and number
              Icon(Icons.phone, color: AppTheme.textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                request['contact_phone'] ?? request['patient_phone'] ?? 'No phone', 
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              
              Spacer(), // Push date to the right
              
              // Clock icon and submission date
              Icon(Icons.access_time, color: AppTheme.textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                formattedDate, 
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // --- ACTION BUTTONS ROW ---
          Row(
            children: [
              // --- REJECT BUTTON (red) ---
              Expanded(
                child: GestureDetector(
                  // Parse request_id to int and call process with approve=false
                  onTap: () => _processRequest(
                    int.parse(request['request_id'].toString()), 
                    false, // reject
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.error.withAlpha(50)),
                    ),
                    child: Center(
                      child: Text(
                        "Reject", 
                        style: TextStyle(
                          color: AppTheme.error, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // --- APPROVE BUTTON (green gradient) ---
              Expanded(
                child: GestureDetector(
                  // Parse request_id to int and call process with approve=true
                  onTap: () => _processRequest(
                    int.parse(request['request_id'].toString()), 
                    true, // approve
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      // Green gradient for approval action
                      gradient: LinearGradient(
                        colors: [AppTheme.success, Color(0xFF00C896)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Approve", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
