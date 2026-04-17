# WebSocket Deployment and Configuration Guide

This guide provides comprehensive instructions for deploying and configuring the WebSocket real-time system in production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Deployment](#backend-deployment)
3. [Frontend Configuration](#frontend-configuration)
4. [Environment Setup](#environment-setup)
5. [Production Configuration](#production-configuration)
6. [Security Configuration](#security-configuration)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Performance Tuning](#performance-tuning)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance](#maintenance)

## Prerequisites

### System Requirements

**Backend Requirements:**
- Node.js 18+ 
- Redis 6.0+
- PostgreSQL 13+
- SSL certificates (for production)
- Load balancer (recommended for production)

**Frontend Requirements:**
- Flutter SDK 3.0+
- Android SDK (for Android builds)
- Xcode (for iOS builds)
- Valid code signing certificates

**Infrastructure Requirements:**
- Minimum 2GB RAM per backend instance
- SSD storage for database
- Stable network connectivity
- CDN for static assets (recommended)

### Network Requirements

**Ports:**
- Backend API: 3000 (HTTP) / 443 (HTTPS)
- WebSocket: Same as API (Socket.IO uses HTTP upgrade)
- Redis: 6379 (internal)
- PostgreSQL: 5432 (internal)

**Firewall Rules:**
- Allow inbound HTTP/HTTPS traffic
- Allow WebSocket upgrade requests
- Block direct database access from external networks

## Backend Deployment

### 1. Environment Setup

Create production environment file:

```bash
# backend/.env.production
NODE_ENV=production
PORT=3000

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/ankhanh_cms
DATABASE_SSL=true
DATABASE_POOL_SIZE=20

# Redis Configuration
REDIS_HOST=redis.internal.domain.com
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
REDIS_DB=0

# JWT Configuration
JWT_SECRET=your-super-secure-jwt-secret-key
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# WebSocket Configuration
WEBSOCKET_CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com
WEBSOCKET_TRANSPORTS=websocket,polling
WEBSOCKET_PING_TIMEOUT=60000
WEBSOCKET_PING_INTERVAL=25000

# SSL Configuration (if terminating SSL at application level)
SSL_CERT_PATH=/path/to/certificate.crt
SSL_KEY_PATH=/path/to/private.key

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH=/var/uploads
```

### 2. Docker Deployment

**Dockerfile:**

```dockerfile
# Multi-stage build for production
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS runtime

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

WORKDIR /app

# Copy node_modules from builder stage
COPY --from=builder --chown=nestjs:nodejs /app/node_modules ./node_modules

# Copy application code
COPY --chown=nestjs:nodejs dist ./dist
COPY --chown=nestjs:nodejs package*.json ./

# Create uploads directory
RUN mkdir -p /var/uploads && chown nestjs:nodejs /var/uploads

USER nestjs

EXPOSE 3000

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main.js"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    depends_on:
      - postgres
      - redis
    volumes:
      - uploads:/var/uploads
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ankhanh_cms
      POSTGRES_USER: cms_user
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U cms_user -d ankhanh_cms"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  uploads:
```

### 3. Nginx Configuration

**nginx.conf:**

```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server app:3000;
        keepalive 32;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=websocket:10m rate=5r/s;

    # WebSocket upgrade configuration
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 80;
        server_name yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name yourdomain.com;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/certificate.crt;
        ssl_certificate_key /etc/nginx/ssl/private.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

        # API endpoints
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # WebSocket endpoints
        location /socket.io/ {
            limit_req zone=websocket burst=10 nodelay;
            
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket specific timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 300s;
        }

        # Health check
        location /health {
            proxy_pass http://backend;
            access_log off;
        }
    }
}
```

### 4. Kubernetes Deployment

**deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ankhanh-cms-backend
  labels:
    app: ankhanh-cms-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ankhanh-cms-backend
  template:
    metadata:
      labels:
        app: ankhanh-cms-backend
    spec:
      containers:
      - name: backend
        image: ankhanh/cms-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        - name: REDIS_HOST
          value: "redis-service"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: secret
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: ankhanh-cms-backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
spec:
  tls:
  - hosts:
    - api.yourdomain.com
    secretName: backend-tls
  rules:
  - host: api.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
```

## Frontend Configuration

### 1. Environment Configuration

**Development (frontend/config/environments/development.yaml):**

```yaml
environment:
  name: development
  display_name: Development

app:
  name: AnKhanh CMS Dev
  bundle_id: com.ankhanh.cms.dev

network:
  api_base_url: http://localhost:3000
  websocket_url: ws://localhost:3000
  timeout: 30000

websocket:
  enabled: true
  auto_connect: true
  reconnect_interval: 5000
  max_reconnect_attempts: 5
  heartbeat_interval: 30000
  connection_timeout: 10000
  message_queue_size: 1000
  channels:
    - inventory
    - customers
    - orders
    - notifications
  features:
    real_time_updates: true
    offline_support: true
    background_sync: true
    push_notifications: true

logging:
  level: debug
  enable_crash_reporting: false
```

**Production (frontend/config/environments/production.yaml):**

```yaml
environment:
  name: production
  display_name: Production

app:
  name: AnKhanh CMS
  bundle_id: com.ankhanh.cms

network:
  api_base_url: https://api.yourdomain.com
  websocket_url: wss://api.yourdomain.com
  timeout: 30000

websocket:
  enabled: true
  auto_connect: true
  reconnect_interval: 15000
  max_reconnect_attempts: 10
  heartbeat_interval: 60000
  connection_timeout: 15000
  message_queue_size: 2000
  channels:
    - inventory
    - customers
    - orders
    - notifications
  features:
    real_time_updates: true
    offline_support: true
    background_sync: false  # Disabled for battery optimization
    push_notifications: true

logging:
  level: info
  enable_crash_reporting: true
```

### 2. Build Configuration

**Android (android/app/build.gradle):**

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.ankhanh.cms"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }

    flavorDimensions "environment"
    productFlavors {
        development {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        production {
            dimension "environment"
        }
    }
}
```

**iOS (ios/Runner/Info.plist):**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>yourdomain.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 3. Build Scripts

**build-production.sh:**

```bash
#!/bin/bash

set -e

echo "Building AnKhanh CMS for production..."

# Clean previous builds
flutter clean
flutter pub get

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build Android APK
echo "Building Android APK..."
flutter build apk --release --flavor production

# Build Android App Bundle
echo "Building Android App Bundle..."
flutter build appbundle --release --flavor production

# Build iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building iOS..."
    flutter build ios --release --flavor production
fi

echo "Build completed successfully!"
echo "Android APK: build/app/outputs/flutter-apk/app-production-release.apk"
echo "Android Bundle: build/app/outputs/bundle/productionRelease/app-production-release.aab"

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "iOS: build/ios/iphoneos/Runner.app"
fi
```

## Environment Setup

### 1. Development Environment

```bash
# Backend setup
cd backend
npm install
cp .env.example .env.development
npm run start:dev

# Frontend setup
cd frontend
flutter pub get
flutter packages pub run build_runner build
flutter run --flavor development
```

### 2. Staging Environment

```bash
# Backend
docker-compose -f docker-compose.staging.yml up -d

# Frontend
flutter build apk --release --flavor staging
```

### 3. Production Environment

```bash
# Backend
docker-compose -f docker-compose.production.yml up -d

# Frontend
flutter build appbundle --release --flavor production
```

## Production Configuration

### 1. Load Balancer Configuration

**HAProxy Configuration:**

```
global
    daemon
    maxconn 4096

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend websocket_frontend
    bind *:443 ssl crt /etc/ssl/certs/yourdomain.pem
    redirect scheme https if !{ ssl_fc }
    
    # WebSocket detection
    acl is_websocket hdr(Upgrade) -i websocket
    acl is_websocket_path path_beg /socket.io/
    
    use_backend websocket_backend if is_websocket OR is_websocket_path
    default_backend api_backend

backend api_backend
    balance roundrobin
    option httpchk GET /health
    server api1 10.0.1.10:3000 check
    server api2 10.0.1.11:3000 check
    server api3 10.0.1.12:3000 check

backend websocket_backend
    balance source
    option httpchk GET /health
    server ws1 10.0.1.10:3000 check
    server ws2 10.0.1.11:3000 check
    server ws3 10.0.1.12:3000 check
```

### 2. Redis Cluster Configuration

**redis.conf:**

```
# Network
bind 0.0.0.0
port 6379
protected-mode yes
requirepass your-redis-password

# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Cluster (if using Redis Cluster)
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
```

### 3. Database Configuration

**PostgreSQL Configuration:**

```sql
-- Create database and user
CREATE DATABASE ankhanh_cms;
CREATE USER cms_user WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE ankhanh_cms TO cms_user;

-- Performance tuning
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- Connection pooling
ALTER SYSTEM SET max_connections = 200;

SELECT pg_reload_conf();
```

## Security Configuration

### 1. SSL/TLS Setup

**Generate SSL Certificate:**

```bash
# Using Let's Encrypt
certbot certonly --webroot -w /var/www/html -d yourdomain.com -d api.yourdomain.com

# Or using custom certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/yourdomain.key \
    -out /etc/ssl/certs/yourdomain.crt
```

### 2. Firewall Configuration

**UFW (Ubuntu):**

```bash
# Reset firewall
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# SSH access
ufw allow ssh

# HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Internal services (adjust IP ranges as needed)
ufw allow from 10.0.0.0/8 to any port 5432  # PostgreSQL
ufw allow from 10.0.0.0/8 to any port 6379  # Redis

# Enable firewall
ufw enable
```

### 3. Security Headers

**Express.js Security Middleware:**

```typescript
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP',
});

app.use('/api/', limiter);
```

## Monitoring and Logging

### 1. Application Monitoring

**Prometheus Configuration:**

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ankhanh-cms'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s
```

**Grafana Dashboard:**

```json
{
  "dashboard": {
    "title": "AnKhanh CMS Monitoring",
    "panels": [
      {
        "title": "WebSocket Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "websocket_connections_total",
            "legendFormat": "Active Connections"
          }
        ]
      },
      {
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "http_request_duration_seconds",
            "legendFormat": "Response Time"
          }
        ]
      }
    ]
  }
}
```

### 2. Logging Configuration

**Winston Logger Setup:**

```typescript
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'ankhanh-cms' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}
```

### 3. Health Checks

**Health Check Endpoint:**

```typescript
@Controller('health')
export class HealthController {
  constructor(
    private readonly databaseService: DatabaseService,
    private readonly redisService: RedisService,
  ) {}

  @Get()
  async check(): Promise<HealthCheckResult> {
    const checks = await Promise.allSettled([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkWebSocket(),
    ]);

    const status = checks.every(check => check.status === 'fulfilled') ? 'healthy' : 'unhealthy';

    return {
      status,
      timestamp: new Date().toISOString(),
      checks: {
        database: checks[0].status === 'fulfilled' ? 'healthy' : 'unhealthy',
        redis: checks[1].status === 'fulfilled' ? 'healthy' : 'unhealthy',
        websocket: checks[2].status === 'fulfilled' ? 'healthy' : 'unhealthy',
      },
    };
  }
}
```

## Performance Tuning

### 1. Backend Optimization

**Node.js Configuration:**

```bash
# Environment variables for production
NODE_ENV=production
NODE_OPTIONS="--max-old-space-size=2048"
UV_THREADPOOL_SIZE=128

# PM2 Configuration
pm2 start dist/main.js --name "ankhanh-cms" -i max --max-memory-restart 1G
```

### 2. Database Optimization

**PostgreSQL Tuning:**

```sql
-- Connection pooling
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '512MB';
ALTER SYSTEM SET effective_cache_size = '2GB';

-- Query optimization
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET seq_page_cost = 1.0;

-- WAL configuration
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET max_wal_size = '2GB';
ALTER SYSTEM SET min_wal_size = '512MB';

-- Checkpoint tuning
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET checkpoint_timeout = '10min';

SELECT pg_reload_conf();
```

### 3. Redis Optimization

**Redis Configuration:**

```
# Memory optimization
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Network optimization
tcp-keepalive 300
timeout 0

# Persistence optimization
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
```

## Troubleshooting

### Common Issues

#### 1. WebSocket Connection Failures

**Symptoms:**
- Clients cannot connect to WebSocket
- Frequent disconnections
- Authentication failures

**Solutions:**

```bash
# Check WebSocket endpoint
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     -H "Sec-WebSocket-Version: 13" \
     https://api.yourdomain.com/socket.io/

# Check logs
docker logs ankhanh-cms-backend | grep -i websocket

# Test Redis connection
redis-cli -h redis-host -p 6379 ping
```

#### 2. High Memory Usage

**Symptoms:**
- Application crashes with out-of-memory errors
- Slow response times
- High swap usage

**Solutions:**

```bash
# Monitor memory usage
docker stats ankhanh-cms-backend

# Analyze heap dump
node --inspect dist/main.js
# Connect Chrome DevTools to analyze memory

# Optimize garbage collection
NODE_OPTIONS="--max-old-space-size=2048 --gc-interval=100"
```

#### 3. Database Connection Issues

**Symptoms:**
- Connection pool exhausted
- Slow queries
- Connection timeouts

**Solutions:**

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Optimize connection pool
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '512MB';
```

### Debugging Tools

**Backend Debugging:**

```bash
# Enable debug logging
DEBUG=* npm run start:dev

# Profile application
node --prof dist/main.js
node --prof-process isolate-*.log > processed.txt

# Memory profiling
node --inspect --inspect-brk dist/main.js
```

**Frontend Debugging:**

```bash
# Enable WebSocket debugging
flutter run --debug --dart-define=WEBSOCKET_DEBUG=true

# Analyze app size
flutter build apk --analyze-size

# Performance profiling
flutter run --profile
```

## Maintenance

### 1. Regular Maintenance Tasks

**Daily:**
- Monitor application logs
- Check system resources
- Verify backup completion

**Weekly:**
- Update security patches
- Analyze performance metrics
- Review error rates

**Monthly:**
- Database maintenance (VACUUM, REINDEX)
- Certificate renewal check
- Capacity planning review

### 2. Backup Strategy

**Database Backup:**

```bash
#!/bin/bash
# backup-database.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/database"
DB_NAME="ankhanh_cms"

# Create backup
pg_dump -h localhost -U cms_user -d $DB_NAME | gzip > "$BACKUP_DIR/backup_$DATE.sql.gz"

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

# Upload to cloud storage (optional)
aws s3 cp "$BACKUP_DIR/backup_$DATE.sql.gz" s3://your-backup-bucket/database/
```

**Application Backup:**

```bash
#!/bin/bash
# backup-uploads.sh

DATE=$(date +%Y%m%d_%H%M%S)
UPLOAD_DIR="/var/uploads"
BACKUP_DIR="/backups/uploads"

# Create backup
tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" -C "$UPLOAD_DIR" .

# Upload to cloud storage
aws s3 cp "$BACKUP_DIR/uploads_$DATE.tar.gz" s3://your-backup-bucket/uploads/
```

### 3. Update Procedures

**Backend Updates:**

```bash
# 1. Backup current version
docker tag ankhanh/cms-backend:latest ankhanh/cms-backend:backup-$(date +%Y%m%d)

# 2. Pull new version
docker pull ankhanh/cms-backend:latest

# 3. Update with zero downtime
docker-compose up -d --no-deps backend

# 4. Verify deployment
curl -f http://localhost:3000/health
```

**Frontend Updates:**

```bash
# 1. Build new version
flutter build appbundle --release --flavor production

# 2. Upload to app stores
# Android: Upload to Google Play Console
# iOS: Upload to App Store Connect

# 3. Gradual rollout
# Start with 5% of users, monitor for issues
```

This deployment guide provides comprehensive instructions for setting up, configuring, and maintaining the WebSocket real-time system in production environments. Follow the security best practices and monitoring guidelines to ensure a stable and secure deployment.