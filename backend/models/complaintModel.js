
const db = require('../db');

// Save a complaint using a MySQL stored procedure
function createComplaint(title, category, description, location) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_create_complaint(?, ?, ?, ?)',
            [title, category, description, location],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                resolve(results[0][0]);
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

                resolve(results[0]);
            }
        );
    });
}

// Update complaint status using a MySQL stored procedure
function updateComplaintStatus(id, status) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_update_complaint_status(?, ?)',
            [id, status],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                console.log('Stored procedure results:', results);

                // MySQL returns a ResultSetHeader directly in this case.
                const affectedRows = results?.affectedRows;

                if (typeof affectedRows !== 'number') {
                    return reject(
                        new Error('Could not read affectedRows from database.')
                    );
                }

                resolve(affectedRows);
            }
        );
    });
}

module.exports = {
    createComplaint,
    getComplaints,
    updateComplaintStatus
};
