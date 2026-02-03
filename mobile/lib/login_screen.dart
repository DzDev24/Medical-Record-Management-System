// ============================================
// LOGIN_SCREEN.DART - User Authentication
// ============================================
// This screen handles login for both PATIENTS and STAFF (admin/doctor/nurse).
// It features a toggle switch to switch between login modes and animated transitions.

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Custom typography (Inter font)
import 'app_theme.dart'; // Our custom theme - colors, glassmorphism widgets
import 'api_service.dart'; // Backend API calls for authentication
import 'home_screens.dart'; // Redirects to role-specific home screen after login
import 'request_reaccess_screen.dart'; // Screen for restricted patients to request account reactivation

/// LoginScreen - The first screen users see when opening the app.
/// Supports two authentication modes:
/// 1. PATIENT LOGIN: Uses Full Name + National ID + Password
/// 2. STAFF LOGIN: Uses Username + Password (for admin, doctor, nurse)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Constructor - const for performance

  @override
  _LoginScreenState createState() => _LoginScreenState(); // Creates the mutable state
}

/// The State class for LoginScreen.
/// TickerProviderStateMixin enables multiple animation controllers.
class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // ==========================================
  // STATE VARIABLES
  // ==========================================
  
  /// Tracks which login mode is active. true = Patient, false = Staff
  bool _isPatientLogin = true;
  
  /// Shows loading spinner on login button when API call is in progress
  bool _isLoading = false;
  
  /// Controls password visibility. true = hidden (dots), false = visible
  bool _obscurePassword = true;

  // ==========================================
  // TEXT CONTROLLERS
  // ==========================================
  // Controllers manage the text in input fields and allow us to read their values.
  
  final TextEditingController _usernameController = TextEditingController(); // Staff username
  final TextEditingController _passwordController = TextEditingController(); // Shared by both modes
  final TextEditingController _nameController = TextEditingController(); // Patient full name
  final TextEditingController _nationalIdController = TextEditingController(); // Patient national ID

  // ==========================================
  // ANIMATION CONTROLLERS
  // ==========================================
  // 'late' means these will be initialized later (in initState).
  
  /// Controls the page entrance animation (fade + slide up)
  late AnimationController _animController;
  late Animation<double> _fadeAnimation; // Opacity: 0.0 (invisible) to 1.0 (visible)
  late Animation<Offset> _slideAnimation; // Position offset for slide-in effect
  
  /// Controls the toggle switch sliding pill animation
  late AnimationController _toggleController;
  late Animation<double> _toggleSlideAnimation; // 0.0 = left (Patient), 1.0 = right (Staff)

  /// Called once when the widget is inserted into the widget tree.
  /// Perfect place to initialize animation controllers.
  @override
  void initState() {
    super.initState(); // Always call super.initState() first!
    
    // ========== PAGE ENTRANCE ANIMATION ==========
    // Creates a smooth fade-in + slide-up effect when the page loads.
    _animController = AnimationController(
      duration: Duration(milliseconds: 800), // Animation lasts 800ms
      vsync: this, // 'this' provides the ticker (TickerProviderStateMixin)
    );
    
    // Fade animation: 0% opacity -> 100% opacity
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut), // Smooth deceleration
    );
    
    // Slide animation: start 30% below final position, slide up to normal position
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3), // X=0 (no horizontal), Y=0.3 (30% down)
      end: Offset.zero, // Final position (normal)
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    
    // ========== TOGGLE SWITCH ANIMATION ==========
    // Controls the sliding pill indicator between Patient/Staff modes.
    _toggleController = AnimationController(
      duration: Duration(milliseconds: 300), // Quick 300ms transition
      vsync: this,
    );
    
    // Slide value: 0.0 = Patient (left), 1.0 = Staff (right)
    _toggleSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeInOutCubic),
    );
    
    // Start the entrance animation immediately
    _animController.forward();
  }

  /// Called when the widget is removed from the widget tree.
  /// CRITICAL: Always dispose of controllers to prevent memory leaks!
  @override
  void dispose() {
    // Dispose animation controllers to release resources
    _animController.dispose();
    _toggleController.dispose();
    
    // Dispose text controllers to release memory
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nationalIdController.dispose();
    
    super.dispose(); // Always call super.dispose() last!
  }

  // ==========================================
  // LOGIN HANDLER
  // ==========================================
  
  /// Handles the login button press.
  /// This is an async function because it makes API calls to our PHP backend.
  void _handleLogin() async {
    // Show loading spinner on the button
    setState(() { _isLoading = true; });

    // Get password (used by both login types)
    String password = _passwordController.text.trim(); // trim() removes whitespace
    Map<String, dynamic> result; // Will hold the API response

    // ========== PATIENT LOGIN ==========
    if (_isPatientLogin) {
      String name = _nameController.text.trim();
      String nid = _nationalIdController.text.trim(); // National ID

      // Validate that all fields are filled
      if (name.isEmpty || nid.isEmpty || password.isEmpty) {
        _showError("Please fill all fields");
        return; // Exit early if validation fails
      }

      // Call the API - patient uses fullName + nationalId + password
      result = await ApiService.login(
        loginType: 'patient', // Tells backend this is a patient login
        password: password,
        fullName: name,
        nationalId: nid,
      );
    } 
    // ========== STAFF LOGIN ==========
    else {
      String username = _usernameController.text.trim();

      // Validate that all fields are filled
      if (username.isEmpty || password.isEmpty) {
        _showError("Please fill all fields");
        return;
      }

      // Call the API - staff uses username + password
      result = await ApiService.login(
        loginType: 'staff', // Tells backend this is a staff login
        password: password,
        username: username,
      );
    }

    // Hide loading spinner
    setState(() { _isLoading = false; });

    // ========== HANDLE LOGIN RESULT ==========
    if (result['success']) {
      // LOGIN SUCCESS - Navigate to the appropriate home screen
      
      // Parse user ID from the response (comes as String, need int)
      int userId = int.parse(result['user_id'].toString());
      
      // Replace the current screen with the home screen
      // pushReplacement prevents going back to login with back button
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          // HomeScreenSelector chooses the right screen based on role
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreenSelector(
            role: result['role'], // 'admin', 'doctor', 'nurse', or 'patient'
            name: result['name'], // User's display name
            userId: userId,
          ),
          // Smooth fade transition between screens
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    } else {
      // LOGIN FAILED - Check why and show appropriate message
      
      // Special case: Patient account is restricted (3+ missed appointments)
      if (result['is_restricted'] == true && result['patient_id'] != null) {
        // Show dialog with option to request re-access
        _showRestrictedDialog(
          result['message'],
          int.parse(result['patient_id'].toString()),
          result['name'] ?? 'Patient',
        );
      } else {
        // Generic login failure (wrong password, user not found, etc.)
        _showDialog("Login Failed", result['message']);
      }
    }
  }

  // ==========================================
  // DIALOGS AND ERROR HANDLING
  // ==========================================
  
  /// Shows a special dialog for restricted patient accounts.
  /// Offers the option to navigate to the re-access request screen.
  /// 
  /// Parameters:
  /// - message: The restriction reason to display
  /// - patientId: ID of the restricted patient (for the request form)
  /// - patientName: Name to display on the request screen
  void _showRestrictedDialog(String message, int patientId, String patientName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // White background for clean look
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Title with lock icon to emphasize restriction
        title: Row(
          children: [
            Icon(Icons.lock, color: AppTheme.error), // Red lock icon
            SizedBox(width: 8),
            Text("Account Restricted", style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          // Cancel button - neutral gray styling
          GestureDetector(
            onTap: () => Navigator.pop(ctx), // Just close the dialog
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0), // Light gray background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 1), // Minimal spacing between buttons
          // Request Re-Access button - blue gradient for primary action
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx); // Close dialog first
              // Navigate to the re-access request form
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestReaccessScreen(
                    patientId: patientId,
                    patientName: patientName,
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Request Re-Access", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a brief error message as a snackbar at the bottom of the screen.
  /// Used for validation errors (e.g., "Please fill all fields").
  void _showError(String msg) {
    setState(() { _isLoading = false; }); // Stop the loading spinner
    // ScaffoldMessenger manages snackbars across the app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error, // Red background for errors
        behavior: SnackBarBehavior.floating, // Floats above content
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16), // Padding from screen edges
      ),
    );
  }

  /// Shows a simple alert dialog with a title and message.
  /// Used for general error messages (e.g., "Invalid credentials").
  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark, // White/light background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(msg, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close dialog
            child: Text("OK", style: TextStyle(color: AppTheme.adminPrimary)), // Green OK button
          ),
        ],
      ),
    );
  }

  /// Switches between Patient and Staff login modes.
  /// Animates the toggle pill to the selected side.
  void _switchLoginType(bool isPatient) {
    if (_isPatientLogin != isPatient) {
      setState(() {
        _isPatientLogin = isPatient; // Update state
      });
      // Animate the toggle pill
      if (isPatient) {
        _toggleController.reverse(); // Slide to left (Patient)
      } else {
        _toggleController.forward(); // Slide to right (Staff)
      }
    }
  }

  // ==========================================
  // BUILD METHOD - Main UI
  // ==========================================
  
  /// Builds the main login screen UI.
  /// The widget tree: Scaffold -> GradientBackground -> SafeArea -> ScrollView -> Column
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // GradientBackground is a custom widget from app_theme.dart
      // that creates a smooth gradient background
      body: GradientBackground(
        colors: AppTheme.loginGradient, // Blue gradient colors
        child: SafeArea(
          // SafeArea avoids notches and system UI
          child: Center(
            // SingleChildScrollView prevents overflow when keyboard appears
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              // FadeTransition for entrance animation
              child: FadeTransition(
                opacity: _fadeAnimation,
                // SlideTransition for slide-up entrance
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ========== LOGO & TITLE ==========
                      _buildLogo(), // App logo and title text
                      SizedBox(height: 40),

                      // ========== LOGIN CARD ==========
                      GlassCard(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          children: [
                            // Toggle Switch with sliding indicator
                            _buildAnimatedToggle(),
                            SizedBox(height: 30),

                            // Form Fields with crossfade
                            AnimatedCrossFade(
                              firstChild: _buildPatientFields(),
                              secondChild: _buildStaffFields(),
                              crossFadeState: _isPatientLogin 
                                  ? CrossFadeState.showFirst 
                                  : CrossFadeState.showSecond,
                              duration: Duration(milliseconds: 300),
                              sizeCurve: Curves.easeInOut,
                            ),

                            SizedBox(height: 20),

                            // Password Field
                            GlassTextField(
                              controller: _passwordController,
                              labelText: "Password",
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              focusColor: _isPatientLogin ? AppTheme.info : AppTheme.adminPrimary,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),

                            SizedBox(height: 32),

                            // Login Button
                            GlassButton(
                              text: "LOGIN",
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                              color: _isPatientLogin ? AppTheme.patientPrimary : AppTheme.adminPrimary,
                              icon: Icons.login,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Footer text
                      Text(
                        "",
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.doctorPrimary,
                AppTheme.patientPrimary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.doctorPrimary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.nightlight_round,
            size: 50,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        Text(
          "National Medical Record",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 1,
          ),
        ),
        Text(
          "Management System",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Animated toggle with sliding pill indicator
  Widget _buildAnimatedToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final toggleWidth = constraints.maxWidth;
        final pillWidth = toggleWidth / 2 - 4;
        
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.cardDarker,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Sliding indicator pill
              AnimatedBuilder(
                animation: _toggleSlideAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 4 + (_toggleSlideAnimation.value * pillWidth),
                    top: 4,
                    bottom: 4,
                    width: pillWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPatientLogin 
                            ? [AppTheme.patientPrimary, AppTheme.patientSecondary]
                            : [AppTheme.adminPrimary, AppTheme.adminSecondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_isPatientLogin ? AppTheme.patientPrimary : AppTheme.adminPrimary)
                                .withAlpha(102),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Button labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchLoginType(true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isPatientLogin ? Colors.white : AppTheme.textMuted,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: _isPatientLogin ? Colors.white : AppTheme.textMuted,
                              ),
                              SizedBox(width: 8),
                              Text("Patient"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchLoginType(false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: !_isPatientLogin ? Colors.white : AppTheme.textMuted,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge,
                                size: 18,
                                color: !_isPatientLogin ? Colors.white : AppTheme.textMuted,
                              ),
                              SizedBox(width: 8),
                              Text("Staff"),
                            ],
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
      },
    );
  }

  Widget _buildPatientFields() {
    return Column(
      key: ValueKey('patient'),
      children: [
        SizedBox(height: 8),  // Space for floating label
        GlassTextField(
          controller: _nameController,
          labelText: "Full Name",
          prefixIcon: Icons.person_outline,
          focusColor: AppTheme.info,  // Blue for patient
        ),
        SizedBox(height: 16),
        GlassTextField(
          controller: _nationalIdController,
          labelText: "National ID Number",
          prefixIcon: Icons.credit_card,
          keyboardType: TextInputType.number,
          focusColor: AppTheme.info,  // Blue for patient
        ),
      ],
    );
  }

  Widget _buildStaffFields() {
    return Column(
      key: ValueKey('staff'),
      children: [
        SizedBox(height: 8),  // Space for floating label
        GlassTextField(
          controller: _usernameController,
          labelText: "Staff Username",
          prefixIcon: Icons.account_circle_outlined,
          focusColor: AppTheme.adminPrimary,  // Green for staff
        ),
      ],
    );
  }
}