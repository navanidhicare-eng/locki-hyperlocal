const db = require('../data/db');

// Distance calculation using Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

exports.getNearbyProviders = (req, res) => {
  const { lat, lng, categoryId, maxDistanceKm = 15 } = req.query;

  let providers = db.data.providers.filter(p => p.kycStatus === 'approved' && p.isOnline);

  if (categoryId) {
    providers = providers.filter(p => p.category === categoryId);
  }

  if (lat && lng) {
    const userLat = parseFloat(lat);
    const userLng = parseFloat(lng);

    providers = providers.map(p => {
      const distance = calculateDistance(userLat, userLng, p.currentLocation.lat, p.currentLocation.lng);
      return {
        ...p,
        distanceKm: Math.round(distance * 10) / 10
      };
    }).filter(p => p.distanceKm <= parseFloat(maxDistanceKm));

    providers.sort((a, b) => a.distanceKm - b.distanceKm);
  }

  // Remove passwords
  const safeProviders = providers.map(p => {
    const copy = { ...p };
    delete copy.passwordHash;
    return copy;
  });

  res.json({
    success: true,
    count: safeProviders.length,
    providers: safeProviders
  });
};

exports.toggleOnlineStatus = (req, res) => {
  const providerId = req.user.id;
  const provider = db.data.providers.find(p => p.id === providerId);

  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  if (provider.kycStatus !== 'approved') {
    return res.status(403).json({
      success: false,
      message: 'Cannot go online: Your KYC is still pending admin approval'
    });
  }

  provider.isOnline = req.body.isOnline !== undefined ? Boolean(req.body.isOnline) : !provider.isOnline;
  db.save();

  res.json({
    success: true,
    message: `Provider is now ${provider.isOnline ? 'ONLINE (Ready for Jobs)' : 'OFFLINE'}`,
    isOnline: provider.isOnline
  });
};

exports.updateLocation = (req, res) => {
  const providerId = req.user.id;
  const { lat, lng } = req.body;

  if (lat === undefined || lng === undefined) {
    return res.status(400).json({ success: false, message: 'Latitude and Longitude are required' });
  }

  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  provider.currentLocation = { lat: parseFloat(lat), lng: parseFloat(lng) };
  db.save();

  // If Socket.IO exists, broadcast provider movement
  const io = req.app.get('io');
  if (io) {
    io.emit('provider:location_updated', {
      providerId,
      location: provider.currentLocation
    });
  }

  res.json({ success: true, message: 'Location updated', location: provider.currentLocation });
};

exports.getProviderOrders = (req, res) => {
  const providerId = req.user.id;
  const orders = db.data.orders.filter(o => o.providerId === providerId || (o.orderStatus === 'PENDING' && o.category === req.user.category));

  res.json({
    success: true,
    orders: orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
  });
};

exports.getProfile = (req, res) => {
  const providerId = req.user.id;
  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }
  const copy = { ...provider };
  delete copy.passwordHash;
  res.json({ success: true, provider: copy });
};

exports.updateProfile = (req, res) => {
  const providerId = req.user.id;
  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  const allowedFields = [
    'name', 'email', 'category', 'categoryName', 'subCategory', 'subCategoryId', 'subCategoryName', 'childServices', 'selectedChildServices', 'serviceName', 'experience',
    'district', 'mandal', 'village', 'pincode', 'address',
    'aadhaarNumber', 'upiId',
    'fatherName', 'motherName', 'dob', 'age', 'currentAddress',
    'emergencyContact', 'aadhaarFrontUrl', 'aadhaarBackUrl',
    'panNumber', 'panCardUrl', 'drivingLicenseNumber', 'drivingLicenseUrl',
    'skillCertificates', 'livePhotoVerificationStatus',
    'guarantorName', 'guarantorRelation', 'guarantorPhone',
    'workingHours', 'serviceRadius',
    'hasPhysicalShop', 'shopName', 'shopAddress', 'shopFrontPhotoUrl', 'shopInsidePhotoUrl', 'shopGstNumber',
    'landmark', 'shopDistrict', 'shopMandal', 'shopVillage', 'shopLandmark'
  ];

  for (const field of allowedFields) {
    if (req.body[field] !== undefined) {
      provider[field] = req.body[field];
    }
  }

  provider.isProfileComplete = true;
  provider.profileUpdatedAt = new Date().toISOString();

  db.save();

  const copy = { ...provider };
  delete copy.passwordHash;

  res.json({
    success: true,
    message: 'Profile created/updated successfully!',
    provider: copy
  });
};
