
const express = require('express');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '.env') });
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const app = express();
const PORT = Number(process.env.PORT) || 3000;

// Routes
const complaintRoutes = require('./routes/complaintRoutes');
const authRoutes = require('./routes/authRoutes');

// Middleware
const verifyToken = require('./middleware/authMiddleware');
const corsMiddleware = require('./middleware/corsMiddleware');

app.use(corsMiddleware);
app.use(express.json());

// Serve uploaded complaint images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

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

// Keep unknown API endpoints in the same JSON response format as API routes.
app.use('/api', (req, res) => {
    res.status(404).json({
        success: false,
        message: `API route ${req.method} ${req.originalUrl} was not found.`
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
