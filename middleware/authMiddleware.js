
const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            message: 'Access denied. Token is required.'
        });
    }

    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET;

    if (!secret) {
        console.error('JWT_SECRET is not configured.');

        return res.status(500).json({
            message: 'Authentication is not configured.'
        });
    }

    jwt.verify(token, secret, (err, decoded) => {
        if (err) {
            return res.status(401).json({
                message: 'Invalid or expired token.'
            });
        }

        req.user = decoded;
        next();
    });
}

module.exports = verifyToken;
