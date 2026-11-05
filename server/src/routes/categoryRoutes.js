const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.get('/', categoryController.getAllCategories);
router.post('/', verifyToken, requireRole('admin'), categoryController.createCategory);
router.put('/:id', verifyToken, requireRole('admin'), categoryController.updateCategory);
router.delete('/:id', verifyToken, requireRole('admin'), categoryController.deleteCategory);

// Sub-categories routes
router.post('/:id/subcategories', verifyToken, requireRole('admin'), categoryController.addSubCategory);
router.put('/:id/subcategories/:subId', verifyToken, requireRole('admin'), categoryController.updateSubCategory);
router.delete('/:id/subcategories/:subId', verifyToken, requireRole('admin'), categoryController.deleteSubCategory);

// Child-categories routes
router.post('/:id/subcategories/:subId/children', verifyToken, requireRole('admin'), categoryController.addChildCategory);
router.delete('/:id/subcategories/:subId/children/:childId', verifyToken, requireRole('admin'), categoryController.deleteChildCategory);

module.exports = router;
