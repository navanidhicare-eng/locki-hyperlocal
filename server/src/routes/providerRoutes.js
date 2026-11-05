const express = require('express');
const router = express.Router();
const providerController = require('../controllers/providerController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.get('/nearby', providerController.getNearbyProviders);
router.get('/by-category/:categoryId', providerController.getProvidersByCategory);
router.post('/toggle-online', verifyToken, requireRole('provider'), providerController.toggleOnlineStatus);
router.post('/location', verifyToken, requireRole('provider'), providerController.updateLocation);
router.get('/my-orders', verifyToken, requireRole('provider'), providerController.getProviderOrders);
router.get('/profile', verifyToken, requireRole('provider'), providerController.getProfile);
router.put('/profile', verifyToken, requireRole('provider'), providerController.updateProfile);

module.exports = router;
