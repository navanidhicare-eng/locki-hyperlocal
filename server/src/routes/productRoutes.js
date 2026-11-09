const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, productController.getAllProducts);
router.get('/user/:phoneOrId', optionalAuth, productController.getUserProducts);
router.post('/', optionalAuth, productController.createProduct);
router.put('/:id', optionalAuth, productController.updateProduct);
router.delete('/:id', optionalAuth, productController.deleteProduct);

module.exports = router;
