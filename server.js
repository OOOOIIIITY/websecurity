const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet()); // Adds various security headers
app.use(express.json({ limit: '10mb' })); // Limit JSON payload size
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS || 'http://localhost:3000',
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

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
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
