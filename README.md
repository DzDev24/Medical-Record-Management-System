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

The National Medical Record Management System is designed to digitize and streamline healthcare operations. It provides role-based access for patients, doctors, and administrators, ensuring secure and efficient management of medical data.

---

## Features

### Patient Features
- View personal medical records and history
- Book and manage appointments
- View prescriptions and lab results
- Request re-access to restricted accounts
- Track appointment status

### Doctor Features
- View assigned patients and their medical records
- Manage appointments (confirm, complete, cancel, mark as missed)
- Create consultations with diagnoses and notes
- Prescribe medications
- Upload and manage lab results

### Administrator Features
- Manage all patients (add, edit, delete, restrict)
- Manage staff accounts (doctors, admins)
- View and manage all appointments
- Process re-access requests
- View system activity logs
- Access system statistics and metadata

### System Features
- Consecutive missed appointment tracking with automatic patient restriction
- Comprehensive activity logging
- Secure authentication with role-based access control
- File upload support for lab results

---

## Technology Stack

### Backend
- PHP 7.4+
- MySQL / MariaDB
- PDO for database operations
- Apache (XAMPP recommended)

### Mobile Application
- Flutter 3.x
- Dart
- HTTP package for API communication
- Google Fonts for typography
- Shared Preferences for local storage

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

## Backend Setup

### Prerequisites
- XAMPP (or similar PHP development environment)
- MySQL / MariaDB

### Installation

1. Copy the `backend` folder contents to your web server directory:
   ```
   C:\xampp\htdocs\medical_app\
   ```

2. Start Apache and MySQL services in XAMPP

3. Import the database:
   - Open phpMyAdmin (http://localhost/phpmyadmin)
   - Create a new database named `medical_record_system`
   - Import `medical_record_system.sql`

4. Configure database connection in `db_connect.php`:
   ```php
   $host = 'localhost';
   $dbname = 'medical_record_system';
   $username = 'root';
   $password = '';
   ```

5. Verify the API is running by accessing:
   ```
   http://localhost/medical_app/login.php
   ```

---

## Mobile App Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code with Flutter extensions
- Android device or emulator

### Installation

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update the API base URL in `lib/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_SERVER_IP/medical_app';
   ```

4. Run the application:
   ```bash
   flutter run
   ```

---

## Database Schema

The system uses the following main tables:

| Table | Description |
|-------|-------------|
| `users` | User accounts (patients, doctors, admins) |
| `patients` | Patient-specific information |
| `appointments` | Scheduled appointments |
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
| Patient | View own records, book appointments, request re-access |
| Doctor | Manage assigned patients, appointments, consultations |
| Admin | Full system access, user management, system logs |

---

## Screenshots

Screenshots can be added here to showcase the application interface.

---

## License

This project is developed for educational and demonstration purposes.

---

## Contact

For questions or support, please open an issue in this repository.
