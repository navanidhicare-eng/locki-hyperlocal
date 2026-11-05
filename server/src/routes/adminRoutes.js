const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.use(verifyToken, requireRole('admin'));

router.get('/dashboard', adminController.getDashboardStats);

// Provider / Partner routes
router.get('/providers', adminController.getAllProviders);
router.post('/providers', adminController.createProvider);
router.delete('/providers/:id', adminController.deleteProvider);
router.patch('/providers/:id/kyc', adminController.updateKycStatus);
router.patch('/providers/:id/subscription', adminController.updateProviderSubscription);
router.patch('/providers/:id/toggle-online', adminController.toggleProviderOnline);

// Customer routes
router.get('/users', adminController.getAllUsers);
router.post('/users', adminController.createCustomer);
router.delete('/users/:id', adminController.deleteCustomer);

router.get('/orders', adminController.getAllOrders);

module.exports = router;
