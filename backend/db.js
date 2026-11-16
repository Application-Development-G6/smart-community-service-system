const fs = require('fs');
const path = require('path');
const mysql = require('mysql2');

const requiredVariables = ['DB_USER'];
const missingVariables = requiredVariables.filter(
    (name) => process.env[name] === undefined
);

if (missingVariables.length > 0) {
    throw new Error(
        `Missing database environment variables: ${missingVariables.join(', ')}`
    );
}

const dbName = process.env.DB_NAME || 'smart_community_db';
const connection = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD ?? '',
    multipleStatements: true
});

function executeSqlFile(filePath) {
    return new Promise((resolve, reject) => {
        const sql = fs.readFileSync(filePath, 'utf8');
        const normalizedSql = sql
            .replace(/DELIMITER\s*\$\$\s*/gi, '')
            .replace(/DELIMITER\s*;\s*/gi, '')
            .replace(/\$\$/g, ';');

        connection.query(normalizedSql, (err, results) => {
            if (err) {
                reject(err);
                return;
            }
            resolve(results);
        });
    });
}

async function initializeDatabase() {
    await new Promise((resolve, reject) => {
        connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\``, (err) => {
            if (err) {
                reject(err);
                return;
            }

            connection.query(`USE \`${dbName}\``, (useErr) => {
                if (useErr) {
                    reject(useErr);
                    return;
                }
                resolve();
            });
        });
    });

    const schemaFile = path.join(__dirname, 'database', 'smart_community_db.sql');
    await executeSqlFile(schemaFile);

    const proceduresDir = path.join(__dirname, 'database', 'stored_procedures');
    const procedureFiles = fs
        .readdirSync(proceduresDir)
        .filter((file) => file.toLowerCase().endsWith('.sql'))
        .sort();

    for (const file of procedureFiles) {
        await executeSqlFile(path.join(proceduresDir, file));
    }
}

connection.connect(async (err) => {
    if (err) {
        console.error('MySQL connection failed:', err.message);
        return;
    }

    try {
        await initializeDatabase();
        console.log('Connected to MySQL database and initialized schema.');
    } catch (dbError) {
        console.error('Database initialization failed:', dbError.message);
        process.exit(1);
    }
});

module.exports = connection;