const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const { verifyToken, requireRole } = require('../middleware/auth');

// POST /api/upload
// Accepts { dataUrl, filename, folder = 'categories' }
router.post('/', verifyToken, (req, res) => {
  try {
    const { dataUrl, filename, folder = 'categories' } = req.body;
    if (!dataUrl || !dataUrl.includes(',')) {
      return res.status(400).json({ success: false, message: 'Invalid image dataUrl format' });
    }

    // Parse data URL prefix e.g. data:image/png;base64,
    const matches = dataUrl.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    if (!matches || matches.length !== 3) {
      return res.status(400).json({ success: false, message: 'Invalid base64 payload' });
    }

    const mimeType = matches[1];
    const base64Data = matches[2];
    const buffer = Buffer.from(base64Data, 'base64');

    // Extension from mimeType or filename
    let ext = '.png';
    if (mimeType.includes('jpeg') || mimeType.includes('jpg')) ext = '.jpg';
    else if (mimeType.includes('svg')) ext = '.svg';
    else if (mimeType.includes('webp')) ext = '.webp';
    else if (mimeType.includes('gif')) ext = '.gif';

    // Target folder
    const safeFolder = folder.replace(/[^a-zA-Z0-9_-]/g, '');
    const uploadDir = path.join(__dirname, '../../uploads', safeFolder);
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    const timestamp = Date.now();
    const cleanBase = (filename || 'image').replace(/\.[^/.]+$/, '').replace(/[^a-zA-Z0-9_-]/g, '_').toLowerCase();
    const finalFilename = `${cleanBase}_${timestamp}${ext}`;
    const filePath = path.join(uploadDir, finalFilename);

    fs.writeFileSync(filePath, buffer);

    // Build URL accessible from mobile apps & web
    const host = req.get('host');
    const protocol = req.protocol;
    const fileUrl = `${protocol}://${host}/uploads/${safeFolder}/${finalFilename}`;

    res.json({
      success: true,
      url: fileUrl,
      filename: finalFilename,
      size: buffer.length,
      mimeType
    });
  } catch (err) {
    console.error('File upload error:', err);
    res.status(500).json({ success: false, message: 'Upload failed: ' + err.message });
  }
});

module.exports = router;

