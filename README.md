# Smart Community Service and Complaint System

## Project Overview

The Smart Community Service and Complaint System is a proposed digital platform that allows residents to report community problems and service requests online. It also enables authorized barangay officials to review complaints, manage reports, and monitor their progress.

The initial implementation will focus on one barangay, with the possibility of supporting additional barangays in the future.

## Objectives

- Allow residents to submit complaints and service requests.
- Support photo uploads as evidence of reported problems.
- Allow residents to track report statuses: Pending, Ongoing, and Resolved.
- Provide an administrative dashboard for authorized barangay officials.
- Publish community announcements and emergency alerts.
- Maintain organized complaint records and history.
- Provide a responsive interface for supported devices.

## Planned Technology Stack

- **Frontend:** Flutter and Dart
- **Backend:** Node.js and Express.js
- **Database:** MySQL
- **API:** REST API
- **Version Control:** Git and GitHub

## Main Features

1. User Authentication
2. Report Problems
3. Photo Upload
4. Status Tracking
5. Emergency Alerts and Announcements
6. Admin Dashboard
7. Report History
8. Responsive Interface

## System Architecture

Flutter Client → Express.js REST API → MySQL Database

## Project Structure

- `backend/` contains the Node.js API, MVC layers, middleware, database schema, and stored procedures.
- `frontend/flutter/` contains the Flutter application and its platform-specific projects.
- `frontend/legacy-web/views/` preserves the former HTML view without coupling it to the API server. The backend no longer serves these pages.
- `backend/uploads/` stores uploaded complaint images.

## Run the Backend

Create a root-level `.env` file (it is ignored by Git) with the database connection settings and JWT signing secret:

```text
DB_HOST=localhost
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password
DB_NAME=smart_community_db
JWT_SECRET=replace_with_a_long_random_value
PORT=3000
CORS_ORIGINS=*
```

`DB_PASSWORD` may be empty only when the local MySQL account is configured that way. Set `CORS_ORIGINS` to the Flutter web origin(s) when running outside local development.

Install backend dependencies once, then start the API:

```powershell
cd backend
npm install
npm start
```

The API listens on port `3000` by default. `PORT` can override it. The status endpoint is `GET /api/status`.

## Run the Flutter Frontend

```powershell
cd frontend/flutter
flutter pub get
flutter run --dart-define="API_BASE_URL=http://localhost:3000/api"
```

Set `API_BASE_URL` for the target device or browser. For example, an Android emulator typically reaches the host machine using `http://10.0.2.2:3000/api`; a physical device needs a reachable host address. Use HTTPS for deployed environments. The API base URL is configurable at build/run time and no production address is embedded in the app.

The login and registration screens call `POST /api/auth/login` and `POST /api/auth/register`. Authenticated complaint endpoints continue to use bearer JWTs.

The app also stores the login token and account details using platform secure storage, restores the session on the next launch, and sends the bearer token with complaint requests. Complaint photos are selected with the platform file picker and sent as multipart field `photo`.

The Flutter project declares `file_picker`, `flutter_secure_storage`, and `http_parser` for complaint images and secure sessions. After approving dependency resolution, run `flutter pub get` in `frontend/flutter` to update `pubspec.lock` and generated platform plugin registrations. Package installation was not run during integration.

## Project Status

The Flutter registration/login and complaint submission/list/status flows are integrated with the existing Complaint API. Database setup, Flutter dependency resolution, and runtime verification remain necessary before deployment.

## Team Members

- Cherryl M. Caspe — Team Leader
- Charvelou F. Antiquina — Developer
- Jebson L. Manteza — Developer
- Wynevel A. Ybanez — Project Manager
- Eldroeh S. Bayron — Quality Assurance (QA)

## Collaboration

GitHub is used for source-code management, task tracking, code reviews, and team collaboration. Team members should work on assigned branches and submit pull requests for review before changes are merged into protected branches.

## Complaint API

#### Import the database scripts with phpMyAdmin

1. In phpMyAdmin, open **Import** from the server or select the `smart_community_db` database first.
2. Import `backend/database/smart_community_db.sql`. It creates the database if it does not exist, then creates the `users` and `complaints` tables and applies the complaint-table migrations, including `admin_remark`. It does not delete or replace an existing database or its tables.
3. Import each stored procedure file from `backend/database/stored_procedures/`:
   - `sp_create_complaint.sql`
   - `sp_get_complaints.sql`
   - `sp_get_user_complaints.sql`
   - `sp_update_complaint_status.sql`
   - `sp_register_user.sql`
   - `sp_get_user_by_email.sql`

The procedure scripts can be imported in any order and can be re-imported to replace the existing procedures. The application's database user needs permission to create databases, create/alter tables, and create procedures. If `smart_community_db` already contains data, back it up first; the script preserves existing tables but the foreign-key migration may fail if existing complaint user IDs do not match users.

Registration and login procedures use the existing `users` columns. Passwords are hashed with bcrypt in the backend before registration; the login procedure returns the stored hash for bcrypt comparison and never receives a plaintext password.

### Postman testing

Set a Postman environment variable `base_url` to `http://localhost:3000`. If the API uses a different port or host, set it to that server origin (do not append `/api`).

1. **Register a resident** — `POST {{base_url}}/api/auth/register`, Body → raw → JSON:

   ```json
   {
     "full_name": "Test Resident",
     "email": "resident@example.test",
     "password": "TestPassword123"
   }
   ```

   Expect `201 Created`. Use a fresh email if the address is already registered.

2. **Log in** — `POST {{base_url}}/api/auth/login`, Body → raw → JSON:

   ```json
   {
     "email": "resident@example.test",
     "password": "TestPassword123"
   }
   ```

   Expect `200 OK`. Copy `token` from the response into the Postman environment variable `user_token`. The token expires after one hour.

   To provision an administrator, an authorized database operator can promote a dedicated account, for example with `UPDATE users SET role = 'admin' WHERE email = 'admin@example.test';`. Confirm the intended account before running this statement, then log in again to receive a token with the admin role. Public registration intentionally cannot assign admin privileges.

3. **Submit a complaint** — `POST {{base_url}}/api/complaints`. Select Authorization → Bearer Token and enter `{{user_token}}`. Select Body → form-data and add text fields `title`, `category`, `location`, and `description`; optionally add `photo` as a File. Use a JPEG, PNG, GIF, or WebP image up to 5 MB. Do not manually set `Content-Type`; Postman must generate the multipart boundary. Expect `201 Created` with `complaintId`, `referenceNumber`, and `photoUrl`.

4. **List complaints** — `GET {{base_url}}/api/complaints`, Authorization → Bearer Token `{{user_token}}`. Residents receive only their own complaints; admin accounts receive all complaints. The response includes `id`, `title`, `category`, `location`, `description`, `photo_url`, `status`, `admin_remark`, and other stored fields. `GET {{base_url}}/api/complaints/admin` is restricted to admins and returns all complaints.

5. **Update a complaint status** — after an administrator has promoted a dedicated account, log in with that account to obtain a fresh admin JWT. Send `PATCH {{base_url}}/api/complaints/{{complaint_id}}/status`, Authorization → Bearer Token with that JWT, Body → raw → JSON:

   ```json
   {
     "status": "Ongoing",
     "remark": "Repair crew assigned; work is scheduled for tomorrow."
   }
   ```

   `status` must be `Pending`, `Ongoing`, or `Resolved`. `remark` is optional and limited to 500 characters; the latest admin remark is visible with the complaint. The route requires a JWT whose database user has role `admin`; registration creates ordinary users. Promote a dedicated test account through an approved database-administration process before testing this endpoint. Expect `200 OK` on success, `401` for an invalid/expired token, or `403` for a non-admin account.

### Submit a complaint

- Method and URL: `POST http://localhost:3000/api/complaints`
- Header: `Authorization: Bearer <JWT>`
- In Postman, choose **Body → form-data** and add text fields `title`, `category`, `location`, and `description`.
- Add an optional field named `photo`, set its type to **File**, and choose a JPEG, PNG, GIF, or WebP image up to 5 MB.
- Do not manually set the `Content-Type` header. Postman must generate the multipart boundary.

The response includes the existing `complaintId` field, the equivalent `referenceNumber`, and `photoUrl` (`null` when no image was supplied). The uploaded image can be accessed through its returned `/uploads/...` path.

### List complaints

- Method and URL: `GET http://localhost:3000/api/complaints`
- Send a bearer token. Residents receive only their own complaints; admins receive all complaints.
- The response remains an array and includes `user_id`, `photo_url`, `status`, and `admin_remark` for each record.
- Admin dashboard list: `GET http://localhost:3000/api/complaints/admin` (admin role required).
