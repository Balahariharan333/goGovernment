require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const dns = require('dns');

// Ensure reliable DNS resolution for MongoDB Atlas SRV records
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {
  console.warn('DNS server override failed:', e.message);
}

const complaintRoutes = require('./routes/complaintRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const authRoutes = require('./routes/authRoutes');
const addressRoutes = require('./routes/addressRoutes');
const storeRoutes = require('./routes/storeRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');
const productRoutes = require('./routes/productRoutes');
const cartRoutes = require('./routes/cartRoutes');
const wishlistRoutes = require('./routes/wishlistRoutes');
const orderRoutes = require('./routes/orderRoutes');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'],
  },
});

// Expose io instance to route handlers via req.app.get('io')
app.set('io', io);

io.on('connection', (socket) => {
  console.log(`⚡ [Socket.io] Client connected: ${socket.id}`);

  // Store merchant joins store room for targeted alerts
  socket.on('join:store', (storeId) => {
    if (storeId) {
      socket.join(`store:${storeId}`);
      console.log(`🏪 [Socket.io] Socket ${socket.id} joined store room: store:${storeId}`);
    }
  });

  // Rider joins general riders dispatch room
  socket.on('join:rider', (riderId) => {
    socket.join('riders');
    console.log(`🚴 [Socket.io] Socket ${socket.id} joined riders room (Rider: ${riderId})`);
  });

  // Relay chat messages between citizen and rider
  socket.on('chat:send', (message) => {
    if (message && message.orderId) {
      console.log(`💬 [Socket.io] Chat relay for order ${message.orderId}`);
      io.emit(`chat:${message.orderId}`, message);
    }
  });

  // Relay rider live GPS coordinates to citizen
  socket.on('rider:location', (data) => {
    if (data && data.orderId) {
      io.emit(`order:${data.orderId}:rider_location`, data);
    }
  });

  socket.on('disconnect', () => {
    console.log(`⚡ [Socket.io] Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(morgan('dev'));

// Serve uploaded photos statically so Flutter can display them
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health Check Endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    message: 'GoGovernment Node.js Backend is running smoothly 🚀',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/complaints', complaintRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/addresses', addressRoutes);
app.use('/api/stores', storeRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/orders', orderRoutes);

// Connect to MongoDB & Start Server
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error('❌ MONGO_URI is missing in .env file!');
  process.exit(1);
}

const os = require('os');

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log(' MongoDB Atlas Connected Successfully!');
    server.listen(PORT, '0.0.0.0', () => {
      console.log(` Server is running!`);
      console.log(` Laptop URL: http://localhost:${PORT}/api/health`);
      
      // Auto-detect local Wi-Fi IP
      const nets = os.networkInterfaces();
      for (const name of Object.keys(nets)) {
        for (const net of nets[name]) {
          if (net.family === 'IPv4' && !net.internal) {
            console.log(` Mobile URL (${name}): http://${net.address}:${PORT}/api/health`);
          }
        }
      }
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Failed:', err.message);
  });
