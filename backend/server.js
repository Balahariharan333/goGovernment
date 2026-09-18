require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

const complaintRoutes = require('./routes/complaintRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const authRoutes = require('./routes/authRoutes');
const addressRoutes = require('./routes/addressRoutes');
const storeRoutes = require('./routes/storeRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');

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
