
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const userModel = require('../models/userModel');

// Register a new user
async function register(req, res) {
    const { full_name, email, password } = req.body || {};

    if (
        typeof full_name !== 'string' || !full_name.trim() ||
        typeof email !== 'string' || !email.trim() ||
        typeof password !== 'string' || !password
    ) {
        return res.status(400).json({
            message: 'Full name, email, and password are required.'
        });
    }

    if (password.length < 8) {
        return res.status(400).json({
            message: 'Password must be at least 8 characters.'
        });
    }

    try {
        const normalizedName = full_name.trim();
        const normalizedEmail = email.trim().toLowerCase();
        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await userModel.createUser(
            normalizedName,
            normalizedEmail,
            hashedPassword
        );

        return res.status(201).json({
            message: 'User registered successfully.',
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email
            }
        });
    } catch (err) {
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
}

// Login an existing user
async function login(req, res) {
    const { email, password } = req.body || {};

    if (
        typeof email !== 'string' || !email.trim() ||
        typeof password !== 'string' || !password
    ) {
        return res.status(400).json({
            message: 'Email and password are required.'
        });
    }

    try {
        const user = await userModel.findByEmail(email.trim().toLowerCase());

        if (!user) {
            return res.status(401).json({
                message: 'Invalid email or password.'
            });
        }

        const isMatch = await bcrypt.compare(password, user.password_hash);

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
    } catch (err) {
        console.error('Login error:', err.message);
        return res.status(500).json({
            message: 'Login failed.'
        });
    }
}

module.exports = { register, login };
