const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');
const db = require('../data/db');

exports.login = async (req, res) => {
  try {
    const { email, phone, mobile, identifier, password, role } = req.body;
    const loginIdentifier = (phone || mobile || identifier || email || '').trim();
    if (!loginIdentifier || !password) {
      return res.status(400).json({ success: false, message: 'Mobile number or email and password are required' });
    }

    let user = null;
    let userRole = role;

    const cleanInput = loginIdentifier.toLowerCase().replace(/[^a-z0-9@.]/g, '');
    const phoneInput = loginIdentifier.replace(/[^0-9]/g, '');

    const matchesUser = (u) => {
      if (u.email && u.email.toLowerCase() === cleanInput) return true;
      if (u.phone && phoneInput) {
        const uPhoneDigits = u.phone.replace(/[^0-9]/g, '');
        if (uPhoneDigits === phoneInput || uPhoneDigits.endsWith(phoneInput) || phoneInput.endsWith(uPhoneDigits)) {
          return true;
        }
      }
      return false;
    };

    // Search in providers table first if role is provider, or search both
    if (role === 'provider') {
      user = db.data.providers.find(matchesUser);
      if (user) userRole = 'provider';
    } else {
      user = db.data.users.find(matchesUser);
      if (!user) {
        user = db.data.providers.find(matchesUser);
        if (user) userRole = 'provider';
      }
    }

    if (!user) {
      return res.status(401).json({ success: false, message: 'No registered account found with this mobile number or email' });
    }

    // Role check if specified
    if (role && user.role !== role) {
      return res.status(403).json({ success: false, message: `Account exists, but not with role '${role}'` });
    }

    const isMatch = bcrypt.compareSync(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Incorrect password. Please try again.' });
    }

    // Generate JWT
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        phone: user.phone,
        name: user.name,
        role: user.role
      },
      config.JWT_SECRET,
      { expiresIn: config.JWT_EXPIRY }
    );

    const safeUser = { ...user };
    delete safeUser.passwordHash;

    res.json({
      success: true,
      message: 'Authentication successful',
      token,
      user: safeUser
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.register = async (req, res) => {
  try {
    const { name, email, phone, mobile, password, role = 'provider', category, serviceName, aadhaarNumber, vehicleNumber } = req.body;
    const userPhone = (phone || mobile || '').trim();
    const userEmail = (email && email.trim()) || `${userPhone || Date.now()}@partner.loki`;

    if (!name || !password || !userPhone) {
      return res.status(400).json({ success: false, message: 'Name, mobile number, and password are required' });
    }

    const assignedRole = role === 'provider' ? 'provider' : (role === 'admin' ? 'admin' : 'customer');

    // Check if phone or email already exists
    const cleanPhone = userPhone.replace(/[^0-9]/g, '');
    const phoneMatches = (u) => u.phone && u.phone.replace(/[^0-9]/g, '') === cleanPhone;

    const existsInUsers = db.data.users.some(u => (u.email && u.email.toLowerCase() === userEmail.toLowerCase()) || phoneMatches(u));
    const existsInProviders = db.data.providers.some(p => (p.email && p.email.toLowerCase() === userEmail.toLowerCase()) || phoneMatches(p));

    if (existsInUsers || existsInProviders) {
      return res.status(409).json({ success: false, message: 'Mobile number or email is already registered. Please login.' });
    }

    const salt = bcrypt.genSaltSync(10);
    const passwordHash = bcrypt.hashSync(password, salt);

    if (assignedRole === 'provider') {
      const partnerSeq = (db.data.providers.length + 1).toString().padStart(4, '0');
      const newProvider = {
        id: `prv_${uuidv4().substring(0, 8)}`,
        partnerCode: `LP-${partnerSeq}`,
        name,
        email: userEmail,
        phone: userPhone,
        passwordHash,
        role: 'provider',
        category: category || 'cat_plumbing',
        serviceName: serviceName || 'Verified Specialist',
        rating: 5.0,
        jobsCompleted: 0,
        isOnline: false,
        kycStatus: 'pending', // Requires admin verification
        subscriptionStatus: 'unpaid',
        isProfileComplete: false, // Incomplete profile initially
        aadhaarNumber: aadhaarNumber || 'PENDING_UPLOAD',
        vehicleNumber: vehicleNumber || 'N/A',
        currentLocation: { lat: 17.4435, lng: 78.3772 },
        walletBalance: 0,
        createdAt: new Date().toISOString()
      };

      db.data.providers.push(newProvider);
      db.save();

      const token = jwt.sign(
        { id: newProvider.id, email: newProvider.email, phone: newProvider.phone, name: newProvider.name, role: 'provider' },
        config.JWT_SECRET,
        { expiresIn: config.JWT_EXPIRY }
      );

      const safeProvider = { ...newProvider };
      delete safeProvider.passwordHash;

      return res.status(201).json({
        success: true,
        message: 'Partner account registered successfully! Ready to accept jobs.',
        token,
        user: safeProvider
      });
    }

    // Customer creation
    const newUser = {
      id: `usr_${uuidv4().substring(0, 8)}`,
      name,
      email,
      phone,
      passwordHash,
      role: 'customer',
      address: req.body.address || 'Hyderabad',
      coordinates: req.body.coordinates || { lat: 17.4435, lng: 78.3772 },
      walletBalance: 200, // Signup welcome bonus
      createdAt: new Date().toISOString()
    };

    db.data.users.push(newUser);
    db.save();

    const token = jwt.sign(
      { id: newUser.id, email: newUser.email, name: newUser.name, role: 'customer' },
      config.JWT_SECRET,
      { expiresIn: config.JWT_EXPIRY }
    );

    const safeUser = { ...newUser };
    delete safeUser.passwordHash;

    res.status(201).json({
      success: true,
      message: 'Account created successfully with ₹200 Welcome Bonus!',
      token,
      user: safeUser
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.getProfile = (req, res) => {
  const { id, role } = req.user;
  let account = null;

  if (role === 'provider') {
    account = db.data.providers.find(p => p.id === id);
  } else {
    account = db.data.users.find(u => u.id === id);
  }

  if (!account) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  const safe = { ...account };
  delete safe.passwordHash;
  res.json({ success: true, user: safe });
};
