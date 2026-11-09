const db = require('../data/db');

// Ensure db.data.rentals exists
function ensureRentals() {
  if (!db.data.rentals) {
    db.data.rentals = [
      {
        id: "rent_sample_1",
        postedBy: "customer",
        userId: "usr_sample_1",
        userName: "K. Satyanarayana",
        phone: "9848022334",
        whatsappPhone: "9848022334",
        listingType: "owner", // "owner" (Direct Owner)
        category: "properties",
        categoryName: "Properties & Real Estate",
        subCategory: "Houses & Independent Flats",
        childCategory: "2BHK",
        title: "Spacious 2BHK House for Rent in Chodavaram",
        description: "East facing, 24/7 municipal water, dedicated two-wheeler and car parking. Peaceful residential colony near RCM Church.",
        rentPrice: 8500,
        rentPeriod: "month",
        deposit: 20000,
        stockCount: 1,
        images: [
          "https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=900&auto=format&fit=crop&q=80",
          "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=900&auto=format&fit=crop&q=80"
        ],
        location: "Beside RCM Church, Chodavaram Town",
        district: "Anakapalli",
        status: "available",
        viewsCount: 24,
        isApproved: true,
        createdAt: new Date().toISOString()
      },
      {
        id: "rent_sample_2",
        postedBy: "partner",
        providerId: "prv_76fcc359",
        businessId: "biz_tenthouse_1001",
        businessName: "Sri Lakshmi Tent House & Event Rentals",
        userName: "Gandepalli Prasad",
        phone: "9010737882",
        whatsappPhone: "9010737882",
        listingType: "store", // "store" (Verified Rental Store)
        category: "events",
        categoryName: "Events & Functions",
        subCategory: "Shamiaana, Tents & Chairs",
        childCategory: "VIP Banquet Chairs",
        title: "VIP Plastic Chairs & Event Shamiana Setup",
        description: "500+ Heavy-duty VIP plastic chairs, wedding Shamiana sets, stage lighting, and sound systems for all functions and gatherings.",
        rentPrice: 10,
        rentPeriod: "day",
        deposit: 1000,
        stockCount: 500,
        images: [
          "https://images.unsplash.com/photo-1519741497674-611481863552?w=900&auto=format&fit=crop&q=80",
          "https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=900&auto=format&fit=crop&q=80"
        ],
        location: "Station Road, Chodavaram Town",
        district: "Anakapalli",
        status: "available",
        viewsCount: 58,
        isApproved: true,
        createdAt: new Date().toISOString()
      },
      {
        id: "rent_sample_3",
        postedBy: "partner",
        providerId: "prv_sample_car",
        businessId: "biz_car_rental",
        businessName: "Anakapalli Self-Drive & Taxi Rentals",
        userName: "S. Venkatesh",
        phone: "9848055667",
        whatsappPhone: "9848055667",
        listingType: "store",
        category: "vehicles",
        categoryName: "Vehicles & Transport",
        subCategory: "Cars & Self-Drive",
        childCategory: "7-Seater Ertiga / Innova",
        title: "Maruti Ertiga 7-Seater (Self Drive / With Driver)",
        description: "Clean, sanitized 2023 model Ertiga. Available for outstation trips, family functions, and local travel. Fastag enabled.",
        rentPrice: 2200,
        rentPeriod: "day",
        deposit: 5000,
        stockCount: 3,
        images: [
          "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=900&auto=format&fit=crop&q=80"
        ],
        location: "RTC Complex, Chodavaram",
        district: "Anakapalli",
        status: "available",
        viewsCount: 42,
        isApproved: true,
        createdAt: new Date().toISOString()
      },
      {
        id: "rent_sample_4",
        postedBy: "customer",
        userId: "usr_sample_2",
        userName: "Ramesh Kumar",
        phone: "9848011223",
        whatsappPhone: "9848011223",
        listingType: "owner",
        category: "furniture",
        categoryName: "Furniture & Home Living",
        subCategory: "Cots & Mattresses",
        childCategory: "Teak Wood Double Cot",
        title: "Solid Teak Wood Double Cot with Sleepwell Mattress",
        description: "Queen size (6x5 ft) durable teak wood bed. Comes with clean spring mattress. Ideal for bachelor or family rent.",
        rentPrice: 600,
        rentPeriod: "month",
        deposit: 2000,
        stockCount: 1,
        images: [
          "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=900&auto=format&fit=crop&q=80"
        ],
        location: "Kothapeta, Chodavaram",
        district: "Anakapalli",
        status: "available",
        viewsCount: 19,
        isApproved: true,
        createdAt: new Date().toISOString()
      },
      {
        id: "rent_sample_5",
        postedBy: "customer",
        userId: "usr_sample_3",
        userName: "V. Lakshmi",
        phone: "9848033445",
        whatsappPhone: "9848033445",
        listingType: "owner",
        category: "appliances",
        categoryName: "Electronics & Gadgets",
        subCategory: "Home Appliances",
        childCategory: "1.5 Ton Split AC",
        title: "Voltas 1.5 Ton 5-Star Split AC (Summer Rental)",
        description: "Power-saving copper condenser 5-star AC. Regular servicing done, super fast cooling with remote.",
        rentPrice: 1500,
        rentPeriod: "month",
        deposit: 3000,
        stockCount: 1,
        images: [
          "https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=900&auto=format&fit=crop&q=80"
        ],
        location: "Old Bus Stand Road, Chodavaram",
        district: "Anakapalli",
        status: "available",
        viewsCount: 31,
        isApproved: true,
        createdAt: new Date().toISOString()
      }
    ];
    db.save();
  }
  return db.data.rentals;
}

// GET /api/rentals
exports.getAllRentals = async (req, res) => {
  try {
    const list = ensureRentals();
    const { category, subCategory, childCategory, listingType, search, location, minPrice, maxPrice, status } = req.query;

    let filtered = [...list];

    // Filter by approval status
    filtered = filtered.filter(item => item.isApproved !== false);

    // Filter by status (available / rented)
    if (status) {
      filtered = filtered.filter(item => (item.status || 'available').toLowerCase() === status.toLowerCase());
    }

    // Filter by main category
    if (category && category !== 'all') {
      filtered = filtered.filter(item => item.category && item.category.toLowerCase() === category.toLowerCase());
    }

    // Filter by subcategory
    if (subCategory && subCategory !== 'all') {
      const sc = subCategory.toLowerCase();
      filtered = filtered.filter(item => 
        (item.subCategory && item.subCategory.toLowerCase().includes(sc)) ||
        (item.category && item.category.toLowerCase().includes(sc)) ||
        (item.categoryName && item.categoryName.toLowerCase().includes(sc))
      );
    }

    // Filter by child category
    if (childCategory && childCategory !== 'all') {
      const cc = childCategory.toLowerCase();
      filtered = filtered.filter(item =>
        (item.childCategory && item.childCategory.toLowerCase().includes(cc)) ||
        (item.title && item.title.toLowerCase().includes(cc)) ||
        (item.description && item.description.toLowerCase().includes(cc))
      );
    }

    // Filter by listing type (owner vs store)
    if (listingType && listingType !== 'all') {
      filtered = filtered.filter(item => (item.listingType || 'owner').toLowerCase() === listingType.toLowerCase());
    }

    // Search query
    if (search) {
      const q = search.toLowerCase();
      filtered = filtered.filter(item =>
        (item.title && item.title.toLowerCase().includes(q)) ||
        (item.description && item.description.toLowerCase().includes(q)) ||
        (item.location && item.location.toLowerCase().includes(q)) ||
        (item.subCategory && item.subCategory.toLowerCase().includes(q))
      );
    }

    // Sort newest first
    filtered.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({
      success: true,
      count: filtered.length,
      data: filtered
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/rentals/:id
exports.getRentalById = async (req, res) => {
  try {
    const list = ensureRentals();
    const item = list.find(r => r.id === req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Rental post not found' });
    }
    // Increment views
    item.viewsCount = (item.viewsCount || 0) + 1;
    db.save();

    res.json({
      success: true,
      data: item
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/rentals (Customer or Partner creates a new rental listing)
exports.createRental = async (req, res) => {
  try {
    const list = ensureRentals();
    const body = req.body;

    if (!body.title || !body.rentPrice) {
      return res.status(400).json({ success: false, message: 'Title and Rent Price are required' });
    }

    const newId = `rent_${Date.now()}`;
    const newRental = {
      id: newId,
      postedBy: body.postedBy || (req.user && req.user.role === 'provider' ? 'partner' : 'customer'),
      userId: body.userId || (req.user ? req.user.id : null),
      providerId: body.providerId || (req.user && req.user.role === 'provider' ? req.user.id : null),
      businessId: body.businessId || null,
      businessName: body.businessName || '',
      userName: body.userName || (req.user ? req.user.name : 'Verified User'),
      phone: body.phone || (req.user ? req.user.phone : ''),
      whatsappPhone: body.whatsappPhone || body.phone || '',
      listingType: body.listingType || (body.postedBy === 'partner' ? 'store' : 'owner'),
      category: body.category || 'properties',
      categoryName: body.categoryName || 'Properties & Real Estate',
      subCategory: body.subCategory || 'General',
      childCategory: body.childCategory || '',
      title: body.title.trim(),
      description: (body.description || '').trim(),
      rentPrice: Number(body.rentPrice) || 0,
      rentPeriod: body.rentPeriod || 'month', // 'day' or 'month'
      deposit: Number(body.deposit) || 0,
      stockCount: Number(body.stockCount) || 1,
      images: Array.isArray(body.images) && body.images.length > 0
        ? body.images
        : [body.imageUrl || 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=900'],
      location: body.location || 'Chodavaram, Anakapalli',
      district: body.district || 'Anakapalli',
      mandal: body.mandal || '',
      village: body.village || '',
      landmark: body.landmark || '',
      latitude: body.latitude ? Number(body.latitude) : null,
      longitude: body.longitude ? Number(body.longitude) : null,
      specifications: body.specifications || {},
      status: 'available',
      viewsCount: 0,
      isApproved: true,
      createdAt: new Date().toISOString()
    };

    list.unshift(newRental);
    db.save();

    res.status(201).json({
      success: true,
      message: 'Rental listing published successfully',
      data: newRental
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// PUT /api/rentals/:id
exports.updateRental = async (req, res) => {
  try {
    const list = ensureRentals();
    const idx = list.findIndex(r => r.id === req.params.id);
    if (idx === -1) {
      return res.status(404).json({ success: false, message: 'Rental listing not found' });
    }

    const item = list[idx];
    const body = req.body;

    if (body.title !== undefined) item.title = body.title.trim();
    if (body.description !== undefined) item.description = body.description.trim();
    if (body.rentPrice !== undefined) item.rentPrice = Number(body.rentPrice);
    if (body.rentPeriod !== undefined) item.rentPeriod = body.rentPeriod;
    if (body.deposit !== undefined) item.deposit = Number(body.deposit);
    if (body.stockCount !== undefined) item.stockCount = Number(body.stockCount);
    if (body.status !== undefined) item.status = body.status; // 'available' or 'rented'
    if (body.images !== undefined) item.images = body.images;
    if (body.location !== undefined) item.location = body.location;
    if (body.subCategory !== undefined) item.subCategory = body.subCategory;
    if (body.childCategory !== undefined) item.childCategory = body.childCategory;
    if (body.category !== undefined) item.category = body.category;
    if (body.categoryName !== undefined) item.categoryName = body.categoryName;
    if (body.district !== undefined) item.district = body.district;
    if (body.mandal !== undefined) item.mandal = body.mandal;
    if (body.village !== undefined) item.village = body.village;
    if (body.landmark !== undefined) item.landmark = body.landmark;
    if (body.phone !== undefined) {
      item.phone = body.phone;
      item.whatsappPhone = body.whatsappPhone || body.phone;
    }
    if (body.latitude !== undefined) item.latitude = body.latitude ? Number(body.latitude) : null;
    if (body.longitude !== undefined) item.longitude = body.longitude ? Number(body.longitude) : null;
    if (body.specifications !== undefined) item.specifications = { ...(item.specifications || {}), ...body.specifications };

    list[idx] = item;
    db.save();

    res.json({
      success: true,
      message: 'Rental listing updated successfully',
      data: item
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE /api/rentals/:id
exports.deleteRental = async (req, res) => {
  try {
    let list = ensureRentals();
    const initialLen = list.length;
    list = list.filter(r => r.id !== req.params.id);

    if (list.length === initialLen) {
      return res.status(404).json({ success: false, message: 'Rental listing not found' });
    }

    db.data.rentals = list;
    db.save();

    res.json({
      success: true,
      message: 'Rental listing deleted successfully',
      id: req.params.id
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/rentals/user/:phoneOrId
exports.getUserRentals = async (req, res) => {
  try {
    const list = ensureRentals();
    const identifier = req.params.phoneOrId;
    const { businessId, role } = req.query;

    let userPosts = list.filter(r =>
      r.phone === identifier ||
      r.userId === identifier ||
      r.providerId === identifier ||
      (r.businessId && r.businessId === identifier)
    );

    // Strict multi-business isolation:
    if (businessId && businessId.trim() !== '') {
      userPosts = userPosts.filter(r => r.businessId === businessId.trim());
    } else if (role === 'partner') {
      // Exclude customer personal properties from commercial merchant dashboard
      userPosts = userPosts.filter(r => r.postedBy === 'partner' || r.listingType === 'store');
    }

    res.json({
      success: true,
      count: userPosts.length,
      data: userPosts
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

