
const multer = require('multer');
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const uploadDirectory = path.join(__dirname, '..', 'uploads');
fs.mkdirSync(uploadDirectory, { recursive: true });

const allowedImageTypes = {
    'image/jpeg': ['.jpg', '.jpeg'],
    'image/png': ['.png'],
    'image/gif': ['.gif'],
    'image/webp': ['.webp']
};

const storage = multer.diskStorage({
    destination: uploadDirectory,

    filename: (req, file, cb) => {
        const extension = path.extname(file.originalname).toLowerCase();
        cb(null, `${Date.now()}-${crypto.randomBytes(16).toString('hex')}${extension}`);
    }
});

const fileFilter = (req, file, cb) => {
    const extensions = allowedImageTypes[file.mimetype];
    const extension = path.extname(file.originalname).toLowerCase();

    if (extensions && extensions.includes(extension)) {
        cb(null, true);
        return;
    }

    const error = new Error('Only JPEG, PNG, GIF, and WebP images are allowed.');
    error.code = 'INVALID_IMAGE_TYPE';
    cb(error);
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024
    }
});

function uploadComplaintPhoto(req, res, next) {
    upload.single('photo')(req, res, (error) => {
        if (!error) {
            return next();
        }

        if (error instanceof multer.MulterError) {
            if (error.code === 'LIMIT_FILE_SIZE') {
                return res.status(413).json({
                    success: false,
                    message: 'Image must be 5 MB or smaller.'
                });
            }

            return res.status(400).json({
                success: false,
                message: error.code === 'LIMIT_UNEXPECTED_FILE'
                    ? 'Upload one image using the "photo" field.'
                    : 'Invalid image upload.'
            });
        }

        if (error.code === 'INVALID_IMAGE_TYPE') {
            return res.status(400).json({
                success: false,
                message: error.message
            });
        }

        if (/malformed|unexpected end|boundary|part header/i.test(error.message)) {
            return res.status(400).json({
                success: false,
                message: 'Malformed multipart/form-data request. In Postman, use form-data and let Postman set the Content-Type boundary.'
            });
        }

        console.error('Complaint image upload error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Failed to save uploaded image.'
        });
    });
}

module.exports = uploadComplaintPhoto;
