const jwt = require('jsonwebtoken');
const config = require('../config');
const db = require('../data/db');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'] || req.headers['x-access-token'];
  if (!authHeader) {
    return res.status(401).json({ success: false, message: 'Access Denied: No Token Provided' });
  }

  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

  try {
    const decoded = jwt.verify(token, config.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ success: false, message: 'Invalid or Expired Token' });
  }
};

const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden: Requires one of [${roles.join(', ')}] role`
      });
    }
    next();
  };
};

const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'] || req.headers['x-access-token'];
  if (!authHeader) {
    return next();
  }

  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
  try {
    const decoded = jwt.verify(token, config.JWT_SECRET);
    req.user = decoded;
  } catch (err) {
    // Ignore invalid token in optionalAuth
  }
  next();
};

module.exports = {
  verifyToken,
  optionalAuth,
  requireRole
};
