
require('dotenv').config({
    path: require('path').join(__dirname, '.env')
});

const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT) || 3000;

// Routes
const complaintRoutes = require('./routes/complaintRoutes');
const authRoutes = require('./routes/authRoutes');

// Middleware
const verifyToken = require('./middleware/authMiddleware');

app.use(cors());

app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');

    if (req.method === 'OPTIONS') {
        return res.sendStatus(204);
    }

    next();
});

app.use(express.json());

// Serve frontend assets from the public folder only
app.use(express.static(path.join(__dirname, 'public')));

// Home page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

// Login page
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'login.html'));
});

// Register page
app.get('/register', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'register.html'));
});

// Backend status
app.get('/api/status', (req, res) => {
    res.json({
        success: true,
        message: 'Backend is working!',
        project: 'Smart Community Service and Complaint System'
    });
});

// Temporary protected endpoint for testing JWT
app.get('/api/auth-test', verifyToken, (req, res) => {
    res.json({
        message: 'Token verified successfully!',
        user: req.user
    });
});

// Complaint API routes
app.use('/api/complaints', complaintRoutes);

// Authentication API routes
app.use('/api/auth', authRoutes);

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://localhost:${PORT}`);
    console.log(`Network access enabled on http://0.0.0.0:${PORT}`);
});
