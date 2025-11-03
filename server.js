const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet()); // Adds various security headers
app.use(express.json({ limit: '100kb' })); // Limit JSON payload size to prevent DoS
app.use(express.urlencoded({ extended: true, limit: '100kb' }));

// CORS configuration - supports multiple origins
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
  : ['http://localhost:3000'];

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));

// Rate limiting to prevent brute force attacks
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running securely' });
});

// Example secure endpoint
app.get('/api/data', (req, res) => {
  res.json({
    message: 'This is a secure endpoint',
    timestamp: new Date().toISOString(),
    securityHeaders: 'Helmet middleware applied',
    rateLimited: 'Yes'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handler - doesn't expose sensitive information
app.use((err, req, res, next) => {
  // Log minimal error details (avoid logging full stack in production)
  console.error(`Error: ${err.message}`);
  
  // In production, don't expose error details
  const isDevelopment = process.env.NODE_ENV === 'development';
  res.status(500).json({ 
    error: 'Something went wrong!',
    ...(isDevelopment && { details: err.message })
  });
});

app.listen(PORT, () => {
  console.log(`Secure web server running on port ${PORT}`);
  console.log(`Security features enabled:`);
  console.log(`  - Helmet (Security Headers)`);
  console.log(`  - Rate Limiting`);
  console.log(`  - CORS Protection`);
  console.log(`  - Request Size Limiting`);
});

module.exports = app;
