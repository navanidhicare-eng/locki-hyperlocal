const mongoose = require('mongoose');
const config = require('./index');

let isConnected = false;

async function connectDB() {
  if (isConnected) return;

  const uri = config.MONGODB_URI;

  if (!uri || uri.trim() === '') {
    console.log('ℹ️  MongoDB Atlas: No MONGODB_URI found in .env. Running on local storage mode.');
    return false;
  }

  try {
    console.log('⏳ Connecting to MongoDB Atlas Cloud Database...');
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 8000,
    });
    isConnected = true;
    console.log(`✅ MongoDB Atlas Connected Successfully: ${conn.connection.host}`);
    console.log(`📦 Database: ${conn.connection.name || 'loki_db'}`);

    // Auto-seed/sync existing JSON data to MongoDB Atlas Cloud
    try {
      const db = require('../data/db');
      const { syncJsonToMongo } = require('../data/mongoSync');
      if (db.data) {
        await syncJsonToMongo(db.data);
      }
    } catch (syncErr) {
      console.warn('Initial Atlas sync notice:', syncErr.message);
    }

    return true;
  } catch (err) {
    console.error('❌ MongoDB Atlas Connection Error:', err.message);
    console.log('⚠️  Falling back to local storage so the server stays operational.');
    return false;
  }
}

module.exports = { connectDB, getIsConnected: () => isConnected };

