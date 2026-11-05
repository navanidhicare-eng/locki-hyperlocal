const db = require('../data/db');
const { v4: uuidv4 } = require('uuid');
const { anakapalliDistrict } = require('../data/anakapalliData');

// Ensure db.data.locations is initialized with Anakapalli District, Andhra Pradesh
const ensureLocationsInit = () => {
  if (!db.data.locations || !Array.isArray(db.data.locations) || db.data.locations.length === 0) {
    db.data.locations = [anakapalliDistrict];
    db.save();
  }
};

// 1. Get all locations hierarchy
exports.getAllLocations = (req, res) => {
  ensureLocationsInit();
  res.json({
    success: true,
    count: db.data.locations.length,
    locations: db.data.locations
  });
};

// 2. Add District
exports.createDistrict = (req, res) => {
  ensureLocationsInit();
  const { name, state } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ success: false, message: 'District name is required' });
  }

  const newDistrict = {
    id: `dist_${uuidv4().substring(0, 8)}`,
    name: name.trim(),
    state: state?.trim() || 'Andhra Pradesh',
    mandals: []
  };

  db.data.locations.push(newDistrict);
  db.save();

  res.status(201).json({
    success: true,
    message: 'District created successfully',
    district: newDistrict,
    locations: db.data.locations
  });
};

// 3. Delete District
exports.deleteDistrict = (req, res) => {
  ensureLocationsInit();
  const { id } = req.params;
  const index = db.data.locations.findIndex(d => d.id === id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'District not found' });
  }

  db.data.locations.splice(index, 1);
  db.save();

  res.json({
    success: true,
    message: 'District deleted successfully',
    locations: db.data.locations
  });
};

// 4. Add Mandal under District
exports.createMandal = (req, res) => {
  ensureLocationsInit();
  const { districtId } = req.params;
  const { name } = req.body;

  const district = db.data.locations.find(d => d.id === districtId);
  if (!district) {
    return res.status(404).json({ success: false, message: 'District not found' });
  }

  if (!name || !name.trim()) {
    return res.status(400).json({ success: false, message: 'Mandal name is required' });
  }

  if (!district.mandals) {
    district.mandals = [];
  }

  const newMandal = {
    id: `mnd_${uuidv4().substring(0, 8)}`,
    name: name.trim(),
    villages: []
  };

  district.mandals.push(newMandal);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Mandal added successfully',
    mandal: newMandal,
    district,
    locations: db.data.locations
  });
};

// 5. Delete Mandal
exports.deleteMandal = (req, res) => {
  ensureLocationsInit();
  const { districtId, mandalId } = req.params;

  const district = db.data.locations.find(d => d.id === districtId);
  if (!district || !district.mandals) {
    return res.status(404).json({ success: false, message: 'District or mandals not found' });
  }

  district.mandals = district.mandals.filter(m => m.id !== mandalId);
  db.save();

  res.json({
    success: true,
    message: 'Mandal deleted successfully',
    district,
    locations: db.data.locations
  });
};

// 6. Add Village under Mandal
exports.createVillage = (req, res) => {
  ensureLocationsInit();
  const { districtId, mandalId } = req.params;
  const { name, pincode } = req.body;

  const district = db.data.locations.find(d => d.id === districtId);
  if (!district || !district.mandals) {
    return res.status(404).json({ success: false, message: 'District not found' });
  }

  const mandal = district.mandals.find(m => m.id === mandalId);
  if (!mandal) {
    return res.status(404).json({ success: false, message: 'Mandal not found' });
  }

  if (!name || !name.trim()) {
    return res.status(400).json({ success: false, message: 'Village/Ward name is required' });
  }

  if (!mandal.villages) {
    mandal.villages = [];
  }

  const newVillage = {
    id: `vlg_${uuidv4().substring(0, 8)}`,
    name: name.trim(),
    pincode: pincode?.trim() || ''
  };

  mandal.villages.push(newVillage);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Village added successfully',
    village: newVillage,
    mandal,
    district,
    locations: db.data.locations
  });
};

// 7. Delete Village
exports.deleteVillage = (req, res) => {
  ensureLocationsInit();
  const { districtId, mandalId, villageId } = req.params;

  const district = db.data.locations.find(d => d.id === districtId);
  if (!district || !district.mandals) {
    return res.status(404).json({ success: false, message: 'District not found' });
  }

  const mandal = district.mandals.find(m => m.id === mandalId);
  if (!mandal || !mandal.villages) {
    return res.status(404).json({ success: false, message: 'Mandal not found' });
  }

  mandal.villages = mandal.villages.filter(v => v.id !== villageId);
  db.save();

  res.json({
    success: true,
    message: 'Village deleted successfully',
    mandal,
    district,
    locations: db.data.locations
  });
};
