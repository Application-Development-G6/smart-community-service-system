
const complaintModel = require('../models/complaintModel');

// Handle complaint submission
async function createComplaint(req, res) {
    const { title, category, description, location } = req.body || {};

    if (
        typeof title !== 'string' || !title.trim() ||
        typeof category !== 'string' || !category.trim() ||
        typeof description !== 'string' || !description.trim() ||
        typeof location !== 'string' || !location.trim()
    ) {
        return res.status(400).json({
            success: false,
            message: 'Please provide all required complaint details.'
        });
    }

    try {
        const result = await complaintModel.createComplaint(
            title.trim(),
            category.trim(),
            description.trim(),
            location.trim()
        );

        return res.status(201).json({
            success: true,
            message: 'Complaint submitted successfully!',
            complaintId: result.complaintId
        });
    } catch (err) {
        console.error('Create complaint error:', err.message);

        return res.status(500).json({
            success: false,
            message: 'Failed to save complaint.'
        });
    }
}

// Handle retrieving complaints
async function getComplaints(req, res) {
    try {
        const complaints = await complaintModel.getComplaints();

        return res.json(complaints);
    } catch (err) {
        console.error('Get complaints error:', err.message);

        return res.status(500).json({
            success: false,
            message: 'Failed to retrieve complaints.'
        });
    }
}

// Handle updating complaint status
async function updateComplaintStatus(req, res) {
    const id = Number(req.params.id);
    const { status } = req.body || {};

    const allowedStatuses = ['Pending', 'Ongoing', 'Resolved'];

    if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({
            success: false,
            message: 'Invalid complaint ID.'
        });
    }

    if (
        typeof status !== 'string' ||
        !allowedStatuses.includes(status)
    ) {
        return res.status(400).json({
            success: false,
            message: 'Status must be Pending, Ongoing, or Resolved.'
        });
    }

    try {
        const affectedRows =
            await complaintModel.updateComplaintStatus(id, status);

        console.log(
            'Affected rows received by controller:',
            affectedRows
        );

        if (affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Complaint not found.'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Complaint status updated successfully!'
        });
    } catch (err) {
        console.error('Update complaint status error:', err.message);

        return res.status(500).json({
            success: false,
            message: 'Failed to update complaint status.'
        });
    }
}

module.exports = {
    createComplaint,
    getComplaints,
    updateComplaintStatus
};
