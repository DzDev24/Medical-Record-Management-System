-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 03, 2026 at 06:35 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `medical_record_system`
--

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `appointment_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `doctor_id` int(11) NOT NULL,
  `appointment_date` datetime NOT NULL,
  `reason_for_visit` text DEFAULT NULL,
  `status` enum('scheduled','completed','missed','cancelled') DEFAULT 'scheduled',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointments`
--

INSERT INTO `appointments` (`appointment_id`, `patient_id`, `doctor_id`, `appointment_date`, `reason_for_visit`, `status`, `created_at`) VALUES
(20, 2, 3, '2026-01-27 07:00:00', 'f', 'completed', '2026-01-24 11:41:27'),
(21, 2, 3, '2026-01-27 07:00:00', '', 'completed', '2026-01-24 11:54:30'),
(22, 2, 3, '2026-01-25 09:00:00', '', 'completed', '2026-01-24 12:04:34'),
(23, 2, 3, '2026-01-25 09:00:00', 'this is test', 'missed', '2026-01-24 15:40:18'),
(24, 2, 4, '2026-01-25 09:00:00', 'test', 'missed', '2026-01-24 15:45:07'),
(25, 2, 4, '2026-01-25 09:00:00', 'jjj', 'missed', '2026-01-24 15:53:35'),
(30, 2, 3, '2026-01-28 11:00:00', 'this s', 'completed', '2026-01-25 17:14:23'),
(31, 2, 3, '2026-02-02 11:00:00', 'for checkup', 'completed', '2026-02-01 09:26:21'),
(32, 2, 3, '2026-02-04 10:00:00', 'final COVID Checkup', 'scheduled', '2026-02-01 09:27:42'),
(33, 2, 4, '2026-02-04 00:10:00', '', 'completed', '2026-02-01 12:29:25');

-- --------------------------------------------------------

--
-- Table structure for table `consultations`
--

CREATE TABLE `consultations` (
  `consultation_id` int(11) NOT NULL,
  `appointment_id` int(11) DEFAULT NULL,
  `patient_id` int(11) NOT NULL,
  `doctor_id` int(11) NOT NULL,
  `visit_date` datetime DEFAULT current_timestamp(),
  `diagnosis` text DEFAULT NULL,
  `symptoms` text DEFAULT NULL,
  `doctor_notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `consultations`
--

INSERT INTO `consultations` (`consultation_id`, `appointment_id`, `patient_id`, `doctor_id`, `visit_date`, `diagnosis`, `symptoms`, `doctor_notes`) VALUES
(10, NULL, 3, 3, '2025-12-27 15:45:12', 'ffdds', 'sdsdfd', 'sddf'),
(16, NULL, 5, 3, '2025-12-27 16:13:13', 'qew', 'weq', 'weqw'),
(19, NULL, 2, 3, '2026-01-24 12:25:36', 'he is sick', 'nose runny\nfever\netc', 'tale medsd'),
(20, 20, 2, 3, '2026-01-24 12:50:48', 'sick', 'he is sick', 'very sick'),
(21, 22, 2, 3, '2026-01-24 13:06:15', 'might be sick', 'sss', 'ss'),
(24, 30, 2, 3, '2026-01-25 18:15:07', 'very sick', 'sick ', 'sick'),
(25, NULL, 2, 3, '2026-02-01 10:20:35', 'COVID19', 'Fever, red eyes', 'take a rest and avoid contact with familty members'),
(26, 31, 2, 3, '2026-02-01 10:27:00', 'Cured Of COVID 19', 'none', 'he is cured'),
(27, NULL, 2, 4, '2026-02-01 13:27:56', 'dgfhgjhk', 'dfgfhgjhk', 'dfgfhgj'),
(28, 33, 2, 4, '2026-02-01 13:30:35', 'test sick', 'fever', 'treated');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `department_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`department_id`, `name`) VALUES
(1, 'Emergency'),
(4, 'Geriatrics'),
(2, 'ICU'),
(5, 'Outpatient'),
(3, 'Pediatrics'),
(6, 'Surgery Ward');

-- --------------------------------------------------------

--
-- Table structure for table `doctors`
--

CREATE TABLE `doctors` (
  `doctor_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `specialty_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `doctors`
--

INSERT INTO `doctors` (`doctor_id`, `user_id`, `full_name`, `phone_number`, `specialty_id`) VALUES
(3, 11, 'Boughida Nazim', '+213782258693', 4),
(4, 12, 'Amri Baha Eddine', '+213560796856', 5),
(6, 17, 'Ali Mohamed', '+213782258693', 2),
(7, 20, 'Chaith Makhloufi', '+2130552306604', 2),
(8, 21, 'Ahmed Mahmoud', '+213782258693', 1);

-- --------------------------------------------------------

--
-- Table structure for table `lab_results`
--

CREATE TABLE `lab_results` (
  `result_id` int(11) NOT NULL,
  `consultation_id` int(11) NOT NULL,
  `test_name` varchar(150) NOT NULL,
  `result_summary` text DEFAULT NULL,
  `result_file_path` varchar(255) DEFAULT NULL,
  `test_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_results`
--

INSERT INTO `lab_results` (`result_id`, `consultation_id`, `test_name`, `result_summary`, `result_file_path`, `test_date`) VALUES
(8, 10, 'ds', 'sads', NULL, '2025-12-27'),
(12, 16, 'wwe', 'wwq', '[\"uploads/lab_results/lab_1766857244_eb324da086a4ac01.pdf\"]', '2025-12-27'),
(14, 19, 'blood test', 'passed', '[\"uploads/lab_results/lab_1769253932_ac20b070fa5ae198.pdf\"]', '2026-01-24'),
(15, 21, 'result', 'this is test', 'uploads/lab_results/lab_1769256375_d30a8fcdeef05408.pdf', '2026-01-24'),
(17, 25, 'COVID19 TEST', 'Positive', '[\"uploads/lab_results/lab_1769937604_db4996555163dddc.jpg\"]', '2026-02-01'),
(18, 28, 'test', 'sick', 'uploads/lab_results/lab_1769949035_d3433c8f2096ca6e.jpg', '2026-02-01');

-- --------------------------------------------------------

--
-- Table structure for table `nurses`
--

CREATE TABLE `nurses` (
  `nurse_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `department_id` int(11) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nurses`
--

INSERT INTO `nurses` (`nurse_id`, `user_id`, `full_name`, `department_id`, `phone_number`) VALUES
(4, 13, 'Boughida Nazim', 2, '+213782258693'),
(5, 14, 'Amri Baha Eddine', 6, '+213560796856'),
(6, 18, 'Mohamed Salah', 2, '+213782258693'),
(7, 22, 'Meryem Meryem', 2, '+213782258693');

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `patient_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `national_id` varchar(50) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `date_of_birth` date NOT NULL,
  `gender` enum('Male','Female') NOT NULL,
  `address` text DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `blood_type` varchar(5) DEFAULT NULL,
  `account_status` enum('active','restricted') DEFAULT 'active',
  `consecutive_missed_appointments` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patients`
--

INSERT INTO `patients` (`patient_id`, `user_id`, `national_id`, `full_name`, `date_of_birth`, `gender`, `address`, `phone_number`, `blood_type`, `account_status`, `consecutive_missed_appointments`, `created_at`) VALUES
(2, 8, '111000111', 'Ahmed Benali', '1985-05-15', 'Male', '123 Algiers St', '+0550112233', 'B+', 'active', 0, '2025-12-22 02:23:00'),
(3, 9, '222000222', 'Sarah Kaci', '1992-11-20', 'Female', '45 Oran Ave', '0660445566', 'o+', 'restricted', 0, '2025-12-22 02:23:00'),
(5, 16, '123456789', 'Boughida Ahmedi', '2005-01-19', 'Male', 'address123 numero 5', '+213782258693', 'AB+', 'active', 0, '2025-12-27 01:59:43'),
(6, 19, '1234567890', 'Mohamed Test', '2005-03-16', 'Female', '26 cooperative n55', '+213782258693', 'B-', 'active', 0, '2026-01-24 09:23:10');

-- --------------------------------------------------------

--
-- Table structure for table `prescriptions`
--

CREATE TABLE `prescriptions` (
  `prescription_id` int(11) NOT NULL,
  `consultation_id` int(11) NOT NULL,
  `medication_name` varchar(150) NOT NULL,
  `dosage` varchar(100) DEFAULT NULL,
  `frequency` varchar(100) DEFAULT NULL,
  `duration` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `prescriptions`
--

INSERT INTO `prescriptions` (`prescription_id`, `consultation_id`, `medication_name`, `dosage`, `frequency`, `duration`) VALUES
(8, 10, 'adasd', 'asdadsdsa', 'fdffd', 'vcxx'),
(14, 16, 'ew', 'wq', 'we', 'e'),
(17, 19, 'meds', '500mg', '3x daily', 'for 1 month'),
(18, 25, 'Paracetamol', '1g', '2 times a day', '7 days'),
(19, 25, 'Vitamin C', '500mg', '1 time daily', '7 days'),
(20, 28, 'kgf', 'gff', 'gff', 'ff');

-- --------------------------------------------------------

--
-- Table structure for table `reaccess_requests`
--

CREATE TABLE `reaccess_requests` (
  `request_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `reason` text NOT NULL,
  `contact_phone` varchar(20) DEFAULT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `admin_response` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `processed_at` timestamp NULL DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reaccess_requests`
--

INSERT INTO `reaccess_requests` (`request_id`, `patient_id`, `reason`, `contact_phone`, `status`, `admin_response`, `created_at`, `processed_at`, `processed_by`) VALUES
(1, 2, 'I missed my appointments because I could not do anything about it', '+213782258693', 'approved', 'Your request has been approved. You can now login and book appointments.', '2025-12-27 21:32:17', '2025-12-27 21:33:05', 0),
(2, 3, 'I Could not attend because of issues please unrestrict me', '+213782258693', 'rejected', 'Your request has been rejected. Please contact the clinic for more information.', '2026-01-24 09:49:24', '2026-01-24 09:50:36', 0),
(3, 3, 'I was having issues and could not attend as a result', '+213782258693', 'approved', 'Your request has been approved. You can now login and book appointments.', '2026-01-24 09:54:52', '2026-01-24 09:56:15', 0),
(4, 3, 'test', NULL, 'rejected', 'Your request has been rejected. Please contact the clinic for more information.', '2026-01-24 09:58:03', '2026-01-24 09:58:23', 0),
(5, 3, 'test test', '+213782258693', 'approved', 'Your request has been approved. You can now login and book appointments.', '2026-01-24 10:05:03', '2026-01-24 10:05:17', 0),
(6, 3, 'test2', NULL, 'approved', 'Your request has been approved. You can now login and book appointments.', '2026-01-24 10:08:58', '2026-01-24 10:09:06', 0),
(7, 3, 'test3', '+213782258693', 'approved', 'Your request has been approved. You can now login and book appointments.', '2026-01-24 10:13:20', '2026-01-24 10:13:43', 0),
(8, 3, 'test3', NULL, 'approved', 'Your request has been approved. You can now login and book appointments.', '2026-01-24 10:18:18', '2026-01-24 10:18:26', 0),
(9, 3, 'test4', NULL, 'rejected', 'Your request has been rejected. Please contact the clinic for more information.', '2026-01-24 10:25:05', '2026-01-24 11:03:24', 0),
(10, 2, 'I am testing the application', '+213782258693', 'approved', 'Your request has been approved. You can now login and book appointments.', '2026-01-24 16:02:52', '2026-01-24 16:03:25', 0),
(11, 3, 'I had other things to do and as a result missed 3 appointments', '+213782258693', 'pending', NULL, '2026-01-26 22:43:22', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `re_access_requests`
--

CREATE TABLE `re_access_requests` (
  `request_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `request_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `reason_for_absence` text DEFAULT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `admin_response` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `specialties`
--

CREATE TABLE `specialties` (
  `specialty_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `specialties`
--

INSERT INTO `specialties` (`specialty_id`, `name`) VALUES
(1, 'Cardiology'),
(5, 'Dermatology'),
(4, 'General Surgery'),
(2, 'Neurology'),
(6, 'Orthopedics'),
(3, 'Pediatrics');

-- --------------------------------------------------------

--
-- Table structure for table `system_logs`
--

CREATE TABLE `system_logs` (
  `log_id` int(11) NOT NULL,
  `action_type` varchar(50) NOT NULL,
  `action_description` text NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(150) DEFAULT NULL,
  `user_role` varchar(20) DEFAULT NULL,
  `target_type` varchar(50) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_logs`
--

INSERT INTO `system_logs` (`log_id`, `action_type`, `action_description`, `user_id`, `user_name`, `user_role`, `target_type`, `target_id`, `ip_address`, `created_at`) VALUES
(1, 'test', 'Test log entry', NULL, 'Admin', NULL, NULL, NULL, NULL, '2025-12-27 22:21:39'),
(2, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2025-12-27 22:22:39'),
(3, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2025-12-27 22:23:08'),
(4, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2025-12-27 22:23:21'),
(5, 'login_success', 'Karim Ziani logged in successfully', 10, 'Karim Ziani', 'patient', NULL, NULL, '127.0.0.1', '2025-12-27 22:23:45'),
(6, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2025-12-27 22:24:27'),
(7, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2025-12-27 22:24:57'),
(8, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2025-12-27 22:25:47'),
(9, 'login_success', 'Karim Ziani logged in successfully', 10, 'Karim Ziani', 'patient', NULL, NULL, '127.0.0.1', '2025-12-27 22:26:14'),
(10, 'login_success', 'Karim Ziani logged in successfully', 10, 'Karim Ziani', 'patient', NULL, NULL, '127.0.0.1', '2025-12-27 22:29:02'),
(11, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2025-12-27 22:29:36'),
(12, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-03 10:09:21'),
(13, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-05 10:28:02'),
(14, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-05 10:29:22'),
(15, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-05 12:42:41'),
(16, 'login_failed', 'Invalid password attempt for: Boughida Nazim', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-05 13:00:02'),
(17, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-05 13:00:15'),
(18, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-05 13:04:54'),
(19, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-05 13:06:38'),
(20, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-05 13:08:18'),
(21, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-06 06:01:15'),
(22, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-06 06:02:16'),
(23, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-06 06:08:57'),
(24, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-06 06:09:47'),
(25, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-06 06:10:24'),
(26, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-06 06:10:56'),
(27, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-06 06:17:05'),
(28, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-06 06:20:07'),
(29, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-06 06:21:56'),
(30, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-06 06:24:01'),
(31, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-06 06:29:17'),
(32, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-06 06:33:11'),
(33, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-06 06:33:52'),
(34, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-06 06:34:13'),
(35, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-06 06:45:30'),
(36, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-23 19:28:03'),
(37, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-23 19:37:29'),
(38, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-23 19:45:34'),
(39, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-23 19:50:50'),
(40, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-23 20:04:19'),
(41, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-23 20:15:13'),
(42, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-23 20:17:40'),
(43, 'login_success', 'Mohamed Salah logged in successfully', 18, 'Mohamed Salah', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-24 09:20:58'),
(44, 'login_success', 'Mohamed Test logged in successfully', 19, 'Mohamed Test', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 09:23:50'),
(45, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:48:50'),
(46, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:49:24'),
(47, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 09:49:34'),
(48, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:50:07'),
(49, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:50:14'),
(50, 'reaccess_rejected', 'Re-access request rejected for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:50:36'),
(51, 'login_success', 'Sarah Kaci logged in successfully', 9, 'Sarah Kaci', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 09:50:55'),
(52, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:54:09'),
(53, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:54:52'),
(54, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:54:56'),
(55, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 09:55:50'),
(56, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:55:58'),
(57, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:56:06'),
(58, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:56:15'),
(59, 'login_success', 'Sarah Kaci logged in successfully', 9, 'Sarah Kaci', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 09:57:24'),
(60, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:57:59'),
(61, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 09:58:03'),
(62, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 09:58:10'),
(63, 'reaccess_rejected', 'Re-access request rejected for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 09:58:23'),
(64, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:04:49'),
(65, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:05:03'),
(66, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:05:09'),
(67, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 10:05:17'),
(68, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:07:46'),
(69, 'login_success', 'Sarah Kaci logged in successfully', 9, 'Sarah Kaci', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 10:08:03'),
(70, 'login_failed', 'Login attempt failed - user not found: sarah kacii', NULL, 'sarah kacii', NULL, NULL, NULL, '127.0.0.1', '2026-01-24 10:08:50'),
(71, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:08:54'),
(72, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:08:59'),
(73, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:09:03'),
(74, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 10:09:06'),
(75, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:13:03'),
(76, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:13:20'),
(77, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:13:29'),
(78, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 10:13:32'),
(79, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 10:13:43'),
(80, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:18:13'),
(81, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:18:18'),
(82, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:18:23'),
(83, 'reaccess_approved', 'Re-access request approved for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 10:18:26'),
(84, 'login_success', 'Sarah Kaci logged in successfully', 9, 'Sarah Kaci', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 10:18:58'),
(85, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:24:08'),
(86, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:25:05'),
(87, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:25:12'),
(88, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:25:33'),
(89, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:30:14'),
(90, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:33:29'),
(91, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:33:42'),
(92, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 10:33:51'),
(93, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 10:34:46'),
(94, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 11:01:58'),
(95, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 11:02:12'),
(96, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 11:03:05'),
(97, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 11:03:14'),
(98, 'reaccess_rejected', 'Re-access request rejected for patient: Sarah Kaci', 0, 'Admin', 'admin', 'patient', 3, '127.0.0.1', '2026-01-24 11:03:24'),
(99, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-24 11:03:40'),
(100, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:23:43'),
(101, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:30:51'),
(102, 'login_failed', 'Invalid password attempt for: Boughida Nazim', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:35:04'),
(103, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:35:11'),
(104, 'appointment_created', 'New appointment scheduled for Jan 27, 2026 10:45', NULL, NULL, NULL, 'appointment', 19, '127.0.0.1', '2026-01-24 11:36:44'),
(105, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 11:37:32'),
(106, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:38:40'),
(107, 'appointment_missed', 'Appointment marked as missed', NULL, NULL, NULL, 'appointment', 19, '127.0.0.1', '2026-01-24 11:39:02'),
(108, 'appointment_created', 'New appointment scheduled for Jan 27, 2026 07:00', NULL, NULL, NULL, 'appointment', 20, '127.0.0.1', '2026-01-24 11:41:27'),
(109, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:45:13'),
(110, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 11:50:13'),
(111, 'appointment_created', 'New appointment scheduled for Jan 27, 2026 07:00', NULL, NULL, NULL, 'appointment', 21, '127.0.0.1', '2026-01-24 11:54:30'),
(112, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 12:03:45'),
(113, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 22, '127.0.0.1', '2026-01-24 12:04:34'),
(114, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 12:15:21'),
(115, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-24 13:08:43'),
(116, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-24 13:10:57'),
(117, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 13:12:30'),
(118, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 13:17:25'),
(119, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 13:22:09'),
(120, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 15:40:05'),
(121, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 23, '127.0.0.1', '2026-01-24 15:40:18'),
(122, 'appointment_missed', 'Appointment marked as missed', NULL, NULL, NULL, 'appointment', 23, '127.0.0.1', '2026-01-24 15:40:22'),
(123, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 15:44:44'),
(124, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 24, '127.0.0.1', '2026-01-24 15:45:07'),
(125, 'appointment_missed', 'Appointment marked as missed', NULL, NULL, NULL, 'appointment', 24, '127.0.0.1', '2026-01-24 15:45:12'),
(126, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 15:53:25'),
(127, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 25, '127.0.0.1', '2026-01-24 15:53:35'),
(128, 'patient_restricted', 'Patient account restricted due to 3+ missed appointments: Ahmed Benali', NULL, NULL, NULL, 'patient', 2, '127.0.0.1', '2026-01-24 15:53:38'),
(129, 'appointment_missed', 'Appointment marked as missed', NULL, NULL, NULL, 'appointment', 25, '127.0.0.1', '2026-01-24 15:53:38'),
(130, 'appointment_created', 'New appointment scheduled for Jan 28, 2026 09:00', NULL, NULL, NULL, 'appointment', 26, '127.0.0.1', '2026-01-24 15:54:01'),
(131, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 27, '127.0.0.1', '2026-01-24 15:54:23'),
(132, 'appointment_missed', 'Appointment marked as missed', NULL, NULL, NULL, 'appointment', 27, '127.0.0.1', '2026-01-24 15:54:27'),
(133, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-24 15:58:19'),
(134, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 28, '127.0.0.1', '2026-01-24 15:58:34'),
(135, 'appointment_missed', 'Appointment marked as missed', NULL, NULL, NULL, 'appointment', 28, '127.0.0.1', '2026-01-24 15:58:37'),
(136, 'appointment_created', 'New appointment scheduled for Jan 25, 2026 09:00', NULL, NULL, NULL, 'appointment', 29, '127.0.0.1', '2026-01-24 15:59:16'),
(137, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 16:01:50'),
(138, 'login_restricted', 'Restricted patient login attempt: Ahmed Benali', 8, 'Ahmed Benali', 'patient', 'patient', 2, '127.0.0.1', '2026-01-24 16:02:26'),
(139, 'reaccess_submitted', 'Re-access request submitted by patient: Ahmed Benali', NULL, 'Ahmed Benali', 'patient', 'patient', 2, '127.0.0.1', '2026-01-24 16:02:52'),
(140, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-24 16:02:57'),
(141, 'reaccess_approved', 'Re-access request approved for patient: Ahmed Benali', 0, 'Admin', 'admin', 'patient', 2, '127.0.0.1', '2026-01-24 16:03:25'),
(142, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 16:03:51'),
(143, 'login_success', 'Karim Ziani logged in successfully', 10, 'Karim Ziani', 'patient', NULL, NULL, '127.0.0.1', '2026-01-24 16:04:29'),
(144, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-25 17:09:45'),
(145, 'appointment_created', 'New appointment scheduled for Jan 28, 2026 11:00', NULL, NULL, NULL, 'appointment', 30, '127.0.0.1', '2026-01-25 17:14:23'),
(146, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-25 21:38:17'),
(147, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-25 21:43:43'),
(148, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 01:42:51'),
(149, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 07:06:39'),
(150, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 12:01:53'),
(151, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 12:50:51'),
(152, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-26 12:54:52'),
(153, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-26 12:58:44'),
(154, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-26 14:27:21'),
(155, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-26 14:30:04'),
(156, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 21:17:35'),
(157, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-26 21:18:45'),
(158, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-26 21:22:03'),
(159, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 22:19:29'),
(160, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-26 22:37:46'),
(161, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 22:40:22'),
(162, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-26 22:42:52'),
(163, 'reaccess_submitted', 'Re-access request submitted by patient: Sarah Kaci', NULL, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-26 22:43:22'),
(164, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-01-26 22:43:29'),
(165, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-01-26 22:51:16'),
(166, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-26 23:18:48'),
(167, 'login_success', 'Boughida Nazim logged in successfully', 13, 'Boughida Nazim', 'nurse', NULL, NULL, '127.0.0.1', '2026-01-26 23:35:27'),
(168, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-01-26 23:40:54'),
(169, 'login_failed', 'Invalid password attempt for: Sarah Kaci', 9, 'Sarah Kaci', 'patient', NULL, NULL, '127.0.0.1', '2026-01-27 00:16:21'),
(170, 'login_restricted', 'Restricted patient login attempt: Sarah Kaci', 9, 'Sarah Kaci', 'patient', 'patient', 3, '127.0.0.1', '2026-01-27 00:16:29'),
(171, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-02-01 09:04:59'),
(172, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-02-01 09:09:35'),
(173, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-02-01 09:17:02'),
(174, 'appointment_created', 'New appointment scheduled for Feb 02, 2026 11:00', NULL, NULL, NULL, 'appointment', 31, '127.0.0.1', '2026-02-01 09:26:21'),
(175, 'appointment_created', 'New appointment scheduled for Feb 04, 2026 10:00', NULL, NULL, NULL, 'appointment', 32, '127.0.0.1', '2026-02-01 09:27:42'),
(176, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-02-01 09:29:02'),
(177, 'login_failed', 'Invalid password attempt for: Ahmed Benali', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-02-01 09:32:18'),
(178, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-02-01 09:33:01'),
(179, 'login_failed', 'Login attempt failed - user not found: Karim Ziani', NULL, 'Karim Ziani', NULL, NULL, NULL, '127.0.0.1', '2026-02-01 12:13:15'),
(180, 'login_success', 'Mohamed Test logged in successfully', 19, 'Mohamed Test', 'patient', NULL, NULL, '127.0.0.1', '2026-02-01 12:13:54'),
(181, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-02-01 12:14:43'),
(182, 'login_success', 'Administrator logged in successfully', 3, 'Administrator', 'admin', NULL, NULL, '127.0.0.1', '2026-02-01 12:25:03'),
(183, 'login_success', 'Mohamed Salah logged in successfully', 18, 'Mohamed Salah', 'nurse', NULL, NULL, '127.0.0.1', '2026-02-01 12:25:57'),
(184, 'login_success', 'Amri Baha Eddine logged in successfully', 12, 'Amri Baha Eddine', 'doctor', NULL, NULL, '127.0.0.1', '2026-02-01 12:26:30'),
(185, 'appointment_created', 'New appointment scheduled for Feb 04, 2026 00:10', NULL, NULL, NULL, 'appointment', 33, '127.0.0.1', '2026-02-01 12:29:25'),
(186, 'login_success', 'Ahmed Benali logged in successfully', 8, 'Ahmed Benali', 'patient', NULL, NULL, '127.0.0.1', '2026-02-01 12:31:32'),
(187, 'login_success', 'Boughida Nazim logged in successfully', 11, 'Boughida Nazim', 'doctor', NULL, NULL, '127.0.0.1', '2026-02-01 12:33:35');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','doctor','nurse','patient') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `role`, `created_at`, `updated_at`, `is_active`) VALUES
(3, 'admin', '$2y$10$J/hC/3gzJeCwgVV9qu5QpeoyYLv732T6U/NKWxN2CRHzFq.S.alnq', 'admin', '2025-12-21 20:49:49', '2025-12-21 21:34:55', 1),
(8, 'patient1', '$2y$10$l5TbuRJn75o1jn5G7BvFBuDaK0L.0Ixj2BKAi4P13T0bgnGoBJLQ6', 'patient', '2025-12-22 02:23:00', '2026-01-24 13:11:40', 1),
(9, 'patient2', '$2y$10$F2sXVrVtK1JzrtCVlFqpAOKNYJ/.xDTqMes3SWNkvevHgRJDLhoge', 'patient', '2025-12-22 02:23:00', '2025-12-22 02:23:00', 1),
(10, 'patient3', '$2y$10$Ky0T5qom/STwF1NxuHMnP../yJzmWPRAezvXzWQZuQoV3sG560TdC', 'patient', '2025-12-22 02:23:00', '2025-12-22 02:23:00', 1),
(11, 'Nazimdoc1', '$2y$10$y9LJ/rPseSbf5/Sf7a/iCeXqXpl6yxCqTI.dJP4KPyYIwfNTyFKjy', 'doctor', '2025-12-22 02:42:43', '2025-12-22 02:42:43', 1),
(12, 'Bahadoc2', '$2y$10$Yuqk6XH5aD15clRTJ9oBdO1bp6YrSgpEjmXF.U5Rarl/guj7ij7.u', 'doctor', '2025-12-22 02:44:21', '2025-12-22 02:45:12', 1),
(13, 'Nazimnurse1', '$2y$10$54GIHC/eXCWfcazteDxT0.9vgbhOJb23h6W820NZnibBI9YM9glTu', 'nurse', '2025-12-22 02:46:59', '2025-12-22 02:46:59', 1),
(14, 'Bahanurse2', '$2y$10$B.YU9z.hiGmUDLHWXP3Nn.fTs3DxaR/DLqYCbfQMdbCULWGVBAU5G', 'nurse', '2025-12-22 02:48:03', '2025-12-22 02:48:03', 1),
(16, '123456789', '$2y$10$.KgxNcfpKeRhYXgJpOA/q.rO9xD3CMoGi95QkwflQszUwt9E3Xtn6', 'patient', '2025-12-27 01:59:43', '2025-12-27 01:59:43', 1),
(17, 'TestDoctor', '$2y$10$xaBxQV59gN4f7K9AHrXW2uSjIn5tSzP14i79UCfSpY43pgpCj5DVe', 'doctor', '2026-01-23 19:56:59', '2026-01-23 19:57:43', 1),
(18, 'TestNurse', '$2y$10$XvsM8NquY7wanTibgzyPRueAph8861ZGLi23s3ahfY.0JD.CTXzyy', 'nurse', '2026-01-23 19:58:53', '2026-01-23 19:58:53', 1),
(19, '1234567890', '$2y$10$yJ6nAAmcHWIIY5zHD4/uvuUqr5KWN6Ukjj.nIQUYvvEQlBmG/dV46', 'patient', '2026-01-24 09:23:10', '2026-01-24 09:23:10', 1),
(20, 'chaithdoc3', '$2y$10$gvWAv0cjrsl4x39sbruOru4MelE0s/eQ.WybTve3qr6VlC39OS3nm', 'doctor', '2026-01-26 12:02:54', '2026-01-26 12:02:54', 1),
(21, 'Ahmeddoc6', '$2y$10$lq6Te3kvI67zMYny1HY1be7/fyDaALV0graiCv4vkmmL0UDcCnke6', 'doctor', '2026-02-01 09:10:43', '2026-02-01 09:10:43', 1),
(22, 'Meryemnurse6', '$2y$10$/eSm4/CYQ/jOEDDnD5M1b.WbUY4VMDjFV1lrrlDiRJs6NTh370Qn2', 'nurse', '2026-02-01 09:12:19', '2026-02-01 09:12:19', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`appointment_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `doctor_id` (`doctor_id`);

--
-- Indexes for table `consultations`
--
ALTER TABLE `consultations`
  ADD PRIMARY KEY (`consultation_id`),
  ADD KEY `appointment_id` (`appointment_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `doctor_id` (`doctor_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`department_id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `doctors`
--
ALTER TABLE `doctors`
  ADD PRIMARY KEY (`doctor_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `specialty_id` (`specialty_id`);

--
-- Indexes for table `lab_results`
--
ALTER TABLE `lab_results`
  ADD PRIMARY KEY (`result_id`),
  ADD KEY `consultation_id` (`consultation_id`);

--
-- Indexes for table `nurses`
--
ALTER TABLE `nurses`
  ADD PRIMARY KEY (`nurse_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
  ADD PRIMARY KEY (`patient_id`),
  ADD UNIQUE KEY `national_id` (`national_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `prescriptions`
--
ALTER TABLE `prescriptions`
  ADD PRIMARY KEY (`prescription_id`),
  ADD KEY `consultation_id` (`consultation_id`);

--
-- Indexes for table `reaccess_requests`
--
ALTER TABLE `reaccess_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `re_access_requests`
--
ALTER TABLE `re_access_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `specialties`
--
ALTER TABLE `specialties`
  ADD PRIMARY KEY (`specialty_id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `system_logs`
--
ALTER TABLE `system_logs`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `appointment_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `consultations`
--
ALTER TABLE `consultations`
  MODIFY `consultation_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `department_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `doctors`
--
ALTER TABLE `doctors`
  MODIFY `doctor_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `lab_results`
--
ALTER TABLE `lab_results`
  MODIFY `result_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `nurses`
--
ALTER TABLE `nurses`
  MODIFY `nurse_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `patients`
--
ALTER TABLE `patients`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `prescriptions`
--
ALTER TABLE `prescriptions`
  MODIFY `prescription_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `reaccess_requests`
--
ALTER TABLE `reaccess_requests`
  MODIFY `request_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `re_access_requests`
--
ALTER TABLE `re_access_requests`
  MODIFY `request_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `specialties`
--
ALTER TABLE `specialties`
  MODIFY `specialty_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `system_logs`
--
ALTER TABLE `system_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=188;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `appointments_ibfk_2` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE CASCADE;

--
-- Constraints for table `consultations`
--
ALTER TABLE `consultations`
  ADD CONSTRAINT `consultations_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `consultations_ibfk_2` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `consultations_ibfk_3` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE CASCADE;

--
-- Constraints for table `doctors`
--
ALTER TABLE `doctors`
  ADD CONSTRAINT `doctors_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `doctors_ibfk_2` FOREIGN KEY (`specialty_id`) REFERENCES `specialties` (`specialty_id`);

--
-- Constraints for table `lab_results`
--
ALTER TABLE `lab_results`
  ADD CONSTRAINT `lab_results_ibfk_1` FOREIGN KEY (`consultation_id`) REFERENCES `consultations` (`consultation_id`) ON DELETE CASCADE;

--
-- Constraints for table `nurses`
--
ALTER TABLE `nurses`
  ADD CONSTRAINT `nurses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `nurses_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);

--
-- Constraints for table `patients`
--
ALTER TABLE `patients`
  ADD CONSTRAINT `patients_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `prescriptions`
--
ALTER TABLE `prescriptions`
  ADD CONSTRAINT `prescriptions_ibfk_1` FOREIGN KEY (`consultation_id`) REFERENCES `consultations` (`consultation_id`) ON DELETE CASCADE;

--
-- Constraints for table `reaccess_requests`
--
ALTER TABLE `reaccess_requests`
  ADD CONSTRAINT `reaccess_requests_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE;

--
-- Constraints for table `re_access_requests`
--
ALTER TABLE `re_access_requests`
  ADD CONSTRAINT `re_access_requests_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
