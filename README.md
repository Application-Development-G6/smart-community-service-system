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

## Project Status

Initial project setup and development are in progress. Features will be implemented and tested according to the approved project proposal.

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
2. Import `database/smart_community_db.sql`. It creates the database if it does not exist, then creates the `users` and `complaints` tables and applies the complaint-table migration. It does not delete or replace an existing database or its tables.
3. Import each stored procedure file from `database/stored_procedures/`:
   - `sp_create_complaint.sql`
   - `sp_get_complaints.sql`
   - `sp_update_complaint_status.sql`

The procedure scripts can be imported in any order and can be re-imported to replace the existing procedures. The application's database user needs permission to create databases, create/alter tables, and create procedures. If `smart_community_db` already contains data, back it up first; the script preserves existing tables but the foreign-key migration may fail if existing complaint user IDs do not match users.

### Submit a complaint

- Method and URL: `POST http://localhost:3000/api/complaints`
- Header: `Authorization: Bearer <JWT>`
- In Postman, choose **Body → form-data** and add text fields `title`, `category`, `location`, and `description`.
- Add an optional field named `photo`, set its type to **File**, and choose a JPEG, PNG, GIF, or WebP image up to 5 MB.
- Do not manually set the `Content-Type` header. Postman must generate the multipart boundary.

The response includes the existing `complaintId` field, the equivalent `referenceNumber`, and `photoUrl` (`null` when no image was supplied). The uploaded image can be accessed through its returned `/uploads/...` path.

### List complaints

- Method and URL: `GET http://localhost:3000/api/complaints`
- The response remains an array and includes `user_id` and `photo_url` for each record.
