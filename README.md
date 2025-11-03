# Web Security Example

This project demonstrates web security best practices using Node.js and Express.

## Features

This secure web application includes:

- **Security Headers**: Using Helmet.js to set secure HTTP headers
- **Rate Limiting**: Protection against brute force and DDoS attacks
- **CORS Protection**: Controlled cross-origin resource sharing
- **Input Validation**: Request size limiting to prevent payload attacks
- **Error Handling**: Safe error responses that don't leak sensitive information

## Installation

```bash
npm install
```

## Usage

Start the server:

```bash
npm start
```

The server will run on port 3000 (or the PORT environment variable if set).

## Endpoints

- `GET /health` - Health check endpoint
- `GET /api/data` - Example secure endpoint

## Security Best Practices Implemented

### 1. Security Headers (Helmet.js)
- X-DNS-Prefetch-Control
- X-Frame-Options
- X-Content-Type-Options
- Strict-Transport-Security
- X-Download-Options
- X-Permitted-Cross-Domain-Policies

### 2. Rate Limiting
- Limits each IP to 100 requests per 15 minutes
- Prevents brute force attacks
- Mitigates DDoS attempts

### 3. CORS Protection
- Configurable allowed origins
- Credentials control
- Prevents unauthorized cross-origin requests

### 4. Input Validation
- Request payload size limits (10MB)
- Prevents memory exhaustion attacks

### 5. Error Handling
- Safe error messages
- No stack trace exposure in production
- Proper HTTP status codes

## Environment Variables

- `PORT` - Server port (default: 3000)
- `ALLOWED_ORIGINS` - CORS allowed origins (default: http://localhost:3000)

## Common Web Security Vulnerabilities (Prevented)

1. **XSS (Cross-Site Scripting)**: Helmet sets Content-Security-Policy headers
2. **Clickjacking**: X-Frame-Options header prevents iframe embedding
3. **MIME Sniffing**: X-Content-Type-Options prevents MIME confusion attacks
4. **DDoS/Brute Force**: Rate limiting protects against automated attacks
5. **Information Disclosure**: Error handler doesn't expose stack traces

## Testing

Test the health endpoint:
```bash
curl http://localhost:3000/health
```

Test the secure API endpoint:
```bash
curl http://localhost:3000/api/data
```

Test rate limiting (run multiple times quickly):
```bash
for i in {1..105}; do curl http://localhost:3000/api/data; done
```

## License

MIT