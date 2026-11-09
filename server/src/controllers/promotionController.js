const db = require('../data/db');

// Initial default promotions matching customer app
const defaultPromotions = [
  // 1. Top Hero Carousel Banners
  {
    id: "promo_hero_1",
    type: "hero",
    tag: "100% SATISFACTION GUARANTEE",
    title: "Certified & Background Verified",
    subtitle: "Government Aadhaar & Police verified skilled technicians",
    cta: "Explore Fixes",
    badge: "VERIFIED",
    imageUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=900&auto=format&fit=crop&q=80",
    colors: ["#064e3b", "#047857", "#10b981"],
    icon: "shield-check",
    active: true,
    impressions: 1420,
    clicks: 312,
    priority: 1,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_hero_2",
    type: "hero",
    tag: "30-MIN DOORSTEP ARRIVAL",
    title: "Emergency Plumbing & Wiring",
    subtitle: "Flat 20% OFF on all repair bookings today",
    cta: "Book Instant",
    badge: "FLAT 20% OFF",
    imageUrl: "https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=900&auto=format&fit=crop&q=80",
    colors: ["#7c2d12", "#c2410c", "#f97316"],
    icon: "zap",
    active: true,
    impressions: 980,
    clicks: 194,
    priority: 2,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_hero_3",
    type: "hero",
    tag: "HYPERLOCAL EXPRESS",
    title: "Medicines & Daily Kirana Drop",
    subtitle: "Delivered to your doorstep in 15 mins",
    cta: "Send Package",
    badge: "15 MINS",
    imageUrl: "https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=900&auto=format&fit=crop&q=80",
    colors: ["#1e1b4b", "#4338ca", "#6366f1"],
    icon: "package",
    active: true,
    impressions: 870,
    clicks: 215,
    priority: 3,
    createdAt: new Date().toISOString()
  },

  // 2. Local Spotlight & Grand Openings Billboard
  {
    id: "promo_spotlight_1",
    type: "spotlight",
    tag: "🌟 GRAND SHOWROOM OPENING",
    title: "Sri Krishna Jewellers",
    offer: "Flat 25% OFF on Making Charges + Free Gold Coin!",
    description: "Exclusive 916 Hallmark Gold & Diamond Collection. Grand opening celebration live today!",
    location: "Main Road, Madhapur (Opp. Metro Pillar 14)",
    imageUrl: "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&auto=format&fit=crop&q=80",
    badge: "GOLD SHOP OPENING",
    colors: ["#381A00", "#B45309", "#D97706"],
    cta: "Explore Gold Offers",
    icon: "diamond",
    active: true,
    impressions: 2850,
    clicks: 640,
    priority: 1,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_spotlight_2",
    type: "spotlight",
    tag: "🛍️ MEGA RETAIL LAUNCH",
    title: "South India Silk & Fashion Mall",
    offer: "Buy 1 Get 1 Free on Designer Silk Sarees",
    description: "Celebrity ribbon-cutting & inaugural mega discounts on all wedding collections & ethnic wear.",
    location: "Jubilee Hills Checkpost, Road No. 36",
    imageUrl: "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80",
    badge: "MALL OPENING",
    colors: ["#1E1B4B", "#4338CA", "#6366F1"],
    cta: "View Collections",
    icon: "shopping-bag",
    active: true,
    impressions: 2100,
    clicks: 480,
    priority: 2,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_spotlight_3",
    type: "spotlight",
    tag: "🍽️ FOOD MEGA INAUGURATION",
    title: "Paradise Royal Dum Biryani",
    offer: "Complimentary Dessert & Buy 2 Get 1 Free",
    description: "Authentic Nizami flavors, family dining & royal ambience. Inaugural festive feast for all foodies!",
    location: "Hitec City, Cyber Towers Road",
    imageUrl: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=900&auto=format&fit=crop&q=80",
    badge: "NEW BRANCH OPEN",
    colors: ["#310B0B", "#991B1B", "#DC2626"],
    cta: "Reserve Table / Order",
    icon: "utensils",
    active: true,
    impressions: 1950,
    clicks: 390,
    priority: 3,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_spotlight_4",
    type: "spotlight",
    tag: "⚡ SMART TECH SHOWROOM",
    title: "Croma Mega Electronics",
    offer: "Up to 50% OFF on 4K Smart TVs & Smartphones",
    description: "Exclusive inaugural zero-cost EMI + free soundbar with select appliances. Grand opening week!",
    location: "Inorbit Mall Road, Mindspace Circle",
    imageUrl: "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=900&auto=format&fit=crop&q=80",
    badge: "TECH LAUNCH",
    colors: ["#0F172A", "#0284C7", "#0EA5E9"],
    cta: "Grab Electronics Deals",
    icon: "tv",
    active: true,
    impressions: 1620,
    clicks: 310,
    priority: 4,
    createdAt: new Date().toISOString()
  },

  // 3. Exclusive Deals & Offers (Sponsored Ads Carousel)
  {
    id: "promo_deal_1",
    type: "deal",
    tag: "APPLIANCE CARE",
    badge: "LIMITED SLOTS",
    title: "AC Gas Refill & Jet Foam Service",
    subtitle: "Pre-summer discount starts at just ₹399",
    offer: "Starts at ₹399",
    cta: "Grab Deal",
    imageUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&auto=format&fit=crop&q=80",
    colors: ["#2A1706", "#9A4A0A", "#D97706"],
    icon: "snowflake",
    active: true,
    impressions: 1350,
    clicks: 290,
    priority: 1,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_deal_2",
    type: "deal",
    tag: "EMERGENCY FIX",
    badge: "FLAT ₹100 OFF",
    title: "Bike & Car Breakdown Assistance",
    subtitle: "Mechanic reaches in 15 mins with battery jumpstart",
    offer: "Flat ₹100 OFF",
    cta: "Get Help",
    imageUrl: "https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&auto=format&fit=crop&q=80",
    colors: ["#2B1B2A", "#831843", "#BE185D"],
    icon: "car",
    active: true,
    impressions: 1780,
    clicks: 410,
    priority: 2,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_deal_3",
    type: "deal",
    tag: "INSTANT COURIER",
    badge: "FASTEST PICKUP",
    title: "Pick & Drop Any Item Across City",
    subtitle: "Medicines, keys, food, documents within 20 mins",
    offer: "Flat ₹40 OFF",
    cta: "Order Drop",
    imageUrl: "https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&auto=format&fit=crop&q=80",
    colors: ["#062822", "#065F46", "#059669"],
    icon: "bike",
    active: true,
    impressions: 940,
    clicks: 180,
    priority: 3,
    createdAt: new Date().toISOString()
  },
  {
    id: "promo_deal_4",
    type: "deal",
    tag: "HOME MAKEOVER",
    badge: "FLAT ₹300 OFF",
    title: "Deep Home Cleaning & Pest Shield",
    subtitle: "Full bathroom, kitchen & sofa sanitization",
    offer: "Flat ₹300 OFF",
    cta: "Book Pro",
    imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&auto=format&fit=crop&q=80",
    colors: ["#1E1B4B", "#3730A3", "#4F46E5"],
    icon: "sparkles",
    active: true,
    impressions: 1120,
    clicks: 230,
    priority: 4,
    createdAt: new Date().toISOString()
  },

  // 4. Post-Login Grand Opening Popups
  {
    id: "promo_popup_1",
    type: "popup",
    storeName: "Kalanikethan Silks & Fashion Mall",
    tag: "GRAND SHOWROOM OPENING",
    badge: "EXCLUSIVE FESTIVAL SALE",
    title: "Kalanikethan Silks & Fashion Mall",
    offer: "FLAT 50% OFF",
    offerDetails: "On All Designer Sarees, Ethnic & Western Collections",
    promoCode: "LOKIFASHION50",
    voucherValue: "₹500",
    location: "Main Road, Madhapur (Opp. Metro Pillar 118)",
    imageUrl: "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80",
    perks: ["Pure Silk Sarees", "Menswear & Suits", "Kids Festive Wear"],
    giftNote: "🎁 First 100 Walk-in Customers get a Free 22K Gold Coin + ₹500 Voucher!",
    cta: "Claim ₹500 Voucher & Visit Store",
    colors: ["#831843", "#BE185D", "#FB7185"],
    active: true,
    impressions: 3400,
    clicks: 980,
    priority: 1,
    createdAt: new Date().toISOString()
  }
];

// Helper to ensure db has promotions
const ensurePromotions = () => {
  if (!db.data.promotions || db.data.promotions.length === 0) {
    db.data.promotions = [...defaultPromotions];
    db.save();
  }
  return db.data.promotions;
};

// GET /api/promotions (Public for Customer App & Admin)
exports.getAllPromotions = async (req, res) => {
  try {
    const list = ensurePromotions();
    const { type, active } = req.query;

    const now = new Date();
    let filtered = [...list];
    if (type && type !== 'all') {
      filtered = filtered.filter(p => p.type === type);
    }
    if (active !== undefined) {
      const isActive = active === 'true' || active === true;
      filtered = filtered.filter(p => {
        if (p.active !== isActive) return false;
        if (isActive && p.expiryDate) {
          const exp = new Date(p.expiryDate);
          exp.setHours(23, 59, 59, 999);
          if (exp < now) return false; // automatically hide expired banners from active customer app views
        }
        return true;
      });
    }

    filtered = filtered.map(p => {
      let isExpired = false;
      if (p.expiryDate) {
        const exp = new Date(p.expiryDate);
        exp.setHours(23, 59, 59, 999);
        isExpired = exp < now;
      }
      return { ...p, isExpired };
    });

    // Sort by priority ascending, then createdAt descending
    filtered.sort((a, b) => (a.priority || 99) - (b.priority || 99));

    res.json({
      success: true,
      count: filtered.length,
      data: filtered,
      grouped: {
        hero: filtered.filter(p => p.type === 'hero'),
        spotlight: filtered.filter(p => p.type === 'spotlight'),
        deal: filtered.filter(p => p.type === 'deal'),
        popup: filtered.filter(p => p.type === 'popup')
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/promotions/:id
exports.getPromotionById = async (req, res) => {
  try {
    const list = ensurePromotions();
    const item = list.find(p => p.id === req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Promotion not found' });
    }
    res.json({ success: true, data: item });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/promotions (Create New Ad)
exports.createPromotion = async (req, res) => {
  try {
    const list = ensurePromotions();
    const body = req.body;

    const newId = `promo_${body.type || 'ad'}_${Date.now()}`;
    const newPromotion = {
      id: newId,
      type: body.type || 'deal',
      title: body.title || '',
      tag: body.tag || '',
      badge: body.badge || '',
      offer: body.offer || '',
      subtitle: body.subtitle || '',
      description: body.description || '',
      location: body.location || '',
      imageUrl: body.imageUrl || '',
      cta: body.cta || '',
      colors: Array.isArray(body.colors) && body.colors.length >= 2 ? body.colors : ['#1E293B', '#334155', '#475569'],
      icon: body.icon || 'sparkles',
      promoCode: body.promoCode || '',
      voucherValue: body.voucherValue || '',
      giftNote: body.giftNote || '',
      perks: Array.isArray(body.perks) ? body.perks : (body.perks ? body.perks.split(',').map(s => s.trim()) : []),
      expiryDate: body.expiryDate || null,
      active: body.active !== undefined ? body.active : true,
      priority: Number(body.priority) || 1,
      impressions: 0,
      clicks: 0,
      createdAt: new Date().toISOString()
    };

    list.unshift(newPromotion);
    db.save();

    res.status(201).json({
      success: true,
      message: 'Ad banner created successfully',
      data: newPromotion
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// PUT /api/promotions/:id (Update Ad)
exports.updatePromotion = async (req, res) => {
  try {
    const list = ensurePromotions();
    const idx = list.findIndex(p => p.id === req.params.id);
    if (idx === -1) {
      return res.status(404).json({ success: false, message: 'Promotion not found' });
    }

    const current = list[idx];
    const body = req.body;

    list[idx] = {
      ...current,
      ...body,
      id: current.id, // prevent ID overwrite
      updatedAt: new Date().toISOString()
    };

    db.save();

    res.json({
      success: true,
      message: 'Ad banner updated successfully',
      data: list[idx]
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// PATCH /api/promotions/:id/toggle (Quick Toggle Active/Inactive)
exports.togglePromotionActive = async (req, res) => {
  try {
    const list = ensurePromotions();
    const item = list.find(p => p.id === req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Promotion not found' });
    }

    item.active = !item.active;
    item.updatedAt = new Date().toISOString();
    db.save();

    res.json({
      success: true,
      message: `Ad is now ${item.active ? 'Active' : 'Paused'}`,
      data: item
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE /api/promotions/:id
exports.deletePromotion = async (req, res) => {
  try {
    let list = ensurePromotions();
    const initialLen = list.length;
    list = list.filter(p => p.id !== req.params.id);

    if (list.length === initialLen) {
      return res.status(404).json({ success: false, message: 'Promotion not found' });
    }

    db.data.promotions = list;
    db.save();

    res.json({
      success: true,
      message: 'Ad banner deleted successfully',
      id: req.params.id
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

