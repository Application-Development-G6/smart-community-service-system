
const express = require('express');
const router = express.Router();

const complaintController = require('../controllers/complaintController');
const uploadComplaintPhoto = require('../middleware/uploadMiddleware');
const verifyToken = require('../middleware/authMiddleware');

// Submit a complaint with an optional image
router.post(
    '/',
    verifyToken,
    uploadComplaintPhoto,
    complaintController.createComplaint
);

// Retrieve all complaints (requires authentication)
router.get(
    '/',
    verifyToken,
    complaintController.getComplaints
);

// Update a complaint's status (requires authentication)
router.patch(
    '/:id/status',
    verifyToken,
    complaintController.updateComplaintStatus
);

module.exports = router;
