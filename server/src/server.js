const http = require('http');
const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');

const config = require('./config');
const { connectDB } = require('./config/dbConnection');
const socketHandler = require('./sockets/socketHandler');

// Routes
const authRoutes = require('./routes/authRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const serviceRoutes = require('./routes/serviceRoutes');
const providerRoutes = require('./routes/providerRoutes');
const orderRoutes = require('./routes/orderRoutes');
const adminRoutes = require('./routes/adminRoutes');
const locationRoutes = require('./routes/locationRoutes');
const promotionRoutes = require('./routes/promotionRoutes');
const uploadRoutes = require('./routes/uploadRoutes');

const app = express();
const server = http.createServer(app);

// Socket.io initialization
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});
app.set('io', io);
socketHandler(io);

// Security & Middlewares
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Static uploads serving for dynamic category icons, ad banners, etc.
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Rate Limiting (development friendly)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10000,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests from this IP, please try again after 15 minutes' }
});
app.use('/api/', limiter);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'Loki Hyperlocal API & Realtime Gateway',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/providers', providerRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/upload', uploadRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found on Loki Server` });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Server Error]', err);
  res.status(500).json({ success: false, message: 'Internal Server Error', error: config.NODE_ENV === 'development' ? err.message : undefined });
});

// Start Server
const PORT = config.PORT;
server.listen(PORT, async () => {
  console.log(`=================================================`);
  console.log(`🚀 Loki Hyperlocal Backend Server running on port ${PORT}`);
  console.log(`🔗 REST API: http://localhost:${PORT}/api/health`);
  console.log(`⚡ WebSocket Engine: Active`);
  console.log(`🛡️  Security Shield: Helmet + Rate Limiting Enabled`);
  console.log(`=================================================`);
  await connectDB();
});
