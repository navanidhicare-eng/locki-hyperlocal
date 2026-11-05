const db = require('../data/db');

exports.getDashboardStats = (req, res) => {
  const totalOrders = db.data.orders.length;
  const completedOrders = db.data.orders.filter(o => o.orderStatus === 'COMPLETED');
  const activeOrders = db.data.orders.filter(o => ['PENDING', 'ACCEPTED', 'IN_PROGRESS'].includes(o.orderStatus));

  const totalRevenue = completedOrders.reduce((sum, o) => sum + (o.amount || 0), 0);
  const platformEarnings = Math.round(totalRevenue * 0.10); // 10% platform commission

  const totalProviders = db.data.providers.length;
  const onlineProviders = db.data.providers.filter(p => p.isOnline).length;
  const pendingKycCount = db.data.providers.filter(p => p.kycStatus === 'pending').length;

  const totalCustomers = db.data.users.filter(u => u.role === 'customer').length;

  // Breakdown by category
  const categoryStats = db.data.categories.map(c => {
    const ordersInCat = db.data.orders.filter(o => o.category === c.id);
    const revenueInCat = ordersInCat.reduce((sum, o) => sum + (o.amount || 0), 0);
    return {
      id: c.id,
      name: c.name,
      icon: c.icon,
      color: c.color,
      totalOrders: ordersInCat.length,
      revenue: revenueInCat,
      providersCount: db.data.providers.filter(p => p.category === c.id).length
    };
  });

  res.json({
    success: true,
    stats: {
      totalRevenue,
      platformEarnings,
      totalOrders,
      activeOrdersCount: activeOrders.length,
      completedOrdersCount: completedOrders.length,
      totalProviders,
      onlineProviders,
      pendingKycCount,
      totalCustomers
    },
    categoryStats,
    recentOrders: db.data.orders.slice(0, 8),
    pendingKycPartners: db.data.providers.filter(p => p.kycStatus === 'pending')
  });
};

const ensureSeedUsersAndProviders = () => {
  // Purged dummy data: real customer & partner accounts will be populated via registration
};

exports.getAllProviders = (req, res) => {
  ensureSeedUsersAndProviders();
  const { kycStatus } = req.query;
  let list = db.data.providers;
  if (kycStatus) {
    list = list.filter(p => p.kycStatus === kycStatus);
  }

  const safeList = list.map(p => {
    const copy = { ...p };
    delete copy.passwordHash;
    return copy;
  });

  res.json({ success: true, count: safeList.length, providers: safeList });
};

exports.updateKycStatus = (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // 'approved' or 'rejected'

  if (!['approved', 'rejected', 'pending'].includes(status)) {
    return res.status(400).json({ success: false, message: 'Status must be approved, rejected or pending' });
  }

  const provider = db.data.providers.find(p => p.id === id);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  provider.kycStatus = status;
  if (status === 'rejected') {
    provider.isOnline = false;
  }
  db.save();

  const io = req.app.get('io');
  if (io) {
    io.emit('provider:kyc_updated', { providerId: provider.id, status });
  }

  res.json({
    success: true,
    message: `Provider KYC ${status.toUpperCase()} successfully`,
    provider: { id: provider.id, name: provider.name, kycStatus: provider.kycStatus }
  });
};

exports.updateProviderSubscription = (req, res) => {
  const { id } = req.params;
  const { status, paymentMethod = 'cash', amount = 1999, months = 12 } = req.body;

  const provider = db.data.providers.find(p => p.id === id);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  if (status === 'active') {
    provider.subscriptionStatus = 'active';
    provider.subscriptionPaymentMethod = paymentMethod;
    provider.subscriptionAmount = amount;
    provider.subscriptionMonths = parseInt(months);
    provider.subscriptionPlanName = parseInt(months) === 1 ? '1-Month Trial' : (parseInt(months) === 3 ? '3-Months Quarter' : (parseInt(months) === 6 ? '6-Months Half-Year' : '1-Year Annual Pro'));
    provider.subscriptionPaidAt = new Date().toISOString();
    const expiry = new Date();
    expiry.setMonth(expiry.getMonth() + parseInt(months));
    provider.subscriptionExpiresAt = expiry.toISOString();
  } else {
    provider.subscriptionStatus = 'unpaid';
    provider.subscriptionExpiresAt = null;
    provider.subscriptionPlanName = null;
  }

  db.save();

  const io = req.app.get('io');
  if (io) {
    io.emit('provider:subscription_updated', {
      providerId: provider.id,
      subscriptionStatus: provider.subscriptionStatus,
      subscriptionExpiresAt: provider.subscriptionExpiresAt
    });
  }

  res.json({
    success: true,
    message: `Subscription successfully updated to ${provider.subscriptionStatus.toUpperCase()}`,
    provider: {
      id: provider.id,
      name: provider.name,
      subscriptionStatus: provider.subscriptionStatus,
      subscriptionExpiresAt: provider.subscriptionExpiresAt,
      subscriptionPaymentMethod: provider.subscriptionPaymentMethod,
      subscriptionAmount: provider.subscriptionAmount
    }
  });
};

exports.getAllUsers = (req, res) => {
  ensureSeedUsersAndProviders();
  const customers = db.data.users.filter(u => u.role === 'customer').map(u => {
    const copy = { ...u };
    delete copy.passwordHash;
    return copy;
  });

  res.json({ success: true, count: customers.length, users: customers });
};

// Create Customer
exports.createCustomer = (req, res) => {
  const { name, phone, email, address, district, mandal, village } = req.body;
  if (!name || !phone) {
    return res.status(400).json({ success: false, message: 'Name and phone are required' });
  }

  const { v4: uuidv4 } = require('uuid');
  const newCustomer = {
    id: `usr_cust_${uuidv4().substring(0, 8)}`,
    name: name.trim(),
    phone: phone.trim(),
    email: email?.trim() || `${phone.replace(/\s+/g, '')}@loki.customer`,
    address: address?.trim() || (village ? `${village}, ${mandal}, ${district}` : 'Hyderabad, Telangana'),
    district: district || 'Hyderabad',
    mandal: mandal || 'Serilingampally',
    village: village || 'Madhapur',
    role: 'customer',
    walletBalance: 0,
    totalBookings: 0,
    status: 'active',
    createdAt: new Date().toISOString()
  };

  db.data.users.push(newCustomer);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Customer registered successfully',
    customer: newCustomer
  });
};

// Delete Customer
exports.deleteCustomer = (req, res) => {
  const { id } = req.params;
  const index = db.data.users.findIndex(u => u.id === id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Customer not found' });
  }

  db.data.users.splice(index, 1);
  db.save();

  res.json({ success: true, message: 'Customer removed successfully' });
};

// Create Provider (Service Partner)
exports.createProvider = (req, res) => {
  const { name, phone, email, category, serviceName, aadhaarNumber, vehicleNumber, district, mandal, village } = req.body;
  if (!name || !phone || !category) {
    return res.status(400).json({ success: false, message: 'Name, phone, and service category are required' });
  }

  const { v4: uuidv4 } = require('uuid');
  const newProvider = {
    id: `prv_${uuidv4().substring(0, 8)}`,
    name: name.trim(),
    phone: phone.trim(),
    email: email?.trim() || `${phone.replace(/\s+/g, '')}@loki.partner`,
    role: 'provider',
    category,
    serviceName: serviceName?.trim() || 'Certified Specialist',
    rating: 5.0,
    jobsCompleted: 0,
    isOnline: true,
    kycStatus: 'approved',
    aadhaarNumber: aadhaarNumber?.trim() || 'XXXX-XXXX-0000',
    vehicleNumber: vehicleNumber?.trim() || '',
    district: district || 'Hyderabad',
    mandal: mandal || 'Serilingampally',
    village: village || 'Madhapur',
    walletBalance: 0,
    createdAt: new Date().toISOString()
  };

  db.data.providers.push(newProvider);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Service Partner onboarded successfully',
    provider: newProvider
  });
};

// Delete Provider
exports.deleteProvider = (req, res) => {
  const { id } = req.params;
  const index = db.data.providers.findIndex(p => p.id === id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  db.data.providers.splice(index, 1);
  db.save();

  res.json({ success: true, message: 'Provider removed successfully' });
};

// Toggle Provider Online/Offline Status
exports.toggleProviderOnline = (req, res) => {
  const { id } = req.params;
  const provider = db.data.providers.find(p => p.id === id);
  if (!provider) {
    return res.status(404).json({ success: false, message: 'Provider not found' });
  }

  provider.isOnline = !provider.isOnline;
  db.save();

  res.json({
    success: true,
    message: `Provider is now ${provider.isOnline ? 'ONLINE' : 'OFFLINE'}`,
    isOnline: provider.isOnline
  });
};

exports.getAllOrders = (req, res) => {
  res.json({
    success: true,
    count: db.data.orders.length,
    orders: db.data.orders
  });
};
