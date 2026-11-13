
const db = require('../db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Register a new user
function register(req, res) {
    const { full_name, email, password } = req.body;

    if (!full_name || !email || !password) {
        return res.status(400).json({
            message: 'Full name, email, and password are required.'
        });
    }

    if (password.length < 8) {
        return res.status(400).json({
            message: 'Password must be at least 8 characters.'
        });
    }

    bcrypt.hash(password, 10, (err, hashedPassword) => {
        if (err) {
            return res.status(500).json({
                message: 'Failed to secure password.'
            });
        }

        const sql = `
            INSERT INTO users (full_name, email, password_hash)
            VALUES (?, ?, ?)
        `;

        db.query(
            sql,
            [full_name.trim(), email.trim().toLowerCase(), hashedPassword],
            (err, result) => {
                if (err) {
                    if (err.code === 'ER_DUP_ENTRY') {
                        return res.status(409).json({
                            message: 'Email is already registered.'
                        });
                    }

                    console.error('Registration error:', err.message);
                    return res.status(500).json({
                        message: 'Failed to register user.'
                    });
                }

                return res.status(201).json({
                    message: 'User registered successfully.',
                    user: {
                        id: result.insertId,
                        full_name: full_name.trim(),
                        email: email.trim().toLowerCase()
                    }
                });
            }
        );
    });
}

// Login an existing user
function login(req, res) {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({
            message: 'Email and password are required.'
        });
    }

    const sql = `
        SELECT id, full_name, email, password_hash, role
        FROM users
        WHERE email = ?
        LIMIT 1
    `;

    db.query(sql, [email.trim().toLowerCase()], (err, results) => {
        if (err) {
            console.error('Login error:', err.message);
            return res.status(500).json({
                message: 'Login failed.'
            });
        }

        if (results.length === 0) {
            return res.status(401).json({
                message: 'Invalid email or password.'
            });
        }

        const user = results[0];

        bcrypt.compare(password, user.password_hash, (err, isMatch) => {
            if (err) {
                return res.status(500).json({
                    message: 'Failed to verify password.'
                });
            }

            if (!isMatch) {
                return res.status(401).json({
                    message: 'Invalid email or password.'
                });
            }

            const secret = process.env.JWT_SECRET;

            if (!secret) {
                console.error('JWT_SECRET is not configured.');
                return res.status(500).json({
                    message: 'Authentication is not configured.'
                });
            }

            const token = jwt.sign(
                {
                    id: user.id,
                    role: user.role
                },
                secret,
                { expiresIn: '1h' }
            );

            return res.status(200).json({
                message: 'Login successful.',
                token,
                user: {
                    id: user.id,
                    full_name: user.full_name,
                    email: user.email,
                    role: user.role
                }
            });
        });
    });
}

module.exports = { register, login };
