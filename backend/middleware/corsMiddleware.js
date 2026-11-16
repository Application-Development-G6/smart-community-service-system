function corsMiddleware(req, res, next) {
    const origin = req.headers.origin;
    const allowedOrigins = (process.env.CORS_ORIGINS || '*')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean);

    if (origin && allowedOrigins.includes('*')) {
        res.setHeader('Access-Control-Allow-Origin', '*');
    } else if (origin && allowedOrigins.includes(origin)) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Vary', 'Origin');
    }

    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Authorization,Content-Type');

    if (req.method === 'OPTIONS') {
        return res.sendStatus(204);
    }

    next();
}

module.exports = corsMiddleware;
