# National Medical Record Management System

A comprehensive healthcare management solution consisting of a PHP backend API and a Flutter mobile application. This system enables healthcare providers to manage patient records, appointments, prescriptions, lab results, and consultations efficiently.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Backend Setup](#backend-setup)
- [Mobile App Setup](#mobile-app-setup)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [User Roles](#user-roles)
- [Screenshots](#screenshots)

---

## Overview

The National Medical Record Management System is a system designed to digitize and Patient medical records. It provides role-based access for patients, doctors, nurses and administrators, ensuring secure and efficient management of medical data.

---

## Features

### Patient Features
- View personal medical records and history
- View prescriptions and lab results
- Request re-access to restricted accounts
- View scheduled and past appointments and their status

### Doctor Features
- View patients and their medical records
- Manage appointments (create, modify, delete, confirm, complete, cancel, mark as missed)
- Create consultations with diagnoses and notes
- Prescribe medications
- Upload lab results

### Nurse Features
-Manage all patients (add, edit, delete)

### Administrator Features
- Manage staff accounts (doctors, admins)
- Process re-access requests
- View system activity logs

### Key Features
- Comprehensive activity logging
- Secure authentication with role-based access control
- File upload support for lab results

### Centralized Medical Records
eliminates duplicated records across different hospitals.
Allows real-time updates of diagnoses, treatments, prescriptions, and lab results.
### Automated Exclusion Mechanism (Anti-No-Show)
-Logic: The system automatically tracks patient attendance.
-Trigger: If a patient misses three (3) consecutive scheduled appointments.
-Action: The system automatically flags the patient and restricts access to their account.
-Resolution: The patient must submit a "Re-access Request" via the app, which the System Administrator must review and approve/reject.

---

## System Architecture
The project follows a client-server architecture

### Backend
Server: Apache (via XAMPP)
Language: PHP 8 (pure php not laravel)
Role: Handles HTTP requests, executes business logic, and manages database interactions.

### Database
System: MySQL / MariaDB
Management Tool: phpMyAdmin
Security: Passwords are hashed; critical medical data is encrypted.

### Mobile Application
- Dart
- Flutter (dart framework to make interfaces based on widgets system)
- HTTP package for API communication
- Google Fonts for typography
- intl: for date/time formatting
- Shared Preferences for local session management

---

## Project Structure

```
medical-app/
├── backend/
│   ├── db_connect.php              # Database connection configuration
│   ├── login.php                   # Authentication endpoint
│   ├── appointments_crud.php       # Appointment operations
│   ├── consultations_crud.php      # Consultation operations
│   ├── prescriptions_crud.php      # Prescription operations
│   ├── lab_results_crud.php        # Lab results operations
│   ├── reaccess_crud.php           # Re-access request operations
│   ├── logs_crud.php               # System logging operations
│   ├── add_patient.php             # Add new patient
│   ├── update_patient.php          # Update patient information
│   ├── delete_patient.php          # Delete patient
│   ├── get_patients.php            # Retrieve patients list
│   ├── get_patients_for_doctor.php # Get doctor's assigned patients
│   ├── get_patient_appointments.php# Get patient's appointments
│   ├── get_patient_full_records.php# Get complete patient records
│   ├── add_staff.php               # Add new staff member
│   ├── update_staff.php            # Update staff information
│   ├── delete_user.php             # Delete user account
│   ├── get_staff.php               # Retrieve staff list
│   ├── get_metadata.php            # Get system statistics
│   ├── upload_lab_file.php         # File upload handler
│   ├── uploads/                    # Uploaded files directory
│   └── medical_record_system.sql   # Database schema
│
└── mobile/
    ├── lib/
    │   ├── main.dart                       # Application entry point
    │   ├── api_service.dart                # API communication layer
    │   ├── app_theme.dart                  # Application theming
    │   ├── login_screen.dart               # Authentication screen
    │   ├── home_screens.dart               # Role-based home dashboards
    │   ├── doctor_appointments_screen.dart # Doctor appointment management
    │   ├── doctor_patients_screen.dart     # Doctor's patient list
    │   ├── patient_appointments_screen.dart# Patient appointment view
    │   ├── patient_medical_records_screen.dart # Patient records view
    │   ├── patient_detail_screen.dart      # Detailed patient view
    │   ├── manage_patients_screen.dart     # Admin patient management
    │   ├── manage_staff_screen.dart        # Admin staff management
    │   ├── manage_reaccess_screen.dart     # Re-access request management
    │   ├── request_reaccess_screen.dart    # Re-access request form
    │   └── system_logs_screen.dart         # System activity logs
    ├── android/
    │   └── app/src/main/AndroidManifest.xml
    └── pubspec.yaml                        # Flutter dependencies
```

---

## Setup and installation

### Prerequisites
- XAMPP (or similar PHP development environment like WAMP/MAMP)
- MySQL / MariaDB
- Flutter SDK installed and configured
- Android Studio to run as a native android application

### Installation

### Step 1: Backend Setup
1-Locate the backend folder in the project.
2-Move the folder to your server's root directory (e.g., C:\xampp\htdocs\medical_system).
3-Start Apache and MySQL in the XAMPP Control Panel.
4-Open http://localhost/phpmyadmin.
5-Create a new database named medical_record_system.
6-Import the medical_record_system.sql file provided in the backend folder.
Optional: Configure your IP address in db_connect.php if testing on a physical device.

### Step 2: Mobile App Setup
1-Open the mobile_app folder in your IDE.
2-Open lib/api/api_service.dart.
3-Change the baseUrl variable to match your local server IP:

```dart
// For Emulator
static const String baseUrl = 'http://10.0.2.2/medical_system';
// For Physical Device
static const String baseUrl = 'http://YOUR_PC_IP_ADDRESS/medical_system';
   ```
4-Run the dependencies command:
```bash
flutter pub get
   ```
5-Launch the app:
```bash
flutter run
   ```

## Database Schema

The system uses the following main tables:

| Table | Description |
|-------|-------------|
| `users` | User accounts (patients, doctors, admins) |
| `patients` | Patient-specific information |
| `appointments` | appointments |
| `consultations` | Medical consultations |
| `prescriptions` | Medication prescriptions |
| `lab_results` | Laboratory test results |
| `reaccess_requests` | Account re-access requests |
| `system_logs` | Activity audit trail |

---

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/login.php` | User authentication |

### Patients
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/get_patients.php` | List all patients |
| POST | `/add_patient.php` | Create new patient |
| POST | `/update_patient.php` | Update patient |
| POST | `/delete_patient.php` | Delete patient |

### Appointments
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/appointments_crud.php` | CRUD operations |

### Consultations
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/consultations_crud.php` | CRUD operations |

### Staff Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/get_staff.php` | List all staff |
| POST | `/add_staff.php` | Create staff account |
| POST | `/update_staff.php` | Update staff |
| POST | `/delete_user.php` | Delete user |

---

## User Roles

| Role | Access Level |
|------|--------------|
| Patient | View own records, view past and scheduled appointments, request re-access |
| Doctor | Manage patients, appointments, consultations |
| Nurse | Manage patients |
| Admin |manage doctors and nurses, treat re access requests, view system logs |

---

## Screenshots

Screenshots can be added here to showcase the application interface.

---

