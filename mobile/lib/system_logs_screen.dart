// ============================================
// SYSTEM_LOGS_SCREEN.DART - Admin Activity Audit Log
// ============================================
// This screen allows ADMINS to view all system activity logs.
// Essential for security auditing and tracking user actions.
// 
// WHAT GETS LOGGED (automatically by the backend):
// - Login attempts: success, failed, restricted accounts
// - Patient management: registration, updates, restrictions
// - Appointment actions: creation, updates, status changes (missed/completed)
// - Medical records: consultation creation with prescriptions/lab results
// - Re-access system: request submissions, admin approvals/rejections
//
// Features:
// - View chronological list of all system events
// - Filter by action type using horizontal scrollable chips
// - Color-coded icons for quick visual identification
// - See who performed each action (user name and role)
// - Pull-to-refresh for latest data
//
// NOTE: Only admins have access to this screen via AdminHome.
// Logs are stored in the 'system_logs' database table.

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Custom typography (Inter font)
import 'package:intl/intl.dart'; // Date formatting (e.g., "Jan 15, 14:30")
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// SystemLogsScreen - Admin screen to view all system activity logs.
/// Provides an audit trail for security, debugging, and tracking purposes.
/// 
/// This is a StatefulWidget because it needs to manage:
/// 1. List of log entries from API
/// 2. Loading state while fetching
/// 3. Current filter selection
/// 4. Fade-in animation on screen load
class SystemLogsScreen extends StatefulWidget {
  // No parameters needed - logs are not user-specific
  const SystemLogsScreen({super.key});

  @override
  _SystemLogsScreenState createState() => _SystemLogsScreenState();
}

/// State class - manages log data, filtering, and UI animations.
/// 'SingleTickerProviderStateMixin' provides a Ticker for our fade animation.
class _SystemLogsScreenState extends State<SystemLogsScreen> with SingleTickerProviderStateMixin {
  
  // ===========================================
  // STATE VARIABLES
  // ===========================================
  
  // List of log entries from the database
  // Each log contains: action_type, action_description, user_name, user_role, created_at
  List<dynamic> _logs = [];
  
  // Loading flag - shows spinner while fetching data
  bool _isLoading = true;
  
  // Currently selected filter type (null = show all)
  // Examples: 'login_success', 'appointment_created', 'patient_registered'
  String? _filterType;
  
  // List of available action types for filter chips
  // Fetched from API to dynamically show only types that exist in logs
  List<String> _actionTypes = [];
  
  // Total count of log entries (for display in header)
  int _total = 0;
  
  // --- ANIMATION ---
  late AnimationController _animController;
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
    _animController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this, // Connect to mixin's ticker for smooth animation
    );
    
    // Create tween animation from 0 (invisible) to 1 (fully visible)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    
    // Fetch logs and action types from API
    _loadData();
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

  /// Fetches logs from the API with optional filter.
  /// Also fetches available action types for the filter bar.
  Future<void> _loadData() async {
    // Show loading spinner
    setState(() => _isLoading = true);
    
    // --- FETCH LOGS ---
    // If _filterType is null, API returns all logs
    // If _filterType is set, API only returns logs of that type
    var result = await ApiService.getSystemLogs(filterType: _filterType);
    
    // --- FETCH ACTION TYPES ---
    // Get list of unique action types that exist in the database
    // This dynamically populates the filter chips
    var types = await ApiService.getLogActionTypes();
    
    // Update state with fetched data
    setState(() {
      _logs = result['logs'] ?? []; // List of log entries
      _total = result['total'] ?? 0; // Total count
      _actionTypes = List<String>.from(types); // Convert to List<String>
      _isLoading = false;
    });
    
    // Start fade-in animation
    _animController.forward();
  }

  // ===========================================
  // COLOR AND ICON HELPERS
  // ===========================================

  /// Returns a color based on the action type for visual distinction.
  /// Colors help users quickly identify the type of action:
  /// - Green = successful actions (login, approval)
  /// - Red = errors/failures (login failed, restricted, rejected)
  /// - Blue = appointments
  /// - Orange = warnings (missed appointments, pending requests)
  /// - Cyan = patient-related actions
  Color _getActionColor(String actionType) {
    // Switch on lowercase version for case-insensitive matching
    switch (actionType.toLowerCase()) {
      // --- LOGIN ACTIONS ---
      case 'login':
      case 'login_success':
        return AppTheme.success; // Green - successful login
      case 'login_failed':
      case 'login_restricted':
        return AppTheme.error; // Red - failed or blocked login
        
      // --- APPOINTMENT ACTIONS ---
      case 'appointment_created':
      case 'appointment_updated':
        return AppTheme.doctorPrimary; // Blue - appointment management
      case 'appointment_missed':
        return AppTheme.warning; // Orange - missed (needs attention)
        
      // --- MEDICAL RECORD ACTIONS ---
      case 'consultation_created':
        return AppTheme.info; // Light blue - consultation added
        
      // --- PATIENT MANAGEMENT ---
      case 'patient_registered':
      case 'patient_updated':
        return AppTheme.nursePrimary; // Cyan - patient records
      case 'patient_restricted':
        return AppTheme.error; // Red - restriction applied (serious)
        
      // --- RE-ACCESS REQUESTS ---
      case 'reaccess_approved':
        return AppTheme.success; // Green - approved
      case 'reaccess_rejected':
        return AppTheme.error; // Red - rejected
      case 'reaccess_submitted':
        return AppTheme.warning; // Orange - pending review
        
      // --- DEFAULT ---
      default:
        return AppTheme.adminPrimary; // Default admin green
    }
  }

  /// Returns an appropriate icon based on the action type.
  /// Icons help users quickly identify the category of action.
  IconData _getActionIcon(String actionType) {
    switch (actionType.toLowerCase()) {
      // --- LOGIN ACTIONS (all use login icon) ---
      case 'login':
      case 'login_success':
      case 'login_failed':
      case 'login_restricted':
        return Icons.login;
        
      // --- APPOINTMENT ACTIONS (all use calendar icon) ---
      case 'appointment_created':
      case 'appointment_updated':
      case 'appointment_missed':
        return Icons.calendar_today;
        
      // --- CONSULTATION (medical bag icon) ---
      case 'consultation_created':
        return Icons.medical_services;
        
      // --- PATIENT REGISTRATION/UPDATE (person add icon) ---
      case 'patient_registered':
      case 'patient_updated':
        return Icons.person_add;
        
      // --- PATIENT RESTRICTION (person with X icon) ---
      case 'patient_restricted':
        return Icons.person_off;
        
      // --- RE-ACCESS REQUESTS (lock open icon) ---
      case 'reaccess_approved':
      case 'reaccess_rejected':
      case 'reaccess_submitted':
        return Icons.lock_open;
        
      // --- DEFAULT (info icon) ---
      default:
        return Icons.info;
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
      // Set background color for edges visible during overscroll
      backgroundColor: AppTheme.adminGradient.first,
      
      // Allow content to extend behind app bar
      extendBodyBehindAppBar: true,
      
      // GradientBackground is our custom widget from app_theme.dart
      body: GradientBackground(
        colors: AppTheme.adminGradient, // Green gradient for admin screens
        
        // SafeArea prevents content from overlapping system UI
        child: SafeArea(
          // FadeTransition animates the opacity
          child: FadeTransition(
            opacity: _fadeAnimation,
            
            // Column for vertical layout: header, filters, logs
            child: Column(
              children: [
                // Header with back button, title, total count, refresh
                _buildHeader(),
                
                // Horizontal scrollable filter chips
                _buildFilterBar(),
                
                // Main content: loading/empty/list of logs
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
                      : _logs.isEmpty
                          ? _buildEmptyState()
                          // RefreshIndicator enables pull-to-refresh
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              // ListView.builder efficiently builds items on demand
                              child: ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) => _buildLogCard(_logs[index]),
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

  /// Builds the header with back button, title, total count, and refresh button.
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
                  "System Logs", 
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Show total count of log entries
                Text(
                  "$_total total entries", 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // --- REFRESH BUTTON ---
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: AppTheme.adminPrimary),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // FILTER BAR
  // ===========================================

  /// Builds the horizontal scrollable filter bar with action type chips.
  Widget _buildFilterBar() {
    return Container(
      height: 40, // Fixed height for the filter bar
      margin: EdgeInsets.symmetric(horizontal: 16),
      
      // ListView with horizontal scroll for filter chips
      child: ListView(
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        children: [
          // "All" chip (always first, clears filter)
          _buildFilterChip("All", null),
          
          SizedBox(width: 8),
          
          // Dynamically create chips for each action type
          // .map() transforms each type string into a Padding widget with chip
          // spread operator (...) unpacks the list into the ListView children
          ..._actionTypes.map((type) => Padding(
            padding: EdgeInsets.only(right: 8),
            child: _buildFilterChip(_formatActionType(type), type),
          )),
        ],
      ),
    );
  }

  /// Builds a single filter chip.
  /// Chips show the action type and highlight when selected.
  Widget _buildFilterChip(String label, String? type) {
    // Check if this chip is currently selected
    bool isSelected = _filterType == type;
    
    // Get the color for this action type (or default for "All")
    Color chipColor = type != null ? _getActionColor(type) : AppTheme.adminPrimary;
    
    // GestureDetector makes the chip tappable
    return GestureDetector(
      onTap: () {
        // Update filter selection and reload data
        setState(() => _filterType = type);
        _loadData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        
        // Chip styling - highlighted if selected
        decoration: BoxDecoration(
          // Background: colored if selected, glass white if not
          color: isSelected ? chipColor.withAlpha(40) : AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(20), // Pill shape
          // Border: colored if selected, glass border if not
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.glassBorder,
          ),
        ),
        
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Formats an action type string for display.
  /// Converts "login_success" to "Login Success" (title case with spaces).
  String _formatActionType(String type) {
    return type
        .replaceAll('_', ' ') // Replace underscores with spaces
        .split(' ') // Split into words
        .map((word) => 
          // Capitalize first letter of each word
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
        )
        .join(' '); // Join words back together
  }

  // ===========================================
  // LOG CARD
  // ===========================================

  /// Builds a single log entry card showing:
  /// - Action type icon (color-coded)
  /// - Action type badge
  /// - Timestamp
  /// - Action description
  /// - User who performed action (if available)
  Widget _buildLogCard(Map<String, dynamic> log) {
    // Extract data from log object
    String actionType = log['action_type'] ?? 'unknown';
    DateTime? createdAt = DateTime.tryParse(log['created_at'] ?? '');
    String formattedDate = createdAt != null 
        ? DateFormat('MMM dd, HH:mm').format(createdAt) // "Jan 15, 14:30"
        : '';
    
    // Get color and icon for this action type
    Color actionColor = _getActionColor(actionType);
    IconData actionIcon = _getActionIcon(actionType);

    return Container(
      margin: EdgeInsets.only(bottom: 10), // Space between cards
      padding: EdgeInsets.all(14),
      
      // Card styling with colored border matching action type
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: actionColor.withAlpha(30)),
      ),
      
      // Row layout: icon | content
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align at top
        children: [
          // --- ACTION ICON ---
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: actionColor.withAlpha(30), // Light colored background
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(actionIcon, color: actionColor, size: 20),
          ),
          
          SizedBox(width: 12),
          
          // --- LOG CONTENT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP ROW: Action type badge + timestamp ---
                Row(
                  children: [
                    // Action type badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: actionColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatActionType(actionType),
                        style: TextStyle(
                          color: actionColor, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    Spacer(), // Push timestamp to the right
                    
                    // Timestamp
                    Text(
                      formattedDate, 
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                
                SizedBox(height: 6),
                
                // --- ACTION DESCRIPTION ---
                Text(
                  log['action_description'] ?? '',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  maxLines: 2, // Limit to 2 lines
                  overflow: TextOverflow.ellipsis, // Show "..." if truncated
                ),
                
                // --- USER INFO (if available) ---
                // Spread operator with 'if' conditionally adds these widgets
                if (log['user_name'] != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.textMuted, size: 12),
                      SizedBox(width: 4),
                      // Show user name and role in parentheses
                      Text(
                        "${log['user_name']} (${log['user_role'] ?? 'unknown'})",
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // EMPTY STATE
  // ===========================================

  /// Builds the empty state shown when no logs are found.
  /// Shows a history icon and message.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // History icon
          Icon(Icons.history, color: AppTheme.textMuted, size: 48),
          
          SizedBox(height: 16),
          
          // Title
          Text(
            "No logs found", 
            style: TextStyle(
              color: AppTheme.textPrimary, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 8),
          
          // Subtitle - different message based on whether filter is active
          Text(
            _filterType != null 
                ? "No entries for this filter" 
                : "System activity will appear here", 
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
