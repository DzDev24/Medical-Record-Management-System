import 'dart:ui'; // Required for ImageFilter (the blur effect)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Used for modern, clean typography

/// ============================================
/// APP THEME - National Medical Record System
/// ============================================

class AppTheme {
  // ==========================================
  // ROLE-SPECIFIC COLOR PALETTES
  // ==========================================
  // NOTE: distinct color schemes help users immediately identify 
  // which portal they are logged into.
  
  // ADMIN - Green symbolizes organization, growth, and stability.
  static const Color adminPrimary = Color(0xFF059669);      // Emerald green
  static const Color adminSecondary = Color(0xFF10B981);    // Light green
  static const Color adminAccent = Color(0xFF34D399);       // Mint green
  static const List<Color> adminGradient = [
    Color(0xFFD1FAE5),  // Very light green
    Color(0xFFECFDF5),  // Lighter green
    Color(0xFFA7F3D0),  // Soft mint
  ];
  
  // DOCTOR - Blue symbolizes trust, intelligence, and calmness (standard medical color).
  static const Color doctorPrimary = Color(0xFF2563EB);     // Royal blue
  static const Color doctorSecondary = Color(0xFF3B82F6);   // Bright blue
  static const Color doctorAccent = Color(0xFF60A5FA);      // Sky blue
  static const List<Color> doctorGradient = [
    Color(0xFFE0F2FE),  // Very light blue
    Color(0xFFBAE6FD),  // Light sky blue
    Color(0xFF7DD3FC),  // Soft blue
  ];
  
  // NURSE - Cyan/Lighter Blue represents compassion, care, and approachability.
  static const Color nursePrimary = Color(0xFF0284C7);      // Ocean blue
  static const Color nurseSecondary = Color(0xFF0EA5E9);    // Cyan blue
  static const Color nurseAccent = Color(0xFF38BDF8);       // Light cyan
  static const List<Color> nurseGradient = [
    Color(0xFFE0F2FE),  // Very light blue
    Color(0xFFBAE6FD),  // Light sky blue
    Color(0xFF7DD3FC),  // Soft blue
  ];
  
  // PATIENT - Indigo/Deep Blue represents depth, sleep, and healing.
  static const Color patientPrimary = Color(0xFF1D4ED8);    // Deep blue
  static const Color patientSecondary = Color(0xFF2563EB);  // Royal blue
  static const Color patientAccent = Color(0xFF3B82F6);     // Bright blue
  static const List<Color> patientGradient = [
    Color(0xFFDBEAFE),  // Very light indigo-blue
    Color(0xFFBFDBFE),  // Light blue
    Color(0xFF93C5FD),  // Soft blue
  ];
  
  // LOGIN - Neutral blue gradient that feels welcoming to all users.
  static const List<Color> loginGradient = [
    Color(0xFFE0F2FE),  // Very light blue
    Color(0xFFBAE6FD),  // Light sky blue
    Color(0xFF0EA5E9),  // Cyan accent
  ];

  // ==========================================
  // GLASSMORPHISM UTILITIES
  // ==========================================
  // The '0x80' and '0x40' at the start of hex codes represent Alpha (Opacity).
  // 0x80 = approx 50% opacity, 0x40 = approx 25% opacity.
  
  static const Color glassWhite = Color(0x80FFFFFF);        // Pure white overlay
  static const Color glassBorder = Color(0x40FFFFFF);       // White border
  
  // Solid colors for readability
  static const Color cardDark = Color(0xFFFFFFFF);          // White cards
  static const Color cardDarker = Color(0xFFF8FAFC);        // Light gray cards
  
  // Typography Colors
  static const Color textPrimary = Color(0xFF1E293B);       // Dark slate text
  static const Color textSecondary = Color(0xFF475569);     // Medium slate text
  static const Color textMuted = Color(0xFF94A3B8);         // Muted slate text
  
  // Status Colors (Feedback)
  static const Color success = Color(0xFF22C55E); // Green for success
  static const Color warning = Color(0xFFF59E0B); // Orange for pending/warning
  static const Color error = Color(0xFFEF4444);   // Red for error/delete
  static const Color info = Color(0xFF3B82F6);    // Blue for information

  // ==========================================
  // DYNAMIC HELPERS
  // ==========================================
  
  // Returns the correct primary color based on the user string from the database
  static Color getPrimaryColor(String role) {
    switch (role) {
      case 'admin': return adminPrimary;
      case 'doctor': return doctorPrimary;
      case 'nurse': return nursePrimary;
      case 'patient': return patientPrimary;
      default: return adminPrimary;
    }
  }

  // Returns the correct background gradient based on the role
  static List<Color> getGradient(String role) {
    switch (role) {
      case 'admin': return adminGradient;
      case 'doctor': return doctorGradient;
      case 'nurse': return nurseGradient;
      case 'patient': return patientGradient;
      default: return loginGradient;
    }
  }

  // ==========================================
  // GLOBAL THEME CONFIGURATION
  // ==========================================
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: adminPrimary,
    scaffoldBackgroundColor: Colors.transparent, // Important for gradients to show through
    
    // Google Fonts implementation for consistent typography
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
      headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
    ),
    
    // Global styling for all Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassWhite,
      border: OutlineInputBorder( // Default border
        borderRadius: BorderRadius.circular(16), // Rounded corners
        borderSide: BorderSide(color: glassBorder), // Subtle border
      ),
      enabledBorder: OutlineInputBorder( // When not focused
        borderRadius: BorderRadius.circular(16), // Rounded corners
        borderSide: BorderSide(color: glassBorder), // Subtle border
      ),
      focusedBorder: OutlineInputBorder( // When focused
        borderRadius: BorderRadius.circular(16), // Rounded corners
        borderSide: BorderSide(color: adminPrimary, width: 2), // Highlighted border
      ),
      labelStyle: TextStyle(color: textSecondary), // Label text color
      prefixIconColor: textSecondary, // Icon color
    ),
    
    // Global styling for Buttons
    elevatedButtonTheme: ElevatedButtonThemeData( // ElevatedButton styling
      style: ElevatedButton.styleFrom( // Base style
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Button padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
        elevation: 0,
      ),
    ),
  );
}

// ==========================================
// CUSTOM WIDGET LIBRARY
// ==========================================

/// [GradientBackground]
/// This widget creates the "Foundation" of the UI.
/// It uses a Stack to place a gradient at the bottom and decorative 
/// circles on top to create depth before the actual content.
class GradientBackground extends StatelessWidget { // Accepts child widget and optional colors
  final Widget child;
  final List<Color> colors;

  const GradientBackground({ // Constructor with required child and optional colors
    super.key, 
    required this.child,
    this.colors = AppTheme.loginGradient,
  });

  @override
  Widget build(BuildContext context) { // Build method returns the gradient background with decorations
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      // Stack allows us to layer widgets on top of each other
      child: Stack( // Stack for decorative circles and content
        children: [
          // Decorative Circle 1 (Top Right)
          Positioned( // Positioned widget to place circle
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.last.withOpacity(0), // Fade out
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Decorative Circle 2 (Bottom Left)
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors[1].withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // The actual page content goes here
          child,
        ],
      ),
    );
  }
}

/// [GlassCard]
/// The core component of Glassmorphism.
/// 1. ClipRRect: Clips the blur to the rounded corners.
/// 2. BackdropFilter: The engine that blurs whatever is BEHIND the card.
/// 3. Container: Provides the semi-transparent white tint and border.

class GlassCard extends StatelessWidget { // Accepts child widget and customization options
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blur = 10,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) { // Build method returns the glass card with blur effect
    return Container( // Outer container for margin
      margin: margin,
      // ClipRRect ensures the blur effect doesn't "leak" outside the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        // BackdropFilter applies the gaussian blur to the background
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), // Blur intensity
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding ?? EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.glassWhite, // Semi-transparent white
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? AppTheme.glassBorder, // Subtle white border
                  width: 1.5,
                ),
                // Subtle shadow to lift the card off the background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// [SolidCard]
/// Sometimes Glassmorphism is too messy for complex data.
/// This widget provides a solid background for lists/data tables to ensure
/// high readability while maintaining the rounded style.
class SolidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SolidCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) { // Build method returns the solid card
    return GestureDetector( // Handles tap events if provided
      onTap: onTap, // Optional tap callback
      child: Container( // Outer container for margin and styling
        margin: margin, // Outer margin
        padding: padding ?? EdgeInsets.all(20),
        decoration: BoxDecoration( // Solid background with border and shadow
          color: backgroundColor ?? AppTheme.cardDark, // Default solid color
          borderRadius: BorderRadius.circular(borderRadius),
          // Conditional border rendering
          border: borderColor != null 
            ? Border.all(color: borderColor!, width: 1.5)  // Custom border color
            : Border.all(color: Color(0x10000000), width: 1), // Very light default border
          boxShadow: [ // Subtle shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Light shadow
              blurRadius: 8,
              offset: Offset(0, 2), // Slight downward offset
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// [GlassTextField]
/// A customized TextFormField that fits the glass aesthetic.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Color? focusColor;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon, // Icon at the start of the field
    this.obscureText = false, // Optional obscure text for passwords
    this.keyboardType, // Optional keyboard type
    this.validator,
    this.suffixIcon,
    this.focusColor,
  });

  @override
  Widget build(BuildContext context) { // Build method returns the customized TextFormField
    return TextFormField( // Core input field
      controller: controller, // Text controller
      obscureText: obscureText, // Obscure text for passwords
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.glassWhite,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        // Borders are defined in ThemeData, but can be overridden here
        border: OutlineInputBorder( // Default border
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder( // When not focused
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder( // When focused
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: focusColor ?? AppTheme.info, width: 2),
        ),
        errorBorder: OutlineInputBorder( // When error occurs
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}

/// [GlassButton]
/// A high-quality custom button with:
/// 1. Gradient background
/// 2. Loading state support (CircularProgressIndicator)
/// 3. "Scale" animation (shrinks slightly when pressed)
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin { // Animation for button press effect
  late AnimationController _controller; // Controls the animation
  late Animation<double> _scaleAnimation; // Animation for scaling

  @override
  void initState() { // Initialize animation controller and animation
    super.initState();
    // Setup animation controller for the button press effect
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    // Button will shrink to 95% of its size when held down
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { // Build method returns the animated button
    final buttonColor = widget.color ?? AppTheme.adminPrimary;
    
    // GestureDetector handles the Touch Down/Up to trigger animations
    return GestureDetector( // Detects tap events for animation
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      // AnimatedBuilder rebuilds just the Transform when animation value changes
      child: AnimatedBuilder( // Rebuilds on animation changes
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  buttonColor,
                  buttonColor.withAlpha(204), // Slight gradient for 3D effect
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withAlpha(102), // Colored shadow glow
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            // Show Loader if loading, otherwise show Text + Icon
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center content
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                      ],
                      Text(
                        widget.text, // Button text
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// [GlassNavTile]
/// A list item used for navigation menus. 
/// Uses SolidCard for better contrast against the glass background.
class GlassNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const GlassNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) { // Build method returns the navigation tile
    return SolidCard( // Uses SolidCard for better readability
      padding: EdgeInsets.all(18), 
      margin: EdgeInsets.symmetric(vertical: 6),
      borderColor: accentColor.withOpacity(0.2),
      onTap: onTap,
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration( // Icon background styling
              color: accentColor.withOpacity(0.15), // Light tint of accent color
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          SizedBox(width: 16),
          // Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
              children: [ // Title and optional subtitle
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 22),
        ],
      ),
    );
  }
}

/// [GlassAppBar]
/// A transparent App Bar that blurs the content scrolling behind it.
/// Implements 'PreferredSizeWidget' so Scaffolds accept it as an appBar.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color accentColor;
  final List<Widget>? actions;
  final bool showBack;

  const GlassAppBar({
    super.key,
    required this.title,
    required this.accentColor,
    this.actions,
    this.showBack = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight); // Standard app bar height

  @override
  Widget build(BuildContext context) { // Build method returns the glass app bar
    return ClipRRect(
      child: BackdropFilter( // Blurs content behind the app bar
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration( // Glass styling
            color: AppTheme.glassWhite, // Semi-transparent white
            border: Border(
              bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  if (!showBack) SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [StatusChip]
/// A dynamic pill-shaped tag.
/// It uses a switch statement to automatically determine the color (Red, Green, Blue)
/// based on the text string passed to it (e.g., "Active", "Cancelled").
class StatusChip extends StatelessWidget {
  final String status;
  
  const StatusChip({super.key, required this.status});

  // Determines background color opacity
  Color get backgroundColor { // Light opacity for background
    switch (status.toLowerCase()) { // Case-insensitive matching
      case 'scheduled': return AppTheme.info.withOpacity(0.2);
      case 'completed': return AppTheme.success.withOpacity(0.2);
      case 'missed': return AppTheme.error.withOpacity(0.2);
      case 'cancelled': return AppTheme.warning.withOpacity(0.2);
      case 'active': return AppTheme.success.withOpacity(0.2);
      case 'restricted': return AppTheme.error.withOpacity(0.2);
      case 'pending': return AppTheme.warning.withOpacity(0.2);
      case 'approved': return AppTheme.success.withOpacity(0.2);
      case 'rejected': return AppTheme.error.withOpacity(0.2);
      default: return AppTheme.glassWhite;
    }
  }

  // Determines text color
  Color get textColor {
    switch (status.toLowerCase()) {
      case 'scheduled': return AppTheme.info;
      case 'completed': return AppTheme.success;
      case 'missed': return AppTheme.error;
      case 'cancelled': return AppTheme.warning;
      case 'active': return AppTheme.success;
      case 'restricted': return AppTheme.error;
      case 'pending': return AppTheme.warning;
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.error;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) { // Build method returns the status chip
    return Container( // Pill-shaped container
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Padding for size
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text( // Status text
        status.toUpperCase(), // Uppercase for emphasis
        style: TextStyle( // Text styling
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}