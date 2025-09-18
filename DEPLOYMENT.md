# 🚀 SmartBus Tracker - Deployment Guide

## 📋 Quick Deployment (30 seconds)

### Option 1: Automatic Start (Windows)
```bash
# Double-click this file:
START-HERE.bat
```

### Option 2: Manual Start
```bash
# 1. Install dependencies
cd backend
npm install

# 2. Start backend server
node server.js

# 3. Open dashboard
# Open index.html in your browser
```

## 🌐 Production Deployment

### AWS EC2 Deployment

1. **Launch EC2 Instance**
   - Ubuntu 22.04 LTS
   - t3.medium or higher
   - Security Group: Allow ports 80, 443, 3000

2. **Install Dependencies**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 for process management
sudo npm install -g pm2

# Install Nginx
sudo apt install nginx -y
```

3. **Deploy Application**
```bash
# Clone repository
git clone https://github.com/Asadp3406/bus-tracking.git
cd bus-tracking

# Install backend dependencies
cd backend
npm install --production

# Start with PM2
pm2 start server.js --name "smartbus-backend"
pm2 startup
pm2 save
```

4. **Configure Nginx**
```nginx
# /etc/nginx/sites-available/smartbus
server {
    listen 80;
    server_name your-domain.com;
    
    # Serve static files
    location / {
        root /path/to/bus-tracking;
        index index.html;
        try_files $uri $uri/ =404;
    }
    
    # Proxy API requests
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

5. **Enable Site**
```bash
sudo ln -s /etc/nginx/sites-available/smartbus /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

6. **SSL Certificate (Optional)**
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### Docker Deployment

1. **Create Dockerfile**
```dockerfile
# backend/Dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --production

COPY . .
EXPOSE 3000

CMD ["node", "server.js"]
```

2. **Create docker-compose.yml**
```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - .:/usr/share/nginx/html
    depends_on:
      - backend
    restart: unless-stopped
```

3. **Deploy with Docker**
```bash
docker-compose up -d
```

## 🔧 Environment Configuration

### Production Environment Variables
```env
# .env
NODE_ENV=production
PORT=3000
JWT_SECRET=your-super-secret-jwt-key-2024
CORS_ORIGIN=https://your-domain.com

# Database (if using external DB)
DATABASE_URL=postgresql://user:pass@host:5432/smartbus
REDIS_URL=redis://host:6379

# External APIs
GOOGLE_MAPS_API_KEY=your-google-maps-key
MAPBOX_TOKEN=your-mapbox-token

# Notifications
FIREBASE_SERVER_KEY=your-firebase-key
TWILIO_SID=your-twilio-sid
TWILIO_TOKEN=your-twilio-token
```

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check backend health
curl http://localhost:3000/health

# Check PM2 status
pm2 status

# View logs
pm2 logs smartbus-backend
```

### Performance Monitoring
```bash
# Install monitoring tools
npm install -g clinic
npm install -g autocannon

# Performance testing
autocannon -c 100 -d 30 http://localhost:3000/api/buses

# Memory profiling
clinic doctor -- node server.js
```

### Backup Strategy
```bash
# Backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "smartbus_backup_$DATE.tar.gz" /path/to/bus-tracking
aws s3 cp "smartbus_backup_$DATE.tar.gz" s3://your-backup-bucket/
```

## 🚨 Troubleshooting

### Common Issues

1. **Port 3000 already in use**
```bash
# Find and kill process
netstat -ano | findstr :3000
taskkill /PID [PID_NUMBER] /F
```

2. **Node.js not found**
```bash
# Install Node.js
# Download from: https://nodejs.org/
# Or use package manager
```

3. **Permission denied (Linux)**
```bash
sudo chown -R $USER:$USER /path/to/bus-tracking
chmod +x START-HERE.bat
```

4. **WebSocket connection failed**
- Check firewall settings
- Verify CORS configuration
- Ensure WebSocket support in proxy

### Performance Optimization

1. **Enable Gzip Compression**
```javascript
// In server.js
const compression = require('compression');
app.use(compression());
```

2. **Add Rate Limiting**
```javascript
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);
```

3. **Database Optimization**
- Add indexes for frequently queried fields
- Implement connection pooling
- Use Redis for caching

## 📈 Scaling Considerations

### Horizontal Scaling
- Use load balancer (AWS ALB, Nginx)
- Implement sticky sessions for WebSocket
- Use Redis for session storage

### Database Scaling
- Read replicas for PostgreSQL
- Redis Cluster for caching
- MongoDB sharding for analytics

### CDN Integration
- CloudFront for static assets
- Edge caching for API responses
- Global distribution

## 🔐 Security Checklist

- [ ] HTTPS enabled
- [ ] JWT tokens secured
- [ ] Rate limiting implemented
- [ ] Input validation active
- [ ] CORS properly configured
- [ ] Security headers set
- [ ] Regular dependency updates
- [ ] Environment variables secured

## 📞 Support

For deployment issues:
1. Check logs: `pm2 logs smartbus-backend`
2. Verify health: `curl http://localhost:3000/health`
3. Review configuration files
4. Check system resources

---

**🚌 SmartBus Tracker - Ready for Production! 🏆**