const mongoose = require('mongoose');

// Schemas with flexible schema (strict: false) to seamlessly match existing rich data
const CategorySchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: String,
  icon: String,
  color: String,
  description: String,
  servicesCount: Number,
  active: Boolean,
  subCategories: Array,
  requiredDocuments: Array
}, { strict: false, timestamps: true });

const ServiceSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: String,
  categoryId: String,
  basePrice: Number,
  duration: String,
  rating: Number,
  reviewsCount: Number,
  active: Boolean,
  description: String,
  includes: Array
}, { strict: false, timestamps: true });

const ProviderSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: String,
  phone: { type: String, required: true },
  category: String,
  serviceName: String,
  rating: Number,
  jobsCompleted: Number,
  leadsReceived: Number,
  cancelledJobs: Number,
  isOnline: Boolean,
  kycStatus: String,
  walletBalance: Number,
  currentLocation: {
    lat: Number,
    lng: Number
  }
}, { strict: false, timestamps: true });

const UserSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: String,
  phone: { type: String, required: true },
  email: String,
  role: String,
  walletBalance: Number
}, { strict: false, timestamps: true });

const OrderSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  customerId: String,
  customerName: String,
  customerPhone: String,
  providerId: String,
  providerName: String,
  serviceId: String,
  serviceName: String,
  category: String,
  amount: Number,
  paymentStatus: String,
  paymentMethod: String,
  orderStatus: String,
  customerAddress: String,
  otp: String,
  notes: String
}, { strict: false, timestamps: true });

const PromotionSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: String,
  type: String
}, { strict: false, timestamps: true });

const CategoryModel = mongoose.models.Category || mongoose.model('Category', CategorySchema);
const ServiceModel = mongoose.models.Service || mongoose.model('Service', ServiceSchema);
const ProviderModel = mongoose.models.Provider || mongoose.model('Provider', ProviderSchema);
const UserModel = mongoose.models.User || mongoose.model('User', UserSchema);
const OrderModel = mongoose.models.Order || mongoose.model('Order', OrderSchema);
const PromotionModel = mongoose.models.Promotion || mongoose.model('Promotion', PromotionSchema);

async function syncJsonToMongo(jsonData) {
  try {
    const categoriesCount = await CategoryModel.countDocuments();
    if (categoriesCount === 0 && jsonData.categories && jsonData.categories.length > 0) {
      console.log('🌱 Seeding categories to MongoDB Atlas...');
      await CategoryModel.insertMany(jsonData.categories);
    }

    const servicesCount = await ServiceModel.countDocuments();
    if (servicesCount === 0 && jsonData.services && jsonData.services.length > 0) {
      console.log('🌱 Seeding services to MongoDB Atlas...');
      await ServiceModel.insertMany(jsonData.services);
    }

    const providersCount = await ProviderModel.countDocuments();
    if (providersCount === 0 && jsonData.providers && jsonData.providers.length > 0) {
      console.log('🌱 Seeding providers to MongoDB Atlas...');
      await ProviderModel.insertMany(jsonData.providers);
    }

    const usersCount = await UserModel.countDocuments();
    if (usersCount === 0 && jsonData.users && jsonData.users.length > 0) {
      console.log('🌱 Seeding users to MongoDB Atlas...');
      await UserModel.insertMany(jsonData.users);
    }

    const ordersCount = await OrderModel.countDocuments();
    if (ordersCount === 0 && jsonData.orders && jsonData.orders.length > 0) {
      console.log('🌱 Seeding orders to MongoDB Atlas...');
      await OrderModel.insertMany(jsonData.orders);
    }

    const promoCount = await PromotionModel.countDocuments();
    if (promoCount === 0 && jsonData.promotions && jsonData.promotions.length > 0) {
      console.log('🌱 Seeding promotions to MongoDB Atlas...');
      await PromotionModel.insertMany(jsonData.promotions);
    }

    console.log('✨ MongoDB Atlas Cloud Database Synchronization Complete!');
  } catch (err) {
    console.error('Mongo sync error:', err.message);
  }
}

async function saveDocumentToMongo(collectionName, doc) {
  try {
    if (!doc || !doc.id) return;
    let Model = null;
    if (collectionName === 'orders') Model = OrderModel;
    if (collectionName === 'providers') Model = ProviderModel;
    if (collectionName === 'users') Model = UserModel;
    if (collectionName === 'services') Model = ServiceModel;
    if (collectionName === 'categories') Model = CategoryModel;

    if (Model) {
      await Model.findOneAndUpdate({ id: doc.id }, { $set: doc }, { upsert: true, new: true });
    }
  } catch (e) {
    console.warn(`Error persisting ${collectionName} to MongoDB:`, e.message);
  }
}

module.exports = {
  CategoryModel,
  ServiceModel,
  ProviderModel,
  UserModel,
  OrderModel,
  PromotionModel,
  syncJsonToMongo,
  saveDocumentToMongo
};

