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

## IMPORTANT NOTE: replace androidManifest.xml with the one provided so the app workds correctly (change to support file upload in emulator), and replace pubspec.yaml with the one provided so you can install all dependencies with flutter pub get

---

## Screenshots

### Admin pages

<img width="406" height="853" alt="Screenshot 2026-01-26 234055" src="https://github.com/user-attachments/assets/183c3ae5-ce2b-4af7-bbd6-f9a7cd753e6b" />
<img width="406" height="853" alt="Screenshot 2026-01-26 234055" src="https://github.com/user-attachments/assets/183c3ae5-ce2b-4af7-bbd6-f9a7cd753e6b" />
<img width="408" height="853" alt="Screenshot 2026-01-26 234117" src="https://github.com/user-attachments/assets/1da5f8fa-a3e0-4140-8fb7-4515cc553bb8" />
<img width="408" height="853" alt="Screenshot 2026-01-26 234117" src="https://github.com/user-attachments/assets/1da5f8fa-a3e0-4140-8fb7-4515cc553bb8" />
![Uploading Screenshot 2026-01-26 234117.png…]()<img width="406" height="840" alt="Screenshot 2026-01-26 234437" src="https://github.com/user-attachments/assets/3f7104cc-5119-41c8-b962-068fa6a78c95" />
<img width="406" height="840" alt="Screenshot 2026-01-26 234437" src="https://github.com/user-attachments/assets/3f7104cc-5119-41c8-b962-068fa6a78c95" />
<img width="407" height="847" alt="Screenshot 2026-01-26 234406" src="https://github.com/user-attachments/assets/e0f61036-7405-40d4-a4b8-98f97c0fbc96" />
<img width="407" height="847" alt="Screenshot 2026-01-26 234406" src="https://github.com/user-attachments/assets/e0f61036-7405-40d4-a4b8-98f97c0fbc96" />
<img width="416" height="861" alt="Screenshot 2026-01-26 234343" src="https://github.com/user-attachments/assets/d2a02bd8-0d21-4408-b724-2a6b89fbe55f" />
<img width="416" height="861" alt="Screenshot 2026-01-26 234343" src="https://github.com/user-attachments/assets/d2a02bd8-0d21-4408-b724-2a6b89fbe55f" />
<img width="410" height="851" alt="Screenshot 2026-01-26 234141" src="https://github.com/user-attachments/assets/c37d5cf7-5c9f-4ffd-9e91-ff022a8a828d" />
<img width="410" height="851" alt="Screenshot 2026-01-26 234141" src="https://github.com/user-attachments/assets/c37d5cf7-5c9f-4ffd-9e91-ff022a8a828d" />

### Doctor pages
<img width="402" height="862" alt="Screenshot 2026-01-27 000604" src="https://github.com/user-attachments/assets/1c8e9ca4-a6c2-4688-a12b-125ae4c3fceb" />
<img width="402" height="862" alt="Screenshot 2026-01-27 000604" src="https://github.com/user-attachments/assets/1c8e9ca4-a6c2-4688-a12b-125ae4c3fceb" />
<img width="406" height="842" alt="Screenshot 2026-01-27 000541" src="https://github.com/user-attachments/assets/639b8008-9f88-47df-b533-2879e69ea5c0" />
<img width="406" height="842" alt="Screenshot 2026-01-27 000541" src="https://github.com/user-attachments/assets/639b8008-9f88-47df-b533-2879e69ea5c0" />
<img width="406" height="847" alt="Screenshot 2026-01-27 000506" src="https://github.com/user-attachments/assets/c37367b7-840d-4552-8b6d-e22142c84375" />
<img width="406" height="847" alt="Screenshot 2026-01-27 000506" src="https://github.com/user-attachments/assets/c37367b7-840d-4552-8b6d-e22142c84375" />
<img width="395" height="852" alt="Screenshot 2026-01-27 000441" src="https://github.com/user-attachments/assets/e00457fe-14e0-4518-b5be-bcfe876e40b4" />
<img width="395" height="852" alt="Screenshot 2026-01-27 000441" src="https://github.com/user-attachments/assets/e00457fe-14e0-4518-b5be-bcfe876e40b4" />
<img width="393" height="847" alt="Screenshot 2026-01-27 000426" src="https://github.com/user-attachments/assets/9623a91b-c579-45e8-8ece-dd3a299c0d1c" />
<img width="393" height="847" alt="Screenshot 2026-01-27 000426" src="https://github.com/user-attachments/assets/9623a91b-c579-45e8-8ece-dd3a299c0d1c" />
<img width="403" height="845" alt="Screenshot 2026-01-27 000336" src="https://github.com/user-attachments/assets/d78deeab-fa38-481b-9faa-5f03998c8677" />
<img width="403" height="845" alt="Screenshot 2026-01-27 000336" src="https://github.com/user-attachments/assets/d78deeab-fa38-481b-9faa-5f03998c8677" />

<img width="398" height="826" alt="Screenshot 2026-01-27 000317" src="https://github.com/user-attachments/assets/003c6ee1-c0b1-4eed-ac90-4cadbee6371d" />
<img width="398" height="826" alt="Screenshot 2026-01-27 000317" src="https://github.com/user-attachments/assets/003c6ee1-c0b1-4eed-ac90-4cadbee6371d" />
<img width="400" height="855" alt="Screenshot 2025-07-31 020422" src="https://github.com/user-attachments/assets/fce4310c-3574-4a25-867e-d5fb11677298" />
<img width="400" height="855" alt="Screenshot 2025-07-31 020422" src="https://github.com/user-attachments/assets/fce4310c-3574-4a25-867e-d5fb11677298" />
<img width="401" height="852" alt="Screenshot 2026-01-27 000648" src="https://github.com/user-attachments/assets/1f156a05-d098-4c01-beb0-d80d8c3bc375" />
![Upload<img width="405" height="848" alt="sssd" src="https://github.com/user-attachments/assets/f218fcc3-02c6-47af-9021-3e096ebe3312" />
<img width="405" height="848" alt="sssd" src="https://github.com/user-attachments/assets/f218fcc3-02c6-47af-9021-3e096ebe3312" />
ing Screenshot 2026-01-27 000648.png…]()
in pages
<img width="400" height="851" alt="Screenshot 2026-01-27 000625" src="https://github.com/user-attachments/assets/c9295630-cc1d-4441-a343-97dd5a4b580d" />
<img width="400" height="851" alt="Screenshot 2026-01-27 000625" src="https://github.com/user-attachments/assets/c9295630-cc1d-4441-a343-97dd5a4b580d" />

### Nurse pages
<img width="407" height="768" alt="Screenshot 2026-01-27 003313" src="https://github.com/user-attachments/assets/9aa3c1ca-3ef1-40ff-8eac-6c08bfbd19cf" />
<img width="407" height="768" alt="Screenshot 2026-01-27 003313" src="https://github.com/user-attachments/assets/9aa3c1ca-3ef1-40ff-8eac-6c08bfbd19cf" />
<img width="401" height="853" alt="Screenshot 2026-01-27 003235" src="https://github.com/user-attachments/assets/454191bb-0e22-4fbf-b253-3f43b8cf1193" />
<img width="401" height="853" alt="Screenshot 2026-01-27 003235" src="https://github.com/user-attachments/assets/454191bb-0e22-4fbf-b253-3f43b8cf1193" />
<img width="408" height="843" alt="Screenshot 2026-01-27 003217" src="https://github.com/user-attachments/assets/9067b328-0f33-4ede-9c77-375374bd30c5" />
<img width="408" height="843" alt="Screenshot 2026-01-27 003217" src="https://github.com/user-attachments/assets/9067b328-0f33-4ede-9c77-375374bd30c5" />
<img width="400" height="840" alt="Screenshot 2026-01-27 002258" src="https://github.com/user-attachments/assets/0eb54d66-4704-4938-aa42-fccedd8038ed" />
<img width="400" height="840" alt="Screenshot 2026-01-27 002258" src="https://github.com/user-attachments/assets/0eb54d66-4704-4938-aa42-fccedd8038ed" />
<img width="398" height="880" alt="dgfdfg" src="https://github.com/user-attachments/assets/d94aceb6-f1ce-4d53-9197-f39756d9199c" />
<img width="398" height="880" alt="dgfdfg" src="https://github.com/user-attachments/assets/d94aceb6-f1ce-4d53-9197-f39756d9199c" />
<img width="403" height="860" alt="asdadss" src="https://github.com/user-attachments/assets/9daabe00-9e47-40e6-8c07-fd1f3f4d9322" />
<img width="403" height="860" alt="asdadss" src="https://github.com/user-attachments/assets/9daabe00-9e47-40e6-8c07-fd1f3f4d9322" />

### Patient pages
<img width="407" height="842" alt="Screenshot 2026-01-27 004348" src="https://github.com/user-attachments/assets/968231e2-e594-4768-85d4-1616b06e25aa" />
<img width="407" height="842" alt="Screenshot 2026-01-27 004348" src="https://github.com/user-attachments/assets/968231e2-e594-4768-85d4-1616b06e25aa" />
<img width="407" height="835" alt="Screenshot 2026-01-27 004308" src="https://github.com/user-attachments/assets/7535b9eb-6ef9-4233-bfb6-ad63d4858a27" />
<img width="407" height="835" alt="Screenshot 2026-01-27 004308" src="https://github.com/user-attachments/assets/7535b9eb-6ef9-4233-bfb6-ad63d4858a27" />
<img width="410" height="847" alt="Screenshot 2026-01-27 004250" src="https://github.com/user-attachments/assets/95e1a3c5-ee76-40e5-8824-c806b82e7c8a" />
<img width="410" height="847" alt="Screenshot 2026-01-27 004250" src="https://github.com/user-attachments/assets/95e1a3c5-ee76-40e5-8824-c806b82e7c8a" />
<img width="407" height="837" alt="Screenshot 2026-01-27 004233" src="https://github.com/user-attachments/assets/3481aef4-4256-40f3-bc5c-17e1333533eb" />
<img width="407" height="837" alt="Screenshot 2026-01-27 004233" src="https://github.com/user-attachments/assets/3481aef4-4256-40f3-bc5c-17e1333533eb" />
<img width="408" height="842" alt="Screenshot 2026-01-27 004154" src="https://github.com/user-attachments/assets/d23fd9df-e283-49b2-8ab8-350945da49b5" />
<img width="408" height="842" alt="Screenshot 2026-01-27 004154" src="https://github.com/user-attachments/assets/d23fd9df-e283-49b2-8ab8-350945da49b5" />
<img width="403" height="833" alt="Screenshot 2026-01-27 004128" src="https://github.com/user-attachments/assets/70e478de-bcd1-42eb-abb7-ec80e6b056fe" />
<img width="403" height="833" alt="Screenshot 2026-01-27 004128" src="https://github.com/user-attachments/assets/70e478de-bcd1-42eb-abb7-ec80e6b056fe" />

### Other pages
<img width="400" height="848" alt="Screenshot 2026-01-27 011641" src="https://github.com/user-attachments/assets/93da6375-852f-4297-8813-1b983d393186" />
<img width="400" height="848" alt="Screenshot 2026-01-27 011641" src="https://github.com/user-attachments/assets/93da6375-852f-4297-8813-1b983d393186" />
<img width="402" height="857" alt="Screenshot 2026-01-27 011558" src="https://github.com/user-attachments/assets/189af366-015a-4ebb-b28a-e81672b7241c" />
<img width="402" height="857" alt="Screenshot 2026-01-27 011558" src="https://github.com/user-attachments/assets/189af366-015a-4ebb-b28a-e81672b7241c" />
<img width="400" height="840" alt="Screenshot 2026-01-27 011534" src="https://github.com/user-attachments/assets/69acdb88-267e-483e-b5ef-41f0eafaabd9" />
<img width="400" height="840" alt="Screenshot 2026-01-27 011534" src="https://github.com/user-attachments/assets/69acdb88-267e-483e-b5ef-41f0eafaabd9" />

---

