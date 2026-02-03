


## Project Report








-In this day and age, computer science has become integral in our daily lives, it has
shaped how we communicate, access information, and connect with the rest of the
world. In healthcare, it has become a powerful tool for solving operational
challenges, one of the most critical being medical record management, which has
become increasingly crucial thanks to the ever-increasing number of patients, the
increase in the number of big hospitals and their staff (doctors, nurses, managers...).
Effective medical record management would help hospitals maintain up to date and
accurate patient records, ensuring smooth running and operation. Lack of proper
record management would cause delays, leading to frustration from patients and
staff.

-Thus, it has become necessary to adopt and implement a National Digital Medical
Record Management System, this system aims to store, manage, and share patient
health records across all hospitals in the country, organizing and streamlining the
process while enabling tracking and updating of patient records and such as
diagnoses, treatments, prescriptions, lab results, appointments, and more, saving
valuable time and providing better healthcare for citizens

Currently, in most hospitals and clinics, patient medical records are still managed
using legacy methods such as paper files and spreadsheets, these old methods lack
the ability to easily update information in real time, and the lack of centralization,
creating significant issues such as:

- Duplicated records: without a centralized system, different hospitals can
have duplicated records of the same person, leading to inconsistencies that
can lead to different information in different hospitals (for example the patient
record gets updated in a hospital but doesn’t get updated in another hospital).

- Difficulty in updating information: difficulties in updating information can
lead to update delays which may make it difficult to get the latest information
of the patient (for example the doctor can’t get the latest lab results of his
patient)

- Difficulties for the patient to check his record: the lack of a record
management system makes it hard for the patient to view his latest medical
information.


- No ability to track appointments: Without a proper appointment tracking, it
becomes hard for the doctors with a lot of patients to track how many
appointments their patients missed which might cause mistakes, we also can’t
implement exclusion automation when a patient misses multiple appointments
## .



In order to answer the mentioned problems, we have set the following objectives for
our project:

- Provide a patient registry interface for administrative nurse: create an
interface where the administrative nurse can register patients in the system by
creating a new medical profile that contains their personal details.

- allow doctors to update medical records: by creating an interface where
the doctor can access a patient’s record and continuously update it with new
medical information (diagnosis, treatments...),  the doctor would also be able
to record whether the patient attended each appointment or not.

- allow patients to view their medical records: by creating a patient interface
where a patient can securely login using his full name and national id number
and view their personal medical information.

- Allow system admin to manage doctors and administrative nurses:
create a system admin interface, where the system admin manages doctors
and admin nurses, (accept/reject their registration to the system, deletes their
accounts...), he can also view latest updates and logs in the system (last
patient added one minute ago, last doctor accepted 5 minutes ago...), and
more

- Integrate an automated exclusion mechanism: integrate a mechanism into
the system that automatically flags patients who missed three consecutive
scheduled appointments and restricts their access until the issue is resolved.

There are four actors in our National Medical Record Management System:



- System Administrator: Can Manage doctors and administrative nurses, he
can accept or reject their registration, manage their accounts (delete, update
information...), view update logs, and more.

- Administrative Nurse: Handles the creation of patients’ medical records,
when a patient visits a hospital for the first time, the administrative nurse
registers them in they system by creating their medical profile that contains
their personal details.

- Doctor: Can access the medical records of his patients, he can view their
records and continuously update them with new medical information
(diagnoses, treatments, prescriptions, lab results), he can also manage
appointments and record whether the patient attended each appointment or
not.

- Patient: Can access and view their medical information (visit history,
prescriptions, examination results, scheduled appointments), and account
status, by logging into the platform using their full name and national id
number
## Administrative Nurse:

-Register new patients into the system and create their medical profile when they
visit the hospital for the first time.

-Search for patients in the database using national ID or full name.

-Send registration request to the system admin to accept/reject.

-login into the system using information

## Doctor:

-Access medical records of his patients.

-Search for his patients in the database.


-Update medical record (add/modify/delete diagnoses, treatments, prescriptions, lab
results)

-Manage appointments by creating/modifying/deleting appointments and recording
whether the patient attended an appointment or not.

-Send registration request to the system admin to accept/reject.

-Login into the system using his information.

## Patient:

-Get registered in the system by the administrative nurse.

-Securely Login in the website using national ID and full name and.

-View Medical Record (visit history, prescriptions, examination results, and
scheduled appointments

-View status of account (if access is restricted or not)

## System Administrator:


## System:


- Performance: There needs be very delay when accessing/updating
information (less than 3 seconds), and it should handle lots of operations at
once since it’s a national system.

- Availability: The system must be operational 99% of times and only stopped
maintenance.

- Maintainability: It must be easily maintained and updated with new features.

- Security: The system needs to include different user roles to restrict data
access, and securely authenticate patients, administrative nurses, and
doctors.

- Scalability: The system needs to handle big growth in the number of users to
avoid performance issues.

- Portability: it has to run on multiple devices and operating systems to ensure
consistent access.

- Ergonomics: The system must have an understandable easy to use interface
that is responsive to handle multiple screen sizes.

- Compliance: The system must be compliant with local rules in order to be
used in public hospitals and clinics.















Use Case Name:  Access and update patient medical records.

-Main Actors: Doctor
-Secondary Actor: System

-Description / Goal: The goal of the use case is to allow an authenticated doctor to
select a patient and access and update his medical records.

## Preconditions:
-Doctor must be registered in the system by the System Admin.
-Doctor must be logged in.
-Registered patients with medical records must exist.

-Scenario Start: The use case begins when a doctor that is logged in selects a
patient from the list of patients and clicks on his profile to view his medical record, or
click the edit button to update his medical records.

## Main Flow:
1-System displays the patient search interface.
2-Doctor searches for patient using patient ID and name.
3-System displays matching patients.
4-Doctor selects desired patient.
5-System opens a new window showing the medical record of the patient.
6-Doctor clicks on the edit button.
7-System displays edit form and doctor edits and adds new information.
8-Doctor clicks on the update button to save and update information.
9-System validates form and saves modifications in the database.
10-System displays popup message confirming the success of the update.




## Alternative Flow:
A1: No matching patient found:
Starts after step 3
1-System finds no matching patients.
2-Display message “no matching patient found’’
3-Doctor re-enters data.
4-Main flow resumes at step 3
A2: Update canceled by the doctor:
Starts after step 7.
1-Doctor clicks on the cancel button.
2-System returns to current record that is saved on the database.
3-Main flow resumes at step 3.

## Exception Flows:
E1: Validation errors:
Starts after step 8
1-System detects validation error (mandatory field missing, incorrect format...)
2-Display error message highlighting the fields with problems.
3-Doctor corrects data and resubmits form.
4-Main flow resumes at step 8

## Postconditions:
-Patient medical record is updated with the new/modified information.

Non – Functional constraints:
-System must operate 24/7
-Storage must be encrypted to protect data.

HMI constraints: Display confirmation message with a summary of changes.

Use Case Name:  Manage patient information (Add, Update, Delete).

-Main Actors: Administrative Nurse
-Secondary Actor: System

-Description / Goal: The goal of the use case is to allow an authenticated
administrative nurse to manage patients, create new patient accounts, delete old
patients, and update information of existing patients

## Preconditions:
-Administrative nurse must be registered in the system by the System Admin.
-Administrative nurse must be logged in.

-Scenario Start: The use case begins when a administrative nurse that is logged in
selects the option in the menu “Manage patients”

## Main Flow:
1-System displays the patient management interface.
2-Nurse chooses “search patient”.
3-Nurse searches for patient using patient ID and name.
4-System displays matching patients.
5-Nurse selects desired patient.
6-System opens a new window showing patient information (id, contact details,
name...)
7-Nurse clicks on the edit button.
8-System displays edit form and nurse edits information.
9-Nurse clicks on the update button to save and update information.
10-System validates form and saves modifications in the database.
11-System displays popup message confirming the success of the update.




## Alternative Flow:
A1: Add a new patient:
Starts after step 1
1-Nurse selects “Add New Patient
2-System displays empty patient profile creation form
3-Nurse fills form with data.
4-Systems validates form.
5-System creates new patient in the database.
6-System displays confirmation message.
7-Main flow resumes at step 1.
## A2: Delete Patient:
Starts after step 6
1-Nurse clicks on the delete button
2-The system shows a delete confirmation dialog
3-Patient gets deleted from the database.
4-Main flow resumes at step 1.

A3: No matching patient found:
Starts after step 3
1-System finds no matching patients.
2-Display message “no matching patient found’’
3-Nurse re-enters data.
4-Main flow resumes at step 3

A4: Update canceled by the nurse:
Starts after step 7.
1-Nurse clicks on the cancel button.
2-System returns to current record that is saved on the database.
3-Main flow resumes at step 6.


## Exception Flows:
E1: Validation erros:
Starts after step 9
1-System detects validation error (mandatory field missing, incorrect format...)
2-Display error message highlighting the fields with problems.
3-Nurse corrects data and resubmits form.
4-Main flow resumes at step 9.

## Postconditions:
-Patient information is updated with the new/modified information.
-Old Patient gets deleted.
-New patient gets added

Non – Functional constraints:
-Log all create, delete, and edit operations with timestamps, changed fields...
-System must operate 24/7
-Storage must be encrypted to protect data.

HMI constraints:
-Clearly differentiate between add patient , delete patient, and edit patient buttons to
avoid mistakes.
-Display confirmation message with a summary of changes.






## Use Case Name:  Manage Doctors Accounts

-Main Actors: System Administrator

-Secondary Actor: System

-Description / Goal: The goal of the use case is to allow an authenticated system
admin to register new doctors, manage and update their details, and delete their
accounts.

## Preconditions:
-System Administrator must have an existing account (created in the database by
developer).
-System Administrator must be logged in

-Scenario Start: The use case begins when a system administrator that is logged in
selects the option in the menu “Manage Doctors”

## Main Flow:
1-System displays the Doctors management interface with a list of registered
doctors.
2-System Admin clicks on the “Search Doctors” button.
3-System Admin searches for Doctor using his ID or name.
4-System displays matching doctors.
5-System Admin chooses a doctor.
6-System opens a new window showing Doctor information (id, contact details,
name...)
7-System Admin clicks on the edit button.
8-System displays edit form and Admin edits information.
9-Admin clicks on the update button to save and update information.
10-System validates form and saves modifications in the database.
11-System displays popup message confirming the success of the update.



## Alternative Flow:

A1: Add a new Doctor:
Starts after step 1
1-Admin clicks on the “Add New Doctor” button.
2-System displays the add new Doctor form.
3-Admin fills form with data.
4-Systems validates form.
5-System creates new Doctor in the database.
6-System displays confirmation message.
7-Main flow resumes at step 1.
## A2: Delete Doctor:
Starts after step 6
1-Admin clicks on the delete button
2-The system shows a delete confirmation dialog
3-Doctor gets deleted from the database.
4-Main flow resumes at step 1.

A3: No matching Doctor found:
Starts after step 3
1-System finds no matching doctors.
2-Display message “no matching doctor found’’
3-Doctor re-enters data.
4-Main flow resumes at step 3

A4: Update canceled by the System Admin:
Starts after step 7.
1-System Admin clicks on the cancel button.
2-System returns to current record that is saved on the database.
3-Main flow resumes at step 6.

## Exception Flows:

E1: Validation erros:
Starts after step 9
1-System detects validation error (mandatory field missing, incorrect format...)
2-Display error message highlighting the fields with problems.
3-System Admin corrects data and resubmits form.
4-Main flow resumes at step 9.

## Postconditions:
-Doctor information is updated with the new/modified information.
-Old Doctor gets deleted.
-New Doctor gets added

Non – Functional constraints:
-Log all create, delete, and edit operations with timestamps, changed fields...
-System must operate 24/7.
-Storage must be encrypted to protect data (the type of information is critical and
must be protected).

HMI constraints:
-Clearly differentiate between add Doctor, delete Doctor, and edit Doctor buttons to
avoid mistakes.
-Display confirmation message with a summary of changes.


## Use Case Name:  Manage Nurses Accounts

-Main Actors: System Administrator
-Secondary Actor: System

-Description / Goal: The goal of the use case is to allow an authenticated system
admin to register new nurses, and manage and update their details, he can also
delete their accounts.


## Preconditions:
-System Administrator must have an existing account (created in the database by
developer).
-System Administrator must be logged in

-Scenario Start: The use case begins when a system administrator that is logged in
selects the option in the menu “Manage Nurses”

## Main Flow:
1-System displays the Nurses management interface with a list of registered Nurses.
2-System Admin clicks on the “Search Nurses” button.
3-System Admin searches for Nurses using their ID or name.
4-System displays matching Nurses.
5-System Admin chooses a Nurse.
6-System opens a new window showing Nurse information (id, contact details,
name...)
7-System Admin clicks on the edit button.
8-System displays edit form and Admin edits information.
9-Admin clicks on the update button to save and update information.
10-System validates form and saves modifications in the database.
11-System displays popup message confirming the success of the update.



## Alternative Flow:
A1: Add a new Nurse:
Starts after step 1
1-Admin clicks on the “Add New Nurse” button.
2-System displays the add new Nurse form.
3-Admin fills form with data.

4-Systems validates form.
5-System creates new Nurse in the database.
6-System displays confirmation message.
7-Main flow resumes at step 1.
## A2: Delete Nurse:
Starts after step 6
1-Admin clicks on the delete button
2-The system shows a delete confirmation dialog
3-Nurse gets deleted from the database.
4-Main flow resumes at step 1.

A3: No matching Nurse found:
Starts after step 3
1-System finds no matching Nurses.
2-Display message “no matching Nurse found’’
3-System Admin re-enters data.
4-Main flow resumes at step 3

A4: Update canceled by the System Admin:
Starts after step 7.
1-System Admin clicks on the cancel button.
2-System returns to current record that is saved on the database.
3-Main flow resumes at step 6.





## Exception Flows:
E1: Validation erros:

Starts after step 9
1-System detects validation error (mandatory field missing, incorrect format...)
2-Display error message highlighting the fields with problems.
3-System Admin corrects data and resubmits form.
4-Main flow resumes at step 9.

## Postconditions:
-Nurse information is updated with the new/modified information.
-Old Nurse gets deleted.
-New Nurse gets added.

Non – Functional constraints:
-Log all create, delete, and edit operations with timestamps, changed fields...
-System must operate 24/7.
-Storage must be encrypted to protect data (the type of information is critical and
must be protected).

HMI constraints:
-Clearly differentiate between add Nurse, delete Nurse, and edit Nurse buttons to
avoid mistakes.
-Display confirmation message with a summary of changes.












Use Case Name:  Request re-access

-Main Actors: Patient
-Secondary Actor: System admin

-Description / Goal: allowing the patient to regain access to the system after
missing some scheduled sessions

## Preconditions:
-The patient must be already registered in the system.

-The patient must miss some of his scheduled sessions

-Scenario Start: A patient misses their appointment, the system automatically marks
the patient as missing appointments and restricts his access to the system ,when the
patient tries to login in it informs him that access is denied and must fill re-access
form to the system, once done the system validates it and restores the patient
account.

## Main Flow:
1- Patient logs into the system.
2- System checks the patient appointment history.

3- System detect it as restricted account.

4- System blocks access to all features.

5- System displays a message informing that the account is restricted due to missed
appointments.

6- Patient clicks re-access and fills his information.

7- Patient submits the re-access request.

8- System admin checks and validates the information and unlocks the patient
account.

9-Patient can fully-access the system again


## Alternative Flow:
A1: Patient refuses the re-access:
Starts after step 6
1-Patient closes the re-access form.

2-System keeps the account restricted.

3-Patient closes the login interface.

A2: System admin refuses the re-access:
start after step 8

1-Patient submits the re access form.
2- System admin checks the information, finds an issue and refuses the re-access
request.
3- System displays a message saying “re-access request refused, please try again”.
4- System returns the patient to the form page.
5- Patient corrects the data and resubmits the form.

## Exception Flows:
E1: Required fields missing:
Starts after step 7
1-System detect an error (missing field).

2_System highlights the fields with problem.

3-Patient corrects data and resubmits form.

E2: System internal error:
1-System displays “re-access failed due to internal error, try again later.

2-System kicks the patient from the page

E3: Patient account already unlocked:
1-System displays “patient account is already unlocked”.
2- System takes the patient back the login page.



## Postconditions:
-System unlocks the patient account.

-Re-access form is stored in the system database.

-System keeps the patient restricted if the form is refused or incomplete.

Non – Functional constraints:
-system ensures that only authorized patients can access the re-access form.

-re-access form should load in a short time.

-system must be available for 24/7.

-system must maintain no data loss during submission.

HMI constraints:
-The re-access restriction message must appear immediately after login.

-Patient cannot navigate to any page except the re-access form.





















## Use Case Name:  View Consultations History

-Main Actors: Patient.
-Secondary Actor: System.

-Description / Goal: allow the patient to view his past consultations (dates, doctors,
diagnoses, treatments, notes).

## Preconditions:
- Patient must be authenticated and has an active account.

-Consultation history exists in the system.


-Scenario Start: the patient logs into to the system and accesses their personal
consultation history, he can choose to view any consultation details such as
diagnosis, doctor notes and treatments.

## Main Flow:
1-Patient logs into the system.

2-Patient selects  “view consultation history”.

3-System retrieves and sorts all consultation records linked to the patient.

4-Patient clicks on a specific consultation.

5-System displays the detailed info (date and time , doctor , diagnosis , notes ,
treatments).

6-Patient closes the details and exits the consultation page.






## Alternative Flow:
A1: No consultation history exists:
Starts after step 3.

1-System retrieves empty results.

2-System displays message saying:”no consultation history”.

A2: Patient filters consultations:
Starts after step 3

1-Patient selects filter based on date, range, doctor, type.

2-System re-filters history.

3-System displays the new results based on the filter.

4-Patient continues from main flow step 4.

A3: Patient sorts the list of consultations:
Starts after step 3:

1-Patient chooses sorting option.

2-System re-sorts the results.

3-System updates the lists.

## Exception Flows:
E1: System cannot retrieve records (database error):
Starts after step 2
1- Patient tries to view consultation history.
2- System cannot retrieve consultations and displays message saying “unable to
load consultations history, please try again later”.





E2: Patient not authenticated:
Starts after step 2
1-Patient stays idle more than 15min.
2-System detect it and send the patient to the login page.

## E3: Invalid Dates:
1-Patient puts invalid dates to filter.
2-System display message saying “invalid date to filter”.


## Postconditions:
-Consultation records are successfully displayed to the patient.

-The patient views detailed data for consultations.

Non – Functional constraints:
-Only authenticated patients may view their own consultation history.

-No access to other patients data.

-The consultation history must be available for  24/7.

-Listing and sorting must be easy and accurate.

HMI constraints:
-Each consultation entry must show date, doctor, speciality ...














## Use Case Name:  View Personal Medical Records

-Main Actors: Patient.
-Secondary Actor: System.

-Description / Goal: Allow a patient to view their personal medical records
(diagnoses, allergies, lab results, prescriptions, medical history...)

## Preconditions:
- Patient must be authenticated and has an active account.

-Personal medical record must exist in the system.


-Scenario Start: The patient logs into the hospital system and selects “View
Personal Medical Records” from the menu. The system retrieves all medical data
linked to the patient, such as chronic conditions, lab results, allergies, treatments,
and medical history... The patient can browse through sections or open detailed
items such as lab reports or prescriptions.


## Main Flow:
1- Patient logs into the system.

2- Patient selects “View Personal Medical Records”.

3-System retrieves all medical records associated with the patient.

4- System categorizes the data (e.g., Conditions, Allergies, Lab Results,
## Prescriptions).

5- Patient selects a category (e.g., Lab Results).

6- System displays the list of records within that category.

7- Patient selects a specific record (blood test result, diagnosis result...).

8- System displays detailed medical information.
9- Patient closes the details or selects another category.
## Alternative Flow:
A1: No medical records available:
Starts after step 2.

1-System finds no records for the patient
2-System displays: “No medical records available.”

A2: Patient filters the search:
Starts after step 5

1- Patient searches for a specific record (e.g., “2023 lab report”).

2-Patient chooses filter based on date, range, record type, doctor...

3-System displays filtered results.

4-Use case continues from Main Flow step 6.

## Exception Flows:
E1: Patient stays idle:
1-System detects expired session.
2-Redirects patient to login page.
E2: Database error:
1- Medical records cannot be loaded due to system error.
2- System displays a message saying: “Unable to load medical records. Please try
again later.”

E3: Invalid filter input:
1-Patient enters invalid input to filter(date , range...).
2-System system shows an error message.
3-Patient corrects the input.





## Postconditions:
- Data displayed remains unchanged (patient has no access to change it (read-only))

-Patient successfully views their medical record.

Non – Functional constraints:
-Medical records must be encrypted.

-Medical record page must load quickly.

HMI constraints:
-Detailed record must be readable and printable.

-Scrolling must be smooth and mobile must be supported.



























Use Case Name:  Login to the system

-Main Actors: Patient, Doctor, Administrative Nurse, System Administrator
-Secondary Actor: System.

-Description / Goal: The main goal is to  allow all registered to authenticate and
access their interfaces and functionalities within the system.

## Preconditions:
- The users must be registered into the system.

-The user must have valid credentials (Name and ID for patients, username and
password for doctors, system admin and administrative nurses).

-Scenario Start: The use case begins when the user opens the application and is
greeted with the login interface.


## Main Flow:

1-System displays login interface with role selection.

2-User selects his role (Patient or staff (doctor, system admin, and administrative
nurse).

3-User enters credentials on the form displayed (name and national ID for patient,
username and password for staff).

4-System validates credentials and checks account status for patient login (Active or
restricted).

5-System grants access and redirects user to his homepage according to his role.




## Alternative Flow:
A1: Patient account is restricted:
Starts after step 3.

1-System detects that the patient account is marked as “restricted” from missing
appointments.

2-System displays a specific error message: "Account restricted due to missed
appointments. Please request re-access”.

3-User clicks on the “request re-access” button.

## Exception Flows:
E1: Invalid/Wrong credentials:
Starts after step 3
1-System cannot match the credentials with the credentials saved in the database.
2-System displays error message: "Invalid credentials, please try again.".
3-User refills form and re-submits.
E2: Database error:
1- System cannot connect to the database to verify users.
2- System displays a message saying: "Service unavailable, please try again later."

## Postconditions:
- User is logged in to the system and is shown his interface according to his role

-User session begins.

Non – Functional constraints:
-Passwords must hashed.

-Login process should be fast.

-Lock the ability to login for 15 minutes after many failed attemps.

HMI constraints:
-Passwords should be hidden when typing them (dots).


Use Case Name:  Create/Modify/Delete consultations

-Main Actors: Doctor.
-Secondary Actor: System.

-Description / Goal: The main goal of the use case is to allow a registered doctor to
manage medical consultation records for a specific patient.

## Preconditions:
- Doctor must be registered and logged into the system.

-Patients of the doctor must exist in the system.

-Scenario Start: The use case begins when doctor is in a patient’s profile and clicks
on the “add consultation” button or clicks on an existing consultation and clicks “edit
consultation” or “delete consultation”.

## Main Flow:

1-System displays the consultation management interface.

2-Doctor clicks on “search patient” button

3-Doctor searches for patient using patient ID and name

4-System displays matching patient.

5-Doctor clicks on the desired patient.

6-System opens a new window showing the consultation history of the patient

7-Doctors clicks on the “add consultation” button.

8-Doctor enters consultation details (diagnosis, prescriptions, symptoms...).

9-Doctor clicks on the “save consultation” button.


10-System validates mandatory fields and saves the consultation record in the
patient history.

11-System displays message: “Consultation added successfully”.

## Alternative Flow:
A1: Edit a consultation:
Starts after step 6.

1-Doctor clicks on an existing consultation and clicks on the “edit consultation”
button.

2-System Displays an edit consultation form and doctor edits the consultation
information.

3-Doctor clicks on the “save consultation” button.

4-System validates mandatory fields and saves the edits of the consultation.

5-System displays message: “Consultation edited successfully”.

A2: Delete a consultation:
Starts after step 6.

1-Doctor clicks on an existing consultation and clicks on the “delete consultation”
button.

2-System displays message: "Are you sure you want to delete this consultation?"

3-Doctor clicks on the “confirm” button.

4-System removes the consultation from the database.

5-System displays message “Consultation deleted successfully”.







A3: Create an appointment (extension):
Starts after step 6.

1-Doctor clicks on the “Create new appointment” button.

2-System executes appointment creation logic.

3-Resume main flow at step 1


## Exception Flows:

E1: Validation errors:
Starts after step 9
1-System detects validation error (mandatory field missing, incorrect format...)
2-Display error message highlighting the fields with problems.
3-Doctor corrects data and resubmits form.
4-Main flow resumes at step 10.

## Postconditions:
- New consultation is added.
- Old consultation is edited.
- Old consultation is deleted.

Non – Functional constraints:
-Patient data must be secure and encrypted.

-System must be up 24/7 (Except for maintenance).

HMI constraints:
-Add consultation, edit consultation and delete consultation buttons must be clearly
visible to prevent accidents.

-Interface must be understandable and easy to navigate





Use Case Name:  Create appointment

-Main Actors: Doctor.
-Secondary Actor: System.

-Description / Goal: The main goal of the use case is to allow a doctor to schedule
a future appointment for his patient.
## Preconditions:
- Doctor must be registered and logged into the system.

-Patient of the doctor and patient record must exist in the system.

-Scenario Start: This use case extends the "Create/Modify/Delete Consultations", it
starts when a doctor clicks on the “Create new appointment” button.

## Main Flow:

1-System displays the appointment scheduler interface and displays a schedule
calendar.

2-Doctor clicks on the “Create new appointment” button.

3-Doctors selects a date and time for the visit.

4-Doctor enters appointment description (reason for visit (follow-up, lab review...)).

5-Doctor clicks on the “Confirm Appointment” button.

6-System checks if the chosen time slot is available or not, and also checks if
information is valid.

7-System adds appointment.

8-System displays message: “appointment scheduled successfully”.









## Alternative Flow:
A1: Selected slot is taken:
Starts after step 6.

1-System detects that slot is taken by another appointment

2-System displays message: "The chosen time slot is not available, please choose
another time."

3-Doctor changes time slot and clicks “Confirm appointment”

4-Main flow resumes at step 6.

A2: Delete an appointment:
Starts after step 1.

1-Doctor clicks on an existing appointment and clicks on the “delete appointment”
button.

2-System displays message: "Are you sure you want to delete this appointment?"

3-Doctor clicks on the “confirm” button.

4-System removes the appointment.

5-System displays message “Appointment deleted successfully”.

A3: Edit an appointment:
Starts after step 1.

1-Doctor clicks on an existing appointment and clicks on the “edit appointment”
button.

2-System Displays an edit appointment form and doctor edits the appointment
information and time slot.

3-Doctor clicks on the “save appointment” button.


4-System validates mandatory fields and saves the edits of the appointment.

5-System displays message: “appointment edited successfully”.

## Exception Flows:

E1: Validation errors:
Starts after step 5
1-System detects validation error (mandatory field missing, incorrect format...)
2-Display error message highlighting the fields with problems.
3-Doctor corrects info and resubmits form.
4-Main flow resumes at step 5.

## Postconditions:
- New appointment is added.
- Old appointment is edited.
- Old appointment is deleted.

Non – Functional constraints:
-Patient data must be secure and encrypted.

-System must be up 24/7 (Except for maintenance).

HMI constraints:
-Add appointment, edit appointment and delete appointment buttons must be clearly
visible to prevent accidents.

-Interface must be understandable and easy to navigate

-Unavailable slots should be greyed out.









## Use Case Name: View Scheduled Appointments

-Main Actors: Patient.
-Secondary Actor: System.

-Description / Goal: The main goal of the use case is to allow an authenticated
patient to view their upcoming scheduled appointments so they don’t miss them.
## Preconditions:
-Patient must be registered and logged into the system.

-Patient account must be active and not restricted.

-Scenario Start: The use case begins when the patient clicks on the "View
Scheduled Appointments" button.

## Main Flow:

1-Patient logs into the system.

2-Patient clicks on “view scheduled appointments” button.

3-System displays scheduled appointments interface and retrieves and sorts all
scheduled appointments linked to the patient (sort by date).

4-Patient clicks on a specific appointment.

5-System displays appointment details (date and time, doctor, appointment
reason...).

6-Patient closes the details and exits the scheduled appointments page

## Alternative Flow:
A1: View Past appointments:
Starts after step 3.

1-Patient clicks on the “past appointments” button.

2-System displays past appointments (appointments before the today date).

3-System displays appointment status (attended, missed, or cancelled).

4-Main flow resumes at step 4.

A2: No upcoming appointments found:
Starts after step 1.

1-System finds no upcoming scheduled appointments for the patient in the database.

2-System displays message: "You have no scheduled appointments"

## Exception Flows:

E1: Database error:
Starts after step 1
1-System fails to connect to the database and retrieve the scheduled appointments.
2-System displays message: "Unable to load scheduled appointments, please try
again later".

3-System redirects patient to his homepage.
4-Main flow resumes at step 5.

## Postconditions:
- Patients knows their appointments schedule.
- No data is modified in the system.

Non – Functional constraints:
-Patient data must be secure and encrypted.

-Appointments list must load quickly.

HMI constraints:
-Upcoming appointments should be visually different than past appointments
(different eye catching color...)











































































































































































































































