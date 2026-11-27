const db = require('../db');
const { findProcedureRow, findProcedureRows } = require('./procedureResults');

// Save a complaint using a MySQL stored procedure
function createComplaint(title, category, description, location, userId, photoUrl) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_create_complaint(?, ?, ?, ?, ?, ?)',
            [title, category, description, location, userId, photoUrl],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                const complaint = findProcedureRow(results, 'complaintId');

                if (!complaint) {
                    return reject(
                        new Error('The create complaint procedure returned no reference number.')
                    );
                }

                resolve(complaint);
            }
        );
    });
}

// Retrieve complaints using a MySQL stored procedure
function getComplaints() {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_get_complaints()',
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                const complaints = findProcedureRows(results, 'id');

                if (!complaints) {
                    return reject(
                        new Error('The get complaints procedure returned no result set.')
                    );
                }

                resolve(complaints);
            }
        );
    });
}

// Retrieve complaints submitted by one resident
function getUserComplaints(userId) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_get_user_complaints(?)',
            [userId],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                const complaints = findProcedureRows(results, 'id');
                if (!complaints) {
                    return reject(
                        new Error('The get user complaints procedure returned no result set.')
                    );
                }

                resolve(complaints);
            }
        );
    });
}

// Update complaint status using a MySQL stored procedure
function updateComplaintStatus(id, status, remark) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_update_complaint_status(?, ?, ?)',
            [id, status, remark],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                const result = findProcedureRow(results, 'found');
                const found = result ? Number(result.found) : NaN;

                if (found !== 0 && found !== 1) {
                    return reject(
                        new Error('Could not read the complaint update result.')
                    );
                }

                resolve(found);
            }
        );
    });
}

module.exports = {
    createComplaint,
    getComplaints,
    getUserComplaints,
    updateComplaintStatus
};
