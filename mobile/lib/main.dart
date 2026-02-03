// ============================================
// MAIN.DART - Application Entry Point
// ============================================
// This is the first file that runs when the app starts.


import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:flutter/services.dart'; // For SystemChrome to control status bar and navigation bar
import 'app_theme.dart'; // Our custom theme configuration (colors, styles, widgets)
import 'login_screen.dart'; // The first screen users see


void main() {

  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    
    statusBarColor: Colors.transparent,
    
    statusBarIconBrightness: Brightness.light,
    
    systemNavigationBarColor: Color(0xFF0F172A), 
    
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  

  runApp(const MedicalApp());
}


class MedicalApp extends StatelessWidget {
  
  const MedicalApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'National Medical Record System',
      
      
      debugShowCheckedModeBanner: false,
      
      
      theme: AppTheme.darkTheme,
      
      home: const LoginScreen(),
    );
  }
}
