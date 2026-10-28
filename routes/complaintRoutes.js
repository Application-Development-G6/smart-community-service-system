
const express = require('express');
const router = express.Router();

const complaintController = require('../controllers/complaintController');

// Submit a complaint
router.post('/', complaintController.createComplaint);

// Retrieve all complaints
router.get('/', complaintController.getComplaints);

// Update a complaint's status
router.patch('/:id/status', complaintController.updateComplaintStatus);

module.exports = router;
