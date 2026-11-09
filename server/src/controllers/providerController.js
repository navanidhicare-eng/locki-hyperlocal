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
  console.log('>>> [my-orders] Request from provider:', providerId, 'at', new Date().toISOString());
  const provider = db.data.providers.find(p => p.id === providerId);

  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  const orders = db.data.orders.filter(o => {
    // 1. Direct assignment to this provider (accepted or assigned directly)
    if (o.providerId === providerId) {
      return true;
    }

    // 2. If order is assigned to another specific provider, DO NOT show to anyone else!
    if (o.providerId && o.providerId !== providerId) {
      return false;
    }

    // 3. For PENDING open pool requests, apply strict 5-Layer Shield
    if (o.orderStatus === 'PENDING') {
      // Layer 1: Category Match
      const orderCat = o.categoryId || o.category;
      if (orderCat && provider.category && orderCat !== provider.category) {
        return false;
      }

      // Layer 2: Sub-Category Match (match by ID or Name)
      if (o.subCategoryId && provider.subCategoryId && o.subCategoryId !== provider.subCategoryId) {
        const oSubName = (o.subCategoryName || '').toLowerCase().trim();
        const pSubName = (provider.subCategoryName || '').toLowerCase().trim();
        if (!oSubName || !pSubName || oSubName !== pSubName) {
          return false;
        }
      }

      // Layer 3: Child Task Match (if partner has child task selection and order specifies child task)
      if (o.childTaskId && provider.selectedChildServices && provider.selectedChildServices.length > 0) {
        if (!provider.selectedChildServices.includes(o.childTaskId)) {
          return false;
        }
      }

      // Layer 4: Admin KYC Approval & Duty Check
      if (provider.kycStatus !== 'approved' || !provider.isOnline) {
        return false;
      }

      // Layer 5: Paid Subscription Check
      if (provider.subscriptionStatus === 'unpaid' || provider.subscriptionStatus === 'expired') {
        return false;
      }

      // Location Check: Mandal or Radius
      if (o.customerMandal && (provider.mandal || provider.shopMandal)) {
        const pMandal = (provider.mandal || provider.shopMandal || '').toLowerCase();
        const cMandal = o.customerMandal.toLowerCase();
        if (pMandal !== cMandal && provider.serviceRadius !== '50 KM') {
          return false;
        }
      }

      return true;
    }

    return false;
  });

  res.json({
    success: true,
    orders: orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
  });
};

// Customer Directory: Get verified technicians in a category with phone and direct hire info
exports.getProvidersByCategory = (req, res) => {
  const { categoryId } = req.params;
  const { mandal, district } = req.query;

  const matches = [];

  (db.data.providers || []).forEach(p => {
    // 1. Direct primary trade match
    if (p.category === categoryId) {
      matches.push({
        id: p.id,
        businessId: p.activeBusinessId || `biz_${p.id}_primary`,
        name: p.name,
        phone: p.phone,
        category: p.category,
        categoryName: p.categoryName || 'Specialist',
        subCategoryId: p.subCategoryId,
        subCategoryName: p.subCategoryName,
        selectedChildServices: p.selectedChildServices || [],
        experience: p.experience || '3+ Years',
        rating: p.rating || 4.9,
        jobsCompleted: p.jobsCompleted || 12,
        isOnline: Boolean(p.isOnline),
        kycStatus: p.kycStatus || 'pending',
        subscriptionStatus: p.subscriptionStatus || 'unpaid',
        district: p.district || p.shopDistrict || 'Anakapalli',
        mandal: p.mandal || p.shopMandal || 'Chodavaram',
        village: p.village || p.shopVillage || 'Chodavaram Town',
        serviceRadius: p.serviceRadius || '10 KM',
        avatarUrl: p.avatarUrl || null,
        shopName: p.shopName || null,
        shopAddress: p.shopAddress || null,
        shopTimings: p.shopTimings || null,
        businessType: p.businessType || 'service'
      });
    }

    // 2. Multi-business match
    if (Array.isArray(p.businesses)) {
      p.businesses.forEach(b => {
        if (b.status === 'approved' && (b.tradeCategory === categoryId || b.category === categoryId)) {
          // Avoid duplicate if it's already the primary
          if (!matches.some(m => m.id === p.id && m.businessId === b.id)) {
            matches.push({
              id: p.id,
              businessId: b.id,
              name: b.name || b.businessName || p.name,
              phone: b.phone || p.phone,
              category: b.tradeCategory || categoryId,
              categoryName: b.tradeCategoryName || 'Store / Specialist',
              subCategoryId: b.subCategoryId || '',
              subCategoryName: b.subCategoryName || '',
              selectedChildServices: [],
              experience: 'Verified Store',
              rating: p.rating || 4.9,
              jobsCompleted: p.jobsCompleted || 12,
              isOnline: b.storeStatus === 'OPEN',
              kycStatus: 'approved',
              subscriptionStatus: p.subscriptionStatus || 'active',
              district: b.district || p.district || 'Anakapalli',
              mandal: b.mandal || p.mandal || 'Chodavaram',
              village: b.village || p.village || 'Chodavaram Town',
              serviceRadius: '5 KM',
              avatarUrl: b.shopPhotoUrl || p.avatarUrl || null,
              shopName: b.name || b.businessName,
              shopAddress: b.shopAddress || p.shopAddress,
              shopTimings: b.shopTimings || { open: '08:00 AM', close: '09:00 PM', workingDays: 'All Days' },
              shopPhotoUrl: b.shopPhotoUrl || null,
              businessType: b.businessType || 'shop'
            });
          }
        }
      });
    }
  });

  if (mandal && mandal.trim()) {
    const qMandal = mandal.trim().toLowerCase();
    matches.sort((a, b) => {
      const aMatch = (a.mandal || '').toLowerCase() === qMandal;
      const bMatch = (b.mandal || '').toLowerCase() === qMandal;
      if (aMatch && !bMatch) return -1;
      if (!aMatch && bMatch) return 1;
      return (b.rating || 0) - (a.rating || 0);
    });
  } else {
    matches.sort((a, b) => (b.rating || 0) - (a.rating || 0));
  }

  const safeProviders = matches;

  res.json({
    success: true,
    count: safeProviders.length,
    providers: safeProviders
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

// Helper: Ensure partner has initialized businesses list
function ensurePartnerBusinesses(provider) {
  if (!provider.businesses || !Array.isArray(provider.businesses) || provider.businesses.length === 0) {
    provider.businesses = [
      {
        id: `biz_${provider.id}_primary`,
        businessType: 'service',
        name: provider.shopName || `${provider.name}'s Service`,
        tradeCategory: provider.category || 'cat_general',
        tradeCategoryName: provider.categoryName || 'Service Specialist',
        subCategoryId: provider.subCategoryId || '',
        subCategoryName: provider.subCategoryName || '',
        shopAddress: provider.shopAddress || provider.address || 'Local Workshop',
        phone: provider.phone,
        status: 'approved',
        isDefault: true,
        isActive: true,
        dutyStatus: provider.isOnline ? 'ON DUTY' : 'OFF DUTY',
        storeStatus: 'OPEN',
        createdAt: provider.createdAt || new Date().toISOString()
      }
    ];
    provider.activeBusinessId = provider.businesses[0].id;
    db.save();
  }
  return provider.businesses;
}

// GET /api/providers/businesses
exports.getBusinesses = (req, res) => {
  const providerId = req.user ? req.user.id : (req.query.providerId || req.params.providerId);
  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  const businesses = ensurePartnerBusinesses(provider);
  res.json({
    success: true,
    activeBusinessId: provider.activeBusinessId || businesses[0].id,
    businesses
  });
};

// POST /api/providers/businesses/request (Apply for a new business profile)
exports.requestNewBusiness = (req, res) => {
  const providerId = req.user ? req.user.id : req.body.providerId;
  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  ensurePartnerBusinesses(provider);
  const body = req.body;
  const bizName = (body.name || body.businessName || '').trim();
  const catName = (body.tradeCategoryName || body.categoryName || body.category || '').trim();

  if (!bizName || !catName) {
    return res.status(400).json({ success: false, message: 'Business name and category are required' });
  }

  // Auto-detect businessType if category or subcategory is rental or shop
  let bType = body.businessType || 'service';
  const checkCat = (body.tradeCategory || body.categoryId || '').toLowerCase();
  const checkCatName = catName.toLowerCase();
  const checkSubName = (body.subCategoryName || '').toLowerCase();
  const checkBizName = bizName.toLowerCase();
  if (
    checkCat === 'cat_ab5c5cd1' ||
    checkCat.includes('rental') ||
    checkCatName.includes('rental') ||
    checkCatName.includes('lease') ||
    checkSubName.includes('rental') ||
    checkBizName.includes('driving') ||
    checkBizName.includes('rental')
  ) {
    bType = 'rental';
  } else if (
    checkCat === 'cat_shops' ||
    checkCatName.includes('shop') ||
    checkCatName.includes('kirana')
  ) {
    bType = 'shop';
  }

  const newBiz = {
    id: `biz_${Date.now()}`,
    businessType: bType, // 'service' | 'shop' | 'rental'
    name: bizName,
    businessName: bizName,
    tradeCategory: body.tradeCategory || body.categoryId || 'cat_general',
    tradeCategoryName: catName,
    subCategoryId: body.subCategoryId || '',
    subCategoryName: body.subCategoryName || '',
    childCategoryId: body.childCategoryId || '',
    childCategoryName: body.childCategoryName || '',
    district: body.district || '',
    mandal: body.mandal || '',
    village: body.village || '',
    landmark: body.landmark || '',
    shopAddress: body.shopAddress || body.address || provider.address || '',
    phone: body.phone || provider.phone,
    shopTimings: body.shopTimings || '9:00 AM - 9:00 PM',
    shopPhotoUrl: body.shopPhotoUrl || '',
    licenseDocUrl: body.licenseDocUrl || '',
    status: 'pending', // 'pending' requires Admin Approval
    isActive: false,
    dutyStatus: 'OFF DUTY',
    storeStatus: 'OPEN',
    createdAt: new Date().toISOString()
  };

  provider.businesses.push(newBiz);
  db.save();

  res.status(201).json({
    success: true,
    message: 'New business profile submitted successfully. Pending Admin Approval.',
    business: newBiz
  });
};

// POST /api/providers/businesses/switch (Switch active business)
exports.switchActiveBusiness = (req, res) => {
  const providerId = req.user ? req.user.id : req.body.providerId;
  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  ensurePartnerBusinesses(provider);
  const { businessId } = req.body;

  const targetBiz = provider.businesses.find(b => b.id === businessId);
  if (!targetBiz) {
    return res.status(404).json({ success: false, message: 'Business profile not found' });
  }

  if (targetBiz.status !== 'approved') {
    return res.status(403).json({
      success: false,
      message: `Cannot switch to this business. Current status: ${targetBiz.status.toUpperCase()} (Pending Admin Approval)`
    });
  }

  // Update active state
  provider.businesses.forEach(b => {
    b.isActive = (b.id === businessId);
  });
  provider.activeBusinessId = businessId;

  // Sync provider top-level category if it is a service business
  if (targetBiz.businessType === 'service') {
    provider.category = targetBiz.tradeCategory;
    provider.categoryName = targetBiz.tradeCategoryName;
    if (targetBiz.subCategoryId) provider.subCategoryId = targetBiz.subCategoryId;
    if (targetBiz.subCategoryName) provider.subCategoryName = targetBiz.subCategoryName;
  }

  db.save();

  res.json({
    success: true,
    message: `Switched active dashboard to ${targetBiz.name}`,
    activeBusinessId: businessId,
    activeBusiness: targetBiz
  });
};

// POST /api/providers/businesses/public/approve
exports.approveBusinessPublic = (req, res) => {
  const { providerId, businessId } = req.body;
  const provider = db.data.providers.find(p => p.id === providerId);
  if (!provider) return res.status(404).json({ success: false, message: 'Provider not found' });
  const biz = (provider.businesses || []).find(b => b.id === businessId);
  if (!biz) return res.status(404).json({ success: false, message: 'Business not found' });
  biz.status = 'approved';
  biz.updatedAt = new Date().toISOString();
  db.save();
  res.json({ success: true, message: `Approved ${biz.name}`, business: biz });
};

// PUT /api/providers/businesses/:businessId (Update business profile info)
exports.updateBusiness = (req, res) => {
  const providerId = req.user ? req.user.id : (req.body.providerId || req.query.providerId);
  const { businessId } = req.params;
  const body = req.body;

  let provider;
  if (providerId) {
    provider = db.data.providers.find(p => p.id === providerId || p.phone === providerId);
  } else {
    provider = db.data.providers.find(p => Array.isArray(p.businesses) && p.businesses.some(b => b.id === businessId));
  }

  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  ensurePartnerBusinesses(provider);
  const biz = provider.businesses.find(b => b.id === businessId);
  if (!biz) {
    return res.status(404).json({ success: false, message: 'Business profile not found' });
  }

  if (body.name !== undefined) {
    biz.name = body.name.trim();
    biz.businessName = body.name.trim();
  }
  if (body.businessName !== undefined) {
    biz.name = body.businessName.trim();
    biz.businessName = body.businessName.trim();
  }
  if (body.shopAddress !== undefined) {
    biz.shopAddress = body.shopAddress.trim();
    biz.address = body.shopAddress.trim();
  }
  if (body.address !== undefined) {
    biz.shopAddress = body.address.trim();
    biz.address = body.address.trim();
  }
  if (body.phone !== undefined) biz.phone = body.phone.trim();
  if (body.landmark !== undefined) biz.landmark = body.landmark.trim();
  if (body.shopTimings !== undefined) biz.shopTimings = body.shopTimings;
  if (body.shopPhotoUrl !== undefined) biz.shopPhotoUrl = body.shopPhotoUrl;
  if (body.district !== undefined) biz.district = body.district;
  if (body.mandal !== undefined) biz.mandal = body.mandal;
  if (body.village !== undefined) biz.village = body.village;

  biz.updatedAt = new Date().toISOString();
  db.save();

  res.json({
    success: true,
    message: 'Business profile updated successfully',
    business: biz
  });
};

// DELETE /api/providers/businesses/:businessId (Delete closed business profile)
exports.deleteBusiness = (req, res) => {
  const providerId = req.user ? req.user.id : (req.body.providerId || req.query.providerId);
  const { businessId } = req.params;

  let provider;
  if (providerId) {
    provider = db.data.providers.find(p => p.id === providerId || p.phone === providerId);
  } else {
    provider = db.data.providers.find(p => Array.isArray(p.businesses) && p.businesses.some(b => b.id === businessId));
  }

  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  ensurePartnerBusinesses(provider);
  const initialLen = provider.businesses.length;
  provider.businesses = provider.businesses.filter(b => b.id !== businessId);

  if (provider.businesses.length === initialLen) {
    return res.status(404).json({ success: false, message: 'Business profile not found' });
  }

  // If the deleted business was active, switch to first remaining approved business
  if (provider.activeBusinessId === businessId) {
    const nextBiz = provider.businesses.find(b => b.status === 'approved') || provider.businesses[0];
    if (nextBiz) {
      provider.activeBusinessId = nextBiz.id;
      provider.businesses.forEach(b => b.isActive = (b.id === nextBiz.id));
    } else {
      provider.activeBusinessId = null;
    }
  }

  // Remove or clean up items attached to this business
  if (Array.isArray(db.data.rentals)) {
    db.data.rentals = db.data.rentals.filter(r => r.businessId !== businessId);
  }
  if (Array.isArray(db.data.products)) {
    db.data.products = db.data.products.filter(p => p.businessId !== businessId);
  }

  db.save();

  res.json({
    success: true,
    message: 'Business profile deleted successfully',
    activeBusinessId: provider.activeBusinessId,
    remainingCount: provider.businesses.length
  });
};
