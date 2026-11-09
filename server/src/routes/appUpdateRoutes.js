const express = require('express');
const router = express.Router();
const appUpdateController = require('../controllers/appUpdateController');

// Public endpoints called by Flutter apps
router.get('/check', appUpdateController.checkUpdate);
router.get('/versions', appUpdateController.getVersions);
router.get('/download/:appId', appUpdateController.downloadApk);

// Release endpoint for admin / CLI
router.post('/release', appUpdateController.releaseUpdate);

module.exports = router;

