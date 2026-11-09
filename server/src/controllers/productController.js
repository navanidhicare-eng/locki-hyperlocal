const db = require('../data/db');

// Ensure db.data.products exists with initial seed
function ensureProducts() {
  if (!db.data.products) {
    db.data.products = [
      {
        id: "prod_sample_1",
        providerId: "prv_76fcc359",
        businessId: "biz_kirana_sample",
        businessName: "Sri Balaji Kirana & General Stores",
        phone: "9010737882",
        name: "Sona Masoori Premium Rice (25kg Bag)",
        price: 1350,
        unit: "25kg Bag",
        category: "cat_shops",
        categoryName: "Local Shops & Kirana",
        subCategory: "Groceries & Rice",
        description: "1 year aged fine quality Sona Masoori raw rice. Free delivery in town.",
        inStock: true,
        images: [
          "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80"
        ],
        createdAt: new Date().toISOString()
      },
      {
        id: "prod_sample_2",
        providerId: "prv_76fcc359",
        businessId: "biz_kirana_sample",
        businessName: "Sri Balaji Kirana & General Stores",
        phone: "9010737882",
        name: "Freedom Refined Sunflower Oil (1 Litre Pouch)",
        price: 135,
        unit: "1 Litre Pouch",
        category: "cat_shops",
        categoryName: "Local Shops & Kirana",
        subCategory: "Cooking Oils & Ghee",
        description: "Pure refined sunflower oil with vitamins A & D.",
        inStock: true,
        images: [
          "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80"
        ],
        createdAt: new Date().toISOString()
      },
      {
        id: "prod_sample_3",
        providerId: "prv_76fcc359",
        businessId: "biz_kirana_sample",
        businessName: "Sri Balaji Kirana & General Stores",
        phone: "9010737882",
        name: "Aashirvaad Superior MP Sharbati Atta (10kg)",
        price: 490,
        unit: "10kg Bag",
        category: "cat_shops",
        categoryName: "Local Shops & Kirana",
        subCategory: "Atta, Flours & Grains",
        description: "100% pure whole wheat grain chakki fresh atta.",
        inStock: true,
        images: [
          "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80"
        ],
        createdAt: new Date().toISOString()
      }
    ];
    db.save();
  }
  return db.data.products;
}

// GET /api/products/user/:phoneOrId (Products posted by a specific partner/shop)
exports.getUserProducts = (req, res) => {
  try {
    const list = ensureProducts();
    const { phoneOrId } = req.params;
    const { businessId } = req.query;

    let userProds = list.filter(item =>
      item.phone === phoneOrId ||
      item.providerId === phoneOrId ||
      (item.businessId && item.businessId === phoneOrId)
    );

    if (businessId) {
      userProds = userProds.filter(item => item.businessId === businessId);
    }

    res.json({
      success: true,
      count: userProds.length,
      products: userProds
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/products (All products for customer app)
exports.getAllProducts = (req, res) => {
  try {
    const list = ensureProducts();
    const { category, subCategory, search, inStock } = req.query;

    let filtered = [...list];

    if (inStock === 'true') {
      filtered = filtered.filter(p => p.inStock !== false);
    }

    if (category && category !== 'all') {
      filtered = filtered.filter(p => p.category === category || p.categoryName?.toLowerCase().includes(category.toLowerCase()));
    }

    if (req.query.businessId) {
      filtered = filtered.filter(p => p.businessId === req.query.businessId);
    }
    if (req.query.providerId) {
      filtered = filtered.filter(p => p.providerId === req.query.providerId);
    }

    if (subCategory && subCategory !== 'all') {
      filtered = filtered.filter(p => p.subCategory?.toLowerCase().includes(subCategory.toLowerCase()));
    }

    if (search) {
      const q = search.toLowerCase();
      filtered = filtered.filter(p =>
        (p.name && p.name.toLowerCase().includes(q)) ||
        (p.description && p.description.toLowerCase().includes(q)) ||
        (p.businessName && p.businessName.toLowerCase().includes(q))
      );
    }

    res.json({
      success: true,
      count: filtered.length,
      products: filtered
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/products (Add a new product to shop catalog with Quota Enforcement)
exports.createProduct = (req, res) => {
  try {
    const list = ensureProducts();
    const body = req.body;

    if (!body.name || !body.price) {
      return res.status(400).json({ success: false, message: 'Product name and price are required' });
    }

    let providerId = body.providerId || (req.user ? req.user.id : null);
    let phone = body.phone || (req.user ? req.user.phone : '');

    const provider = providerId 
      ? db.data.providers.find(p => p.id === providerId || (phone && p.phone === phone))
      : (phone ? db.data.providers.find(p => p.phone === phone) : null);

    if (provider) {
      if (!providerId) providerId = provider.id;
      if (!phone) phone = provider.phone;
    }

    // Check partner's listing quota
    if (providerId) {
      const allowedQuota = (provider && (provider.listingQuota || provider.topUpQuota))
        ? ((provider.listingQuota || 10) + (provider.topUpQuota || 0))
        : 10;

      const currentCount = list.filter(p => p.providerId === providerId || (phone && p.phone === phone)).length;
      if (currentCount >= allowedQuota) {
        return res.status(403).json({
          success: false,
          quotaExceeded: true,
          currentCount,
          allowedQuota,
          message: `Product quota exceeded! Your plan allows ${allowedQuota} products (${currentCount} already listed). Please contact Admin for extra products top-up.`
        });
      }
    }

    // Auto-detect business name if not passed
    let businessName = body.businessName;
    if (!businessName && body.businessId && provider?.businesses) {
      const b = provider.businesses.find(x => x.id === body.businessId);
      if (b) businessName = b.name || b.businessName;
    }

    const newProd = {
      id: `prod_${Date.now()}`,
      providerId: providerId || 'prv_general',
      businessId: body.businessId || null,
      businessName: businessName || 'Local Store',
      phone: phone || '',
      name: body.name.trim(),
      price: Number(body.price),
      unit: body.unit || '1 Piece',
      category: body.category || 'cat_shops',
      categoryName: body.categoryName || 'Local Shops & Kirana',
      subCategory: body.subCategory || 'General Items',
      description: body.description || '',
      inStock: body.inStock !== false,
      images: Array.isArray(body.images) && body.images.length > 0 ? body.images : [
        "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80"
      ],
      createdAt: new Date().toISOString()
    };

    list.unshift(newProd);
    db.save();

    res.status(201).json({
      success: true,
      message: 'Product added to store catalog successfully',
      product: newProd
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// PUT /api/products/:id (Edit product or toggle inStock)
exports.updateProduct = (req, res) => {
  try {
    const list = ensureProducts();
    const { id } = req.params;
    const index = list.findIndex(p => p.id === id);

    if (index === -1) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    list[index] = {
      ...list[index],
      ...req.body,
      updatedAt: new Date().toISOString()
    };
    db.save();

    res.json({
      success: true,
      message: 'Product updated successfully',
      product: list[index]
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE /api/products/:id
exports.deleteProduct = (req, res) => {
  try {
    const list = ensureProducts();
    const { id } = req.params;
    const index = list.findIndex(p => p.id === id);

    if (index === -1) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    list.splice(index, 1);
    db.save();

    res.json({
      success: true,
      message: 'Product removed from store catalog'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
