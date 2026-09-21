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
const walletRoutes = require('./routes/walletRoutes');

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

// ─── Rider GPS Registry (in-memory, no DB overhead) ──────────────────────────
// { riderId: { lat, lng, socketId, isOnline, lastSeen } }
const riderRegistry = new Map();

// Haversine distance formula (returns km)
function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Find nearest online riders to a given store location.
 * @param {number} storeLat
 * @param {number} storeLng
 * @param {number} radiusKm  - max radius
 * @param {number} limit     - max riders to return
 * @param {string[]} excludeIds - riderIds already dispatched in earlier rounds
 */
function findNearestRiders(storeLat, storeLng, radiusKm, limit, excludeIds = []) {
  const candidates = [];
  const now = Date.now();
  for (const [riderId, info] of riderRegistry.entries()) {
    if (!info.isOnline || !info.socketId) continue;
    // Skip riders who already have an active delivery
    if (info.isBusy) continue;
    // Must have active non-zero GPS signal pinged within last 2 minutes (120,000 ms)
    if (info.lat === 0 && info.lng === 0) continue;
    if (info.lastSeen && now - info.lastSeen > 120000) continue;
    if (excludeIds.includes(riderId)) continue;
    const dist = haversineKm(storeLat, storeLng, info.lat, info.lng);
    if (dist <= radiusKm) {
      candidates.push({ riderId, socketId: info.socketId, dist });
    }
  }
  candidates.sort((a, b) => a.dist - b.dist);
  return candidates.slice(0, limit);
}

// Active dispatch timers: { orderId → { timer, round, dispatchedIds } }
const dispatchTimers = new Map();

/**
 * Dispatch an order to nearby riders, with automatic escalation.
 * Round 1: 3 nearest within 2km  (30s timeout)
 * Round 2: 3 nearest within 6km  (30s timeout, excluding round-1 riders)
 * Round 3: broadcast to all online riders
 */
function dispatchOrder(io, orderPayload, storeLat, storeLng, round = 1, prevDispatchedIds = []) {
  const orderId = orderPayload.orderId;

  // Clear any existing timer for this order
  if (dispatchTimers.has(orderId)) {
    clearTimeout(dispatchTimers.get(orderId).timer);
  }

  let targets = [];
  if (round === 1) {
    targets = findNearestRiders(storeLat, storeLng, 2, 3, prevDispatchedIds);
  } else if (round === 2) {
    targets = findNearestRiders(storeLat, storeLng, 6, 3, prevDispatchedIds);
  }

  const dispatchedIds = [...prevDispatchedIds, ...targets.map((t) => t.riderId)];

  if (round <= 2 && targets.length > 0) {
    // Targeted dispatch — only selected riders
    for (const target of targets) {
      io.to(target.socketId).emit('order:dispatch', {
        ...orderPayload,
        dispatchRound: round,
        dispatchDistKm: Math.round(target.dist * 10) / 10,
        countdownSecs: 30,
      });
    }
    console.log(
      `📡 [Dispatch R${round}] Order ${orderId} → ${targets.length} riders within ${round === 1 ? 2 : 6}km`
    );

    // Schedule escalation after 30 seconds
    const timer = setTimeout(() => {
      // Re-check if order is still unaccepted
      const Order = require('./models/Order');
      Order.findOne({ orderId }).then((order) => {
        if (!order || order.status !== 'ready_for_pickup') {
          console.log(`✅ [Dispatch] Order ${orderId} already accepted — no escalation needed`);
          dispatchTimers.delete(orderId);
          return;
        }
        const nextRound = round + 1;
        console.log(`⏱️ [Dispatch] No accept in 30s for order ${orderId} — escalating to round ${nextRound}`);
        dispatchOrder(io, orderPayload, storeLat, storeLng, nextRound, dispatchedIds);
      });
    }, 30000);

    dispatchTimers.set(orderId, { timer, round, dispatchedIds });
  } else {
    // Round 3 (or no riders nearby within 2km/6km) — broadcast to all online riders
    const payload = {
      ...orderPayload,
      dispatchRound: 3,
      dispatchDistKm: null,
      countdownSecs: 30,
    };
    io.emit('order:dispatch', payload);
    io.to('riders').emit('order:dispatch', payload);
    console.log(`📡 [Dispatch R3] Order ${orderId} → broadcast to all online riders`);
    dispatchTimers.delete(orderId);
  }
}

// Expose dispatch helpers so routes can call them
app.set('riderRegistry', riderRegistry);
app.set('dispatchOrder', dispatchOrder);
app.set('dispatchTimers', dispatchTimers);

io.on('connection', (socket) => {
  console.log(`⚡ [Socket.io] Client connected: ${socket.id}`);

  // Store merchant joins store room for targeted alerts
  socket.on('join:store', (storeId) => {
    if (storeId) {
      socket.join(`store:${storeId}`);
      console.log(`🏪 [Socket.io] Socket ${socket.id} joined store room: store:${storeId}`);
    }
  });

  // Rider joins general riders dispatch room + registers in GPS registry
  socket.on('join:rider', (riderId) => {
    socket.join('riders');
    socket.data.riderId = riderId;
    // Register rider in GPS registry (online, position unknown until first ping)
    if (riderId && !riderRegistry.has(riderId)) {
      riderRegistry.set(riderId, {
        lat: 0, lng: 0, socketId: socket.id, isOnline: true, isBusy: false, lastSeen: Date.now(),
      });
    } else if (riderId) {
      const info = riderRegistry.get(riderId);
      info.socketId = socket.id;
      info.isOnline = true;
      info.lastSeen = Date.now();
      // isBusy is preserved — rider reconnecting mid-delivery stays busy
    }
    console.log(`🚴 [Socket.io] Socket ${socket.id} joined riders room (Rider: ${riderId})`);
  });

  // Rider GPS ping — updates in-memory registry (every 30s while online)
  socket.on('rider:location_ping', async (data) => {
    const { riderId, lat, lng, isOnline, bgPing } = data || {};
    if (!riderId) return;
    const existing = riderRegistry.get(riderId) || {};

    // Background keepalive pings (bgPing=true) send lat=0,lng=0 to save battery.
    // Do NOT overwrite real GPS coordinates with zeros — only update online status.
    const isBackgroundPing = bgPing === true && lat === 0 && lng === 0;

    riderRegistry.set(riderId, {
      ...existing,
      lat: isBackgroundPing ? (existing.lat ?? 0) : (lat ?? existing.lat ?? 0),
      lng: isBackgroundPing ? (existing.lng ?? 0) : (lng ?? existing.lng ?? 0),
      socketId: socket.id,
      isOnline: isOnline !== false,
      lastSeen: Date.now(),
    });
    // Ensure rider role is updated in DB
    try {
      await User.updateOne(
        { $or: [{ userId: riderId }, { phone: riderId }] },
        { $set: { role: 'rider' } }
      );
    } catch (_) {}
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
    const riderId = socket.data.riderId;
    if (riderId && riderRegistry.has(riderId)) {
      const info = riderRegistry.get(riderId);
      // CRITICAL: Only mark OFFLINE if THIS socket is still the active socket.
      // The background foreground-service socket may have already taken over
      // with a newer socketId — we must NOT override its isOnline=true state.
      if (info.socketId === socket.id) {
        info.isOnline = false;
        console.log(`🔴 [Socket.io] Rider ${riderId} marked OFFLINE (socket ${socket.id} disconnected)`);
      } else {
        console.log(`⚡ [Socket.io] Stale socket ${socket.id} disconnected for rider ${riderId} — background socket still active, keeping ONLINE`);
      }
    }
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
app.use('/api/wallet', walletRoutes);

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
