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

// Multi-Business Switching routes
router.get('/businesses', verifyToken, requireRole('provider'), providerController.getBusinesses);
router.post('/businesses/request', verifyToken, requireRole('provider'), providerController.requestNewBusiness);
router.post('/businesses/switch', verifyToken, requireRole('provider'), providerController.switchActiveBusiness);
router.put('/businesses/:businessId', verifyToken, requireRole('provider'), providerController.updateBusiness);
router.delete('/businesses/:businessId', verifyToken, requireRole('provider'), providerController.deleteBusiness);
router.get('/businesses/public/:providerId', providerController.getBusinesses);
router.post('/businesses/public/request', providerController.requestNewBusiness);
router.post('/businesses/public/switch', providerController.switchActiveBusiness);
router.post('/businesses/public/approve', providerController.approveBusinessPublic);
router.put('/businesses/public/:businessId', providerController.updateBusiness);
router.delete('/businesses/public/:businessId', providerController.deleteBusiness);

module.exports = router;
