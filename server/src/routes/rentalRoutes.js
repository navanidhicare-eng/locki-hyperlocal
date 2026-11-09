const express = require('express');
const router = express.Router();
const rentalController = require('../controllers/rentalController');

// Public endpoints
router.get('/', rentalController.getAllRentals);
router.get('/user/:phoneOrId', rentalController.getUserRentals);
router.get('/:id', rentalController.getRentalById);
router.post('/', rentalController.createRental);
router.put('/:id', rentalController.updateRental);
router.delete('/:id', rentalController.deleteRental);

module.exports = router;

