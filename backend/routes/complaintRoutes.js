
const express = require('express');
const router = express.Router();

const complaintController = require('../controllers/complaintController');
const uploadComplaintPhoto = require('../middleware/uploadMiddleware');
const verifyToken = require('../middleware/authMiddleware');
const verifyAdmin = require('../middleware/adminMiddleware');

// Submit a complaint with an optional image
router.post(
    '/',
    verifyToken,
    uploadComplaintPhoto,
    complaintController.createComplaint
);

// Residents retrieve their own complaints; admins retrieve all complaints.
router.get(
    '/',
    verifyToken,
    complaintController.getComplaints
);

// Retrieve all complaints for the admin dashboard
router.get(
    '/admin',
    verifyToken,
    verifyAdmin,
    complaintController.getAdminComplaints
);

// Update a complaint's status (requires an admin account)
router.patch(
    '/:id/status',
    verifyToken,
    verifyAdmin,
    complaintController.updateComplaintStatus
);

module.exports = router;
