// ============================================
// HOME_SCREENS.DART - Role-Based Home Screens
// ============================================
// This file contains the home screens for all user roles:
// - PatientHome: View appointments and medical records
// - DoctorHome: View patients and manage appointments
// - NurseHome: Manage patients and their data
// - AdminHome: Manage staff, view logs, handle re-access requests
//
// The HomeScreenSelector routes users to the appropriate home screen
// based on their role returned from the login API.

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'app_theme.dart'; // Custom theme - colors, gradients, glassmorphism widgets
import 'login_screen.dart'; // For logout navigation
import 'api_service.dart'; // Backend API calls
import 'manage_staff_screen.dart'; // Admin: manage doctors/nurses/admins
import 'manage_patients_screen.dart'; // Nurse: manage patient records
import 'doctor_patients_screen.dart'; // Doctor: view patient list
import 'doctor_appointments_screen.dart'; // Doctor: manage appointments
import 'patient_medical_records_screen.dart'; // Patient: view own medical records
import 'patient_appointments_screen.dart'; // Patient: view own appointments
import 'manage_reaccess_screen.dart'; // Admin: handle re-access requests
import 'system_logs_screen.dart'; // Admin: view system activity logs

// ==========================================
// 1. THE SELECTOR (ROUTER)
// ==========================================

/// HomeScreenSelector acts as a router/dispatcher.
/// Based on the user's role, it returns the appropriate home screen widget.
/// This pattern keeps navigation logic centralized and clean.
class HomeScreenSelector extends StatelessWidget {
  final String role; // User role: 'admin', 'doctor', 'nurse', or 'patient'
  final String name; // User's display name
  final int userId; // Unique user ID from database

  const HomeScreenSelector({
    super.key,
    required this.role,
    required this.name,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Switch statement routes to the correct home screen based on role
    switch (role) {
      case 'doctor':
        return DoctorHome(name: name, userId: userId);
      case 'patient':
        return PatientHome(name: name, userId: userId);
      case 'nurse':
        return NurseHome(name: name, userId: userId);
      case 'admin':
        return AdminHome(name: name); // Admin doesn't need userId
      default:
        // Fallback for unknown roles - should never happen in production
        return Scaffold(
          body: Center(child: Text("Error: Unknown Role ($role)")),
        );
    }
  }
}

// ==========================================
// 2. PATIENT HOME
// ==========================================

/// PatientHome - The dashboard for logged-in patients.
/// Features:
/// - View upcoming scheduled appointments
/// - Quick access to Medical Records and all Appointments
/// - Animated entrance for a polished user experience
class PatientHome extends StatefulWidget {
  final String name; // Patient's display name
  final int userId; // Patient's user ID for API calls

  const PatientHome({super.key, required this.name, required this.userId});

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

/// State class for PatientHome.
/// SingleTickerProviderStateMixin provides one AnimationController ticker.
class _PatientHomeState extends State<PatientHome> with SingleTickerProviderStateMixin {
  // Future that holds the list of patient's appointments (loaded from API)
  late Future<List<dynamic>> _appointmentsFuture;
  
  // Animation controllers for entrance effects
  late AnimationController _animController;
  late Animation<double> _fadeAnimation; // Fade in effect

  /// Initialize state - fetch data and set up animations.
  @override
  void initState() {
    super.initState();
    // Fetch appointments from the API immediately
    // widget.userId accesses the parent StatefulWidget's properties
    _appointmentsFuture = ApiService.getPatientAppointments(widget.userId);
    
    // Set up fade-in animation (600ms duration)
    _animController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this, // TickerProvider for smooth animation
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(); // Start the animation
  }

  /// Clean up resources when widget is disposed.
  @override
  void dispose() {
    _animController.dispose(); // Prevent memory leaks
    super.dispose();
  }

  /// Logs out the user and returns to login screen.
  /// Uses pushReplacement to prevent going back with back button.
  void _logout() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        // Smooth fade transition
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Builds the main patient home screen UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow content behind app bar
      body: GradientBackground(
        colors: AppTheme.patientGradient, // Patient-specific gradient (indigo/blue)
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation, // Apply entrance fade animation
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),

                // Welcome Section
                _buildWelcomeSection(),

                // Quick Actions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQuickAction(Icons.medical_information, "Records", AppTheme.patientPrimary, () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PatientMedicalRecordsScreen(
                                userId: widget.userId,
                                patientName: widget.name,
                              ),
                            ));
                          }),
                          SizedBox(width: 12),
                          _buildQuickAction(Icons.calendar_month, "Appointments", AppTheme.doctorSecondary, () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PatientAppointmentsScreen(
                                userId: widget.userId,
                                patientName: widget.name,
                              ),
                            ));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Appointments Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upcoming Appointments",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PatientAppointmentsScreen(
                              userId: widget.userId,
                              patientName: widget.name,
                            ),
                          ));
                        },
                        child: Text("See All", style: TextStyle(color: AppTheme.patientPrimary)),
                      ),
                    ],
                  ),
                ),

                // Appointments List (only upcoming scheduled)
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _appointmentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: AppTheme.patientPrimary),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading data",
                            style: TextStyle(color: AppTheme.error),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Filter to only upcoming scheduled appointments
                      DateTime now = DateTime.now();
                      List<dynamic> upcomingAppointments = snapshot.data!.where((appt) {
                        DateTime? apptDate = DateTime.tryParse(appt['appointment_date'] ?? '');
                        return appt['status'] == 'scheduled' && apptDate != null && apptDate.isAfter(now);
                      }).toList();
                      
                      if (upcomingAppointments.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: upcomingAppointments.length,
                        itemBuilder: (context, index) {
                          var appt = upcomingAppointments[index];
                          return _buildAppointmentCard(appt);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the custom app bar with logo and logout button.
  /// We use a custom app bar instead of AppBar widget for design flexibility.
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.all(16), // 16px padding on all sides
      
      // Row layout: logo on left, logout button on right
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between items
        children: [
          // --- LEFT SIDE: Logo and title ---
          Row(
            children: [
              // Hospital icon in colored container
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.patientPrimary.withOpacity(0.2), // 20% opacity background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_hospital, color: AppTheme.patientPrimary),
              ),
              SizedBox(width: 12), // Horizontal spacing
              // App title text
              Text(
                "My Health",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // --- RIGHT SIDE: Logout button ---
          // GestureDetector makes the container tappable
          GestureDetector(
            onTap: _logout, // Call logout function
            child: Container(
              padding: EdgeInsets.all(10),
              // Glassmorphism styling
              decoration: BoxDecoration(
                color: AppTheme.glassWhite, // Semi-transparent white
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(Icons.logout, color: AppTheme.textSecondary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the welcome section showing patient avatar, name, and status.
  /// Uses GlassCard for a glassmorphism effect.
  Widget _buildWelcomeSection() {
    // GlassCard is our custom widget from app_theme.dart
    // Creates a semi-transparent card with blur effect
    return GlassCard(
      margin: EdgeInsets.all(20), // Margin around the card
      padding: EdgeInsets.all(20), // Padding inside the card
      borderColor: AppTheme.patientPrimary.withOpacity(0.3), // Subtle border
      
      // Row layout: avatar | text | status chip
      child: Row(
        children: [
          // --- AVATAR ---
          // Shows first letter of patient's name
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              // Gradient background for visual appeal
              gradient: LinearGradient(
                colors: [AppTheme.patientPrimary, AppTheme.patientSecondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              // Display first letter of name or "?" if empty
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16), // Horizontal spacing
          
          // --- WELCOME TEXT ---
          // Expanded fills remaining horizontal space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
              children: [
                // Greeting label
                Text(
                  "Welcome back,",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                // Patient's name (from widget.name property)
                Text(
                  widget.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // --- STATUS CHIP ---
          // StatusChip is our custom widget from app_theme.dart
          // Shows account status with colored badge
          StatusChip(status: "active"),
        ],
      ),
    );
  }

  /// Builds a single quick action button (Records or Appointments).
  /// Uses SolidCard with an icon and label.
  /// 
  /// Parameters:
  ///   icon - IconData for the button icon
  ///   label - Text label below the icon
  ///   color - Color for the icon and border
  ///   onTap - Callback function when button is tapped
  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    // Expanded makes this widget take half the row width (when 2 in a Row)
    return Expanded(
      // GestureDetector makes the card tappable
      child: GestureDetector(
        onTap: onTap, // Call the passed-in function
        
        // SolidCard is our custom card widget from app_theme.dart
        child: SolidCard(
          padding: EdgeInsets.symmetric(vertical: 14), // Vertical padding only
          borderRadius: 14,
          borderColor: color.withOpacity(0.15), // Subtle colored border
          
          // Column for vertical layout: icon above, label below
          child: Column(
            children: [
              // Icon in colored container
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2), // 20% opacity background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(height: 8), // Spacing between icon and text
              // Label text
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single appointment card for the ListView.
  /// Shows calendar icon, reason for visit, doctor name, date, and status.
  Widget _buildAppointmentCard(dynamic appt) {
    // SolidCard is our custom card widget from app_theme.dart
    return SolidCard(
      margin: EdgeInsets.only(bottom: 12), // Space below each card
      padding: EdgeInsets.all(16), // Inner padding
      
      // Row layout: calendar icon | text content | status chip
      child: Row(
        children: [
          // --- CALENDAR ICON ---
          // Colored container with status-based color
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              // 20% opacity of the status color
              color: _getStatusColor(appt['status']).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            // Calendar icon in status color
            child: Icon(
              Icons.calendar_today,
              color: _getStatusColor(appt['status']),
            ),
          ),
          SizedBox(width: 14), // Horizontal spacing
          
          // --- APPOINTMENT DETAILS ---
          // Expanded fills remaining horizontal space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
              children: [
                // Reason for visit (or generic "Appointment")
                Text(
                  appt['reason_for_visit'] ?? 'Appointment',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                // Doctor name and date
                // Uses null-aware access to handle missing data
                Text(
                  "Dr. ${appt['doctor_name']} • ${appt['appointment_date']}",
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // --- STATUS CHIP ---
          // StatusChip is our custom widget showing colored status badge
          StatusChip(status: appt['status']),
        ],
      ),
    );
  }

  /// Builds a placeholder widget shown when no appointments exist.
  /// Uses a glassmorphism card for visual appeal.
  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        margin: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Only take up needed space
          children: [
            Icon(Icons.event_available, size: 60, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              "No Appointments Yet",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Your appointments will appear here",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a color based on appointment status.
  /// Used for consistent status indication across the app.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled': return AppTheme.info; // Blue - upcoming
      case 'completed': return AppTheme.success; // Green - done
      case 'missed': return AppTheme.error; // Red - missed
      case 'cancelled': return AppTheme.warning; // Orange - cancelled
      default: return AppTheme.textMuted; // Gray - unknown
    }
  }
}

// ==========================================
// 3. DOCTOR HOME
// ==========================================

/// DoctorHome - The dashboard for logged-in doctors.
/// Features:
/// - View all patients
/// - Manage appointments (schedule, complete, mark missed)
/// - Stateless widget since it just displays menu options
class DoctorHome extends StatelessWidget {
  final String name; // Doctor's display name
  final int userId; // Doctor's user ID for API calls

  const DoctorHome({super.key, required this.name, required this.userId});

  /// Logs out and returns to login screen.
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Builds the doctor home screen with menu cards.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.doctorGradient.first,
      body: GradientBackground(
        colors: AppTheme.doctorGradient, // Doctor-specific blue gradient
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.doctorPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.medical_services, color: AppTheme.doctorPrimary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Doctor Portal",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _logout(context),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Icon(Icons.logout, color: AppTheme.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Welcome Card
                GlassCard(
                  borderColor: AppTheme.doctorPrimary.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.doctorPrimary, AppTheme.doctorSecondary],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, Dr. $name",
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Medical Specialist",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                Text(
                  "Quick Actions",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 16),

                // Action Tiles
                GlassNavTile(
                  icon: Icons.people_alt,
                  title: "My Patients",
                  subtitle: "View and manage patient records",
                  accentColor: AppTheme.doctorPrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorPatientsScreen(
                          doctorId: userId,
                          doctorName: name,
                        ),
                      ),
                    );
                  },
                ),

                GlassNavTile(
                  icon: Icons.calendar_month,
                  title: "Appointments",
                  subtitle: "Manage your schedule",
                  accentColor: AppTheme.doctorSecondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorAppointmentsScreen(
                          doctorUserId: userId,
                          doctorName: name,
                        ),
                      ),
                    );
                  },
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. NURSE HOME
// ==========================================

/// NurseHome - The dashboard for logged-in nurses.
/// Features:
/// - Manage patient records (CRUD operations)
/// - View and update patient information
/// - Stateless widget with navigation to patient management screen
class NurseHome extends StatelessWidget {
  final String name; // Nurse's display name
  final int userId; // Nurse's user ID

  const NurseHome({super.key, required this.name, required this.userId});

  /// Logs out and returns to login screen.
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Builds the nurse home screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nurseGradient.first,
      body: GradientBackground(
        colors: AppTheme.nurseGradient, // Nurse-specific cyan gradient
        child: SafeArea(
          child: LayoutBuilder(
            // LayoutBuilder gives us the available space for responsive design
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.nursePrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.favorite, color: AppTheme.nursePrimary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Nurse Portal",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _logout(context),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Icon(Icons.logout, color: AppTheme.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Welcome Card
                GlassCard(
                  borderColor: AppTheme.nursePrimary.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.nursePrimary, AppTheme.nurseSecondary],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, $name",
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Administrative Nurse",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                Text(
                  "Patient Management",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 16),

                // Action Tiles
                GlassNavTile(
                  icon: Icons.people_outline,
                  title: "Manage Patients",
                  subtitle: "Register, search, view, and edit patient records",
                  accentColor: AppTheme.nursePrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManagePatientsScreen()),
                    );
                  },
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. ADMIN HOME
// ==========================================

/// AdminHome - The dashboard for system administrators.
/// Features:
/// - Manage Staff: Add, edit, delete doctors, nurses, and other admins
/// - Manage Re-Access Requests: Approve/reject restricted patient requests
/// - System Logs: View all system activity for auditing
/// - This is the most powerful role with full system access
class AdminHome extends StatelessWidget {
  final String name; // Admin's display name

  const AdminHome({super.key, required this.name});

  /// Logs out and returns to login screen.
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Builds the admin home screen with management options.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adminGradient.first,
      body: GradientBackground(
        colors: AppTheme.adminGradient, // Admin-specific green gradient
        child: SafeArea(
          child: LayoutBuilder(
            // LayoutBuilder for responsive design
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.adminPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.admin_panel_settings, color: AppTheme.adminPrimary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Admin Panel",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _logout(context),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Icon(Icons.logout, color: AppTheme.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Welcome Card
                GlassCard(
                  borderColor: AppTheme.adminPrimary.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.adminPrimary, AppTheme.adminSecondary],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.shield, color: Colors.white, size: 32),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "System Administrator",
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Full System Access",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                Text(
                  "Staff Management",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 16),

                // Action Tiles
                GlassNavTile(
                  icon: Icons.medical_services,
                  title: "Manage Doctors",
                  subtitle: "Add, edit, or remove doctors",
                  accentColor: AppTheme.doctorPrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageStaffScreen(role: 'doctor'),
                      ),
                    );
                  },
                ),

                GlassNavTile(
                  icon: Icons.local_hospital,
                  title: "Manage Nurses",
                  subtitle: "Add, edit, or remove nurses",
                  accentColor: AppTheme.nursePrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageStaffScreen(role: 'nurse'),
                      ),
                    );
                  },
                ),

                SizedBox(height: 24),

                Text(
                  "System Controls",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 16),

                GlassNavTile(
                  icon: Icons.lock_open,
                  title: "Access Requests",
                  subtitle: "Review pending re-access requests",
                  accentColor: AppTheme.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageReaccessScreen(adminUserId: 0),
                      ),
                    );
                  },
                ),

                GlassNavTile(
                  icon: Icons.history,
                  title: "System Logs",
                  subtitle: "View recent system activity",
                  accentColor: AppTheme.adminSecondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SystemLogsScreen(),
                      ),
                    );
                  },
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}