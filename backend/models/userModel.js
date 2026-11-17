const db = require('../db');
const { findProcedureRow, findProcedureRows } = require('./procedureResults');

function createUser(fullName, email, passwordHash) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_register_user(?, ?, ?)',
            [fullName, email, passwordHash],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                const user = findProcedureRow(results, 'id');

                if (!user) {
                    return reject(
                        new Error('The registration procedure returned no user.')
                    );
                }

                resolve(user);
            }
        );
    });
}

function findByEmail(email) {
    return new Promise((resolve, reject) => {
        db.query(
            'CALL sp_get_user_by_email(?)',
            [email],
            (err, results) => {
                if (err) {
                    return reject(err);
                }

                const rows = findProcedureRows(results, 'id');

                if (!rows) {
                    return reject(
                        new Error('The user lookup procedure returned no result set.')
                    );
                }

                resolve(rows[0] || null);
            }
        );
    });
}

module.exports = {
    createUser,
    findByEmail
};
