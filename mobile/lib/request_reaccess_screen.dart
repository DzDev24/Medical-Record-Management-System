// ============================================
// REQUEST_REACCESS_SCREEN.DART - Re-Access Request Form
// ============================================
// This screen allows RESTRICTED patients to request account reactivation.
// 
// CONTEXT: When a patient misses 3+ appointments, their account becomes
// restricted (is_restricted = 1 in database). They can no longer log in
// normally but are shown a dialog with the option to request re-access.
//
// Features:
// - Form to explain why appointments were missed
// - Optional contact phone number field
// - Submits request to admins for review
// - Success confirmation screen after submission
//
// USER FLOW:
// 1. Patient tries to login with restricted account
// 2. Login fails with "Account Restricted" dialog
// 3. Patient taps "Request Re-Access" button
// 4. This screen opens for them to fill out the form
// 5. Admin reviews request in ManageReaccessScreen
// 6. Admin approves/rejects, which updates patient's is_restricted status
// 7. If approved, patient can now login normally

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Custom typography (Inter font)
import 'app_theme.dart'; // Custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls

/// RequestReaccessScreen - Form for restricted patients to request re-access.
/// This screen appears when login fails due to account restriction (3+ missed appointments).
/// 
/// This is a StatefulWidget because it needs to manage:
/// 1. Form input (reason text, phone number)
/// 2. Loading state during submission
/// 3. Submission success state (shows confirmation screen)
/// 4. Fade-in animation on screen load
class RequestReaccessScreen extends StatefulWidget {
  final int patientId; // ID of the restricted patient (for API call)
  final String patientName; // Patient's name (shown in confirmation)

  // Constructor with required parameters
  const RequestReaccessScreen({
    super.key, // Flutter 3 shorthand for key parameter
    required this.patientId, // Must provide patient ID to submit request
    required this.patientName,
  });

  @override
  _RequestReaccessScreenState createState() => _RequestReaccessScreenState();
}

/// State class - manages form input, submission, and animations.
/// 'SingleTickerProviderStateMixin' provides a Ticker for our fade animation.
class _RequestReaccessScreenState extends State<RequestReaccessScreen> with SingleTickerProviderStateMixin {
  
  // ===========================================
  // STATE VARIABLES
  // ===========================================
  
  // --- FORM CONTROLLERS ---
  // TextEditingController manages the text in a TextField
  // Lets us read the text value and clear it when needed
  final TextEditingController _reasonCtrl = TextEditingController(); // Required: reason for missing appointments
  final TextEditingController _phoneCtrl = TextEditingController(); // Optional: contact phone number
  
  // --- UI STATE ---
  bool _isLoading = false; // True while submitting - shows spinner on button
  bool _isSubmitted = false; // True after successful submission - shows success view
  
  // --- ANIMATION ---
  // AnimationController controls the timing of the animation
  late AnimationController _animController;
  // Animation<double> defines the animated value - here it goes from 0.0 to 1.0
  late Animation<double> _fadeAnimation;

  // ===========================================
  // LIFECYCLE METHODS
  // ===========================================

  /// initState() is called once when widget is first created.
  /// Used to set up animations.
  @override
  void initState() {
    super.initState(); // Always call super first
    
    // Create animation controller
    // Duration: 600 milliseconds for a smooth fade-in effect
    // vsync: this connects to our mixin's ticker to sync with screen refresh
    _animController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Create a Tween animation for the fade effect
    // Tween<double> animates from 'begin' value to 'end' value
    // CurvedAnimation adds easing for more natural motion (easeOut = fast start, slow end)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    
    // Start the animation immediately
    _animController.forward();
  }

  /// dispose() is called when widget is removed from tree.
  /// CRITICAL: Always dispose controllers to prevent memory leaks!
  @override
  void dispose() {
    _reasonCtrl.dispose(); // Clean up text controller
    _phoneCtrl.dispose(); // Clean up text controller
    _animController.dispose(); // Clean up animation controller
    super.dispose(); // Always call super last
  }

  // ===========================================
  // FORM SUBMISSION
  // ===========================================

  /// Submits the re-access request to the API.
  /// Validates input, calls API, and handles response.
  Future<void> _submitRequest() async {
    // --- VALIDATION ---
    // Check that reason field is not empty (trim removes whitespace)
    if (_reasonCtrl.text.trim().isEmpty) {
      _showSnackBar("Please explain why you missed your appointments", false);
      return; // Stop execution if validation fails
    }

    // Show loading spinner on button
    setState(() => _isLoading = true);
    
    // --- API CALL ---
    // Submit the request to the backend
    var result = await ApiService.submitReaccessRequest(
      patientId: widget.patientId, // Patient's ID from widget parameters
      reason: _reasonCtrl.text.trim(), // Trimmed reason text
      // Only include phone if it's not empty (null means optional not provided)
      contactPhone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
    );

    // Hide loading spinner
    setState(() => _isLoading = false);

    // --- HANDLE RESPONSE ---
    if (result['success'] == true) {
      // Success! Switch to success confirmation view
      setState(() => _isSubmitted = true);
    } else {
      // Failed - show error message from API or default message
      _showSnackBar(result['message'] ?? 'Failed to submit request', false);
    }
  }

  /// Shows a snackbar notification at the bottom of the screen.
  /// Used for success and error feedback.
  void _showSnackBar(String message, bool success) {
    // ScaffoldMessenger manages snackbars for the entire scaffold
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Green background for success, red for error
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  // ===========================================
  // BUILD METHOD - Main UI Construction
  // ===========================================

  /// build() is called whenever setState() is called.
  /// Returns either the form view or success view based on _isSubmitted state.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color for edges (behind gradient)
      backgroundColor: AppTheme.patientGradient.first,
      
      // Allow content to extend behind app bar
      extendBodyBehindAppBar: true,
      
      // GradientBackground is our custom widget from app_theme.dart
      body: GradientBackground(
        colors: AppTheme.patientGradient, // Purple gradient for patient screens
        
        // SafeArea prevents content from overlapping system UI (notch, status bar)
        child: SafeArea(
          // LayoutBuilder provides constraints (screen dimensions) for responsive layout
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              // ConstrainedBox ensures content fills at least the full screen height
              // This prevents the form from floating in the middle on tall screens
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                
                // FadeTransition animates the opacity using our _fadeAnimation
                child: FadeTransition(
                  opacity: _fadeAnimation, // 0.0 = invisible, 1.0 = fully visible
                  
                  // Conditional rendering: show success view after submission, form view before
                  child: _isSubmitted ? _buildSuccessView() : _buildFormView(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================
  // FORM VIEW
  // ===========================================

  /// Builds the form view with:
  /// - Back button
  /// - Warning icon and title
  /// - Form card with reason and phone fields
  /// - Submit button
  Widget _buildFormView() {
    return Padding(
      padding: EdgeInsets.all(20), // 20px padding on all sides
      
      // Column for vertical layout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left-align children
        children: [
          // --- BACK BUTTON ---
          // GestureDetector makes any widget tappable
          GestureDetector(
            onTap: () => Navigator.pop(context), // Go back to login screen
            child: Container(
              padding: EdgeInsets.all(10),
              // Glassmorphism styling
              decoration: BoxDecoration(
                color: AppTheme.glassWhite, // Semi-transparent white
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            ),
          ),
          
          SizedBox(height: 24), // Spacing
          
          // --- WARNING ICON ---
          // Large lock icon in red circle to indicate account is locked
          Center(
            child: Container(
              padding: EdgeInsets.all(24),
              // BoxShape.circle creates a circular container
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30), // Light red background
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline, color: AppTheme.error, size: 48),
            ),
          ),
          
          SizedBox(height: 24),
          
          // --- TITLE ---
          Center(
            child: Text(
              "Account Restricted",
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(height: 8),
          
          // --- SUBTITLE explaining why account is restricted ---
          Center(
            child: Text(
              "Your account has been restricted due to multiple missed appointments.",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center, // Center-align multiline text
            ),
          ),
          
          SizedBox(height: 32),
          
          // --- FORM CARD ---
          // GlassCard is our custom glassmorphism widget from app_theme.dart
          GlassCard(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form title
                Text(
                  "Request Re-Access",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Form instructions
                Text(
                  "Please explain why you missed your appointments and we will review your request.",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                
                SizedBox(height: 20),
                
                // --- REASON FIELD ---
                // Field label with asterisk indicating required
                Text(
                  "Reason for missed appointments *", 
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                SizedBox(height: 8),
                
                // Container wraps the TextField for additional styling
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // TextFormField is an input widget for text entry
                  child: TextFormField(
                    controller: _reasonCtrl, // Link to our controller to read value later
                    maxLines: 4, // Allow 4 lines for multiline input
                    style: TextStyle(color: AppTheme.textPrimary), // Text color
                    
                    // InputDecoration styles the input field
                    decoration: InputDecoration(
                      // Placeholder text shown when empty
                      hintText: "e.g., I was hospitalized and could not notify the clinic...",
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      
                      // Border styles for different states
                      // border: default border
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.glassBorder),
                      ),
                      // enabledBorder: when field is enabled but not focused
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.glassBorder),
                      ),
                      // focusedBorder: when field is focused (user is typing)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.info, width: 2), // Blue border when focused
                      ),
                      contentPadding: EdgeInsets.all(14), // Inner padding
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // --- PHONE FIELD (OPTIONAL) ---
                Text(
                  "Contact phone (optional)", 
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                SizedBox(height: 8),
                
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone, // Show phone keyboard on mobile
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: "+213...",
                      hintStyle: TextStyle(color: AppTheme.textMuted),
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
                        borderSide: BorderSide(color: AppTheme.info, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      // prefixIcon appears inside the field on the left
                      prefixIcon: Icon(Icons.phone, color: AppTheme.textMuted, size: 20),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // --- SUBMIT BUTTON ---
                GestureDetector(
                  // Disable tap when loading (null onTap makes it unresponsive)
                  onTap: _isLoading ? null : _submitRequest,
                  child: Container(
                    width: double.infinity, // Full width button
                    padding: EdgeInsets.symmetric(vertical: 16),
                    
                    // Gradient background for the button
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.patientPrimary, AppTheme.patientSecondary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    
                    // Center the button content
                    child: Center(
                      // Show spinner when loading, otherwise show text
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              // Small white spinner
                              child: CircularProgressIndicator(
                                color: Colors.white, 
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Submit Request",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // SUCCESS VIEW
  // ===========================================

  /// Builds the success confirmation view shown after submission.
  /// Shows a checkmark icon and confirmation message.
  Widget _buildSuccessView() {
    // Center the success card on screen
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        
        // GlassCard for the success message container
        child: GlassCard(
          padding: EdgeInsets.all(32),
          
          child: Column(
            // mainAxisSize.min makes the column only take up needed space
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- SUCCESS ICON ---
              // Green checkmark in a circle
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(30), // Light green background
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: AppTheme.success, size: 48),
              ),
              
              SizedBox(height: 24),
              
              // --- SUCCESS TITLE ---
              Text(
                "Request Submitted!",
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 12),
              
              // --- SUCCESS MESSAGE ---
              Text(
                "Your request has been submitted successfully. An administrator will review it and you will be notified of the decision.",
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32),
              
              // --- BACK TO LOGIN BUTTON ---
              GestureDetector(
                onTap: () => Navigator.pop(context), // Go back to login screen
                child: Container(
                  width: double.infinity, // Full width
                  padding: EdgeInsets.symmetric(vertical: 14),
                  
                  // Dark card style (not gradient like submit button)
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  
                  child: Center(
                    child: Text(
                      "Back to Login",
                      style: TextStyle(
                        color: AppTheme.textPrimary, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
