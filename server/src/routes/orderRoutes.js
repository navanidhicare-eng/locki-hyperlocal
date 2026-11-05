const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { verifyToken, optionalAuth } = require('../middleware/auth');

router.post('/', verifyToken, orderController.createOrder);
router.post('/quick-request', orderController.createQuickRequest);
router.put('/:id/accept', verifyToken, orderController.acceptOrder);
router.get('/my', optionalAuth, orderController.getCustomerOrders);
router.get('/:id', verifyToken, orderController.getOrderDetails);
router.patch('/:id/status', verifyToken, orderController.updateOrderStatus);

module.exports = router;
