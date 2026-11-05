const db = require('../data/db');
const { v4: uuidv4 } = require('uuid');

exports.getAllCategories = (req, res) => {
  res.json({
    success: true,
    count: db.data.categories.length,
    categories: db.data.categories
  });
};

exports.createCategory = (req, res) => {
  const { name, icon, iconUrl, color, description, requiredDocuments, subCategories } = req.body;
  if (!name) {
    return res.status(400).json({ success: false, message: 'Category name is required' });
  }

  const newCat = {
    id: `cat_${uuidv4().substring(0, 8)}`,
    name,
    icon: icon || 'wrench',
    iconUrl: iconUrl || '',
    color: color || '#3B82F6',
    description: description || '',
    requiredDocuments: requiredDocuments || ['aadhaar'],
    subCategories: subCategories || [],
    servicesCount: 0,
    active: true
  };

  db.data.categories.push(newCat);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Category created successfully',
    category: newCat
  });
};

exports.updateCategory = (req, res) => {
  const { id } = req.params;
  const index = db.data.categories.findIndex(c => c.id === id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  db.data.categories[index] = {
    ...db.data.categories[index],
    ...req.body
  };
  db.save();

  res.json({
    success: true,
    message: 'Category updated',
    category: db.data.categories[index]
  });
};

exports.deleteCategory = (req, res) => {
  const { id } = req.params;
  const index = db.data.categories.findIndex(c => c.id === id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  db.data.categories.splice(index, 1);
  db.save();

  res.json({
    success: true,
    message: 'Category deleted successfully'
  });
};

// Add Sub-Category
exports.addSubCategory = (req, res) => {
  const { id } = req.params;
  const { name, description, hasChildCategories, basePrice, duration, childCategories } = req.body;
  
  const cat = db.data.categories.find(c => c.id === id);
  if (!cat) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  if (!name) {
    return res.status(400).json({ success: false, message: 'Sub-category name is required' });
  }

  if (!cat.subCategories) {
    cat.subCategories = [];
  }

  const newSub = {
    id: `sub_${uuidv4().substring(0, 8)}`,
    name,
    description: description || '',
    hasChildCategories: Boolean(hasChildCategories),
    basePrice: hasChildCategories ? null : (Number(basePrice) || 199),
    duration: hasChildCategories ? null : (duration || '30 mins'),
    childCategories: hasChildCategories ? (childCategories || []) : []
  };

  cat.subCategories.push(newSub);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Sub-category added successfully',
    subCategory: newSub,
    category: cat
  });
};

// Update Sub-Category (Name, description, basePrice, duration, subscriptionPlans)
exports.updateSubCategory = (req, res) => {
  const { id, subId } = req.params;
  const cat = db.data.categories.find(c => c.id === id);
  if (!cat || !cat.subCategories) {
    return res.status(404).json({ success: false, message: 'Category or sub-categories not found' });
  }

  const sub = cat.subCategories.find(s => s.id === subId);
  if (!sub) {
    return res.status(404).json({ success: false, message: 'Sub-category not found' });
  }

  Object.assign(sub, req.body);
  db.save();

  res.json({
    success: true,
    message: 'Sub-category updated successfully',
    subCategory: sub,
    category: cat
  });
};

// Delete Sub-Category
exports.deleteSubCategory = (req, res) => {
  const { id, subId } = req.params;
  const cat = db.data.categories.find(c => c.id === id);
  if (!cat || !cat.subCategories) {
    return res.status(404).json({ success: false, message: 'Category or sub-categories not found' });
  }

  cat.subCategories = cat.subCategories.filter(s => s.id !== subId);
  db.save();

  res.json({
    success: true,
    message: 'Sub-category deleted successfully',
    category: cat
  });
};

// Add Child-Category under Sub-Category
exports.addChildCategory = (req, res) => {
  const { id, subId } = req.params;
  const { name, basePrice, duration, description } = req.body;

  const cat = db.data.categories.find(c => c.id === id);
  if (!cat || !cat.subCategories) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  const sub = cat.subCategories.find(s => s.id === subId);
  if (!sub) {
    return res.status(404).json({ success: false, message: 'Sub-category not found' });
  }

  if (!name) {
    return res.status(400).json({ success: false, message: 'Child category name is required' });
  }

  sub.hasChildCategories = true;
  if (!sub.childCategories) {
    sub.childCategories = [];
  }

  const newChild = {
    id: `ch_${uuidv4().substring(0, 8)}`,
    name,
    basePrice: Number(basePrice) || 299,
    duration: duration || '30-45 mins',
    description: description || ''
  };

  sub.childCategories.push(newChild);
  db.save();

  res.status(201).json({
    success: true,
    message: 'Child category added successfully',
    childCategory: newChild,
    category: cat
  });
};

// Delete Child-Category
exports.deleteChildCategory = (req, res) => {
  const { id, subId, childId } = req.params;
  const cat = db.data.categories.find(c => c.id === id);
  if (!cat || !cat.subCategories) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  const sub = cat.subCategories.find(s => s.id === subId);
  if (!sub || !sub.childCategories) {
    return res.status(404).json({ success: false, message: 'Sub-category or child categories not found' });
  }

  sub.childCategories = sub.childCategories.filter(ch => ch.id !== childId);
  db.save();

  res.json({
    success: true,
    message: 'Child category deleted successfully',
    category: cat
  });
};
