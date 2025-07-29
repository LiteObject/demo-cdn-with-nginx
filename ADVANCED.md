# Advanced NGINX CDN Proxy Features

This document explains the advanced features available in `nginx-advanced.conf` and how to use them.

## 🚀 Features Overview

### Performance Features
- **Caching**: Multi-tier caching with separate zones for CDN and static content
- **Compression**: Gzip compression with optimal settings
- **Connection Pooling**: Keepalive connections to upstream servers
- **Load Balancing**: Multiple upstream servers with health checks

### Security Features
- **Rate Limiting**: Different limits for different endpoints
- **Security Headers**: Complete set of security headers
- **User Agent Blocking**: Block malicious bots and crawlers
- **Origin Validation**: Stricter CORS with allowed origins

### Monitoring Features
- **Health Checks**: Multiple health check endpoints
- **Detailed Logging**: Enhanced log formats with timing information
- **Cache Statistics**: Cache status and performance metrics
- **Debug Endpoints**: Administrative endpoints for troubleshooting

### Reliability Features
- **Upstream Failover**: Automatic failover to backup servers
- **Circuit Breaker**: Upstream health monitoring
- **Graceful Error Handling**: Custom error pages and fallbacks

## 📋 Quick Start

### Using Docker Compose (Recommended)

```bash
# Start both basic and advanced versions
docker-compose up -d

# Start only the advanced version
docker-compose up -d cdn-proxy-advanced

# Start with log monitoring
docker-compose --profile monitoring up -d
```

### Manual Docker Build

```bash
# Build advanced image
docker build -f Dockerfile.advanced -t cdn-proxy-advanced .

# Run with cache volume
docker run -d \
  -p 8081:80 \
  -v nginx_cache:/var/cache/nginx \
  --name cdn-proxy-advanced \
  cdn-proxy-advanced
```

## 🔧 Configuration Sections

### 1. Performance Optimization

```nginx
# Event loop optimization
events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

# HTTP performance
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
}
```

### 2. Caching Configuration

```nginx
# Cache zones
proxy_cache_path /var/cache/nginx/cdn 
                 levels=1:2 
                 keys_zone=cdn_cache:100m 
                 max_size=2g 
                 inactive=24h;

# Cache usage
location /datafiles/ {
    proxy_cache cdn_cache;
    proxy_cache_valid 200 30m;
    proxy_cache_valid 404 5m;
}
```

### 3. Rate Limiting

```nginx
# Define rate limit zones
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=datafiles:10m rate=30r/s;

# Apply rate limits
location /datafiles/ {
    limit_req zone=datafiles burst=50 nodelay;
}
```

### 4. Load Balancing

```nginx
# Define upstream servers
upstream optimizely_cdn {
    server cdn.optimizely.com:443 max_fails=3 fail_timeout=30s weight=3;
    server cdn-eu.optimizely.com:443 max_fails=3 fail_timeout=30s weight=2;
    server cdn-backup.optimizely.com:443 backup;
    keepalive 32;
}
```

## 📊 Monitoring Endpoints

### Health Check
```bash
curl http://localhost:8081/health
# Response: healthy
```

### Service Status
```bash
curl http://localhost:8081/api/status
# Response: JSON with service information
```

### Cache Statistics
```bash
curl http://localhost:8081/api/cache-stats
# Response: JSON with cache configuration
```

### Configuration Test (localhost only)
```bash
curl http://localhost:8081/admin/config-test
# Response: Configuration OK
```

## 🔍 Testing Advanced Features

### 1. Test Rate Limiting

```bash
# Generate multiple requests quickly
for i in {1..20}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8081/datafiles/test
done
# Should see some 429 (Too Many Requests) responses
```

### 2. Test Caching

```bash
# First request (cache MISS)
curl -I http://localhost:8081/datafiles/test.json
# Check X-Cache-Status header

# Second request (cache HIT)
curl -I http://localhost:8081/datafiles/test.json
# Should show cache HIT in X-Cache-Status
```

### 3. Test CORS

```bash
# OPTIONS preflight request
curl -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: GET" \
  http://localhost:8081/datafiles/

# Should return 204 with CORS headers
```

### 4. Test Security Headers

```bash
curl -I http://localhost:8081/
# Check for security headers:
# X-Frame-Options, X-Content-Type-Options, etc.
```

## 📈 Performance Monitoring

### Log Analysis

```bash
# View access logs with timing
docker exec cdn-proxy-advanced tail -f /var/log/nginx/access.log

# View error logs
docker exec cdn-proxy-advanced tail -f /var/log/nginx/error.log
```

### Cache Monitoring

```bash
# Check cache directory size
docker exec cdn-proxy-advanced du -sh /var/cache/nginx/

# List cached files
docker exec cdn-proxy-advanced find /var/cache/nginx/ -type f | wc -l
```

## 🛠️ Customization

### Adding New Upstream Services

1. Define upstream block:
```nginx
upstream new_service {
    server api.example.com:443;
    keepalive 16;
}
```

2. Add location block:
```nginx
location /api/new-service/ {
    proxy_pass https://new_service/;
    proxy_cache cdn_cache;
    # Add CORS and other headers as needed
}
```

### Adjusting Rate Limits

```nginx
# Modify existing zones or add new ones
limit_req_zone $binary_remote_addr zone=custom:10m rate=5r/s;

location /custom-endpoint/ {
    limit_req zone=custom burst=10 nodelay;
}
```

### Custom Error Pages

Create HTML files in `/usr/share/nginx/html/errors/`:
- `400.html` - Bad Request
- `403.html` - Forbidden
- `404.html` - Not Found
- `429.html` - Rate Limited
- `50x.html` - Server Errors

## 🔧 Production Considerations

### SSL/TLS Configuration

For production, add SSL termination:

```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
}
```

### Environment-Specific Settings

- **Development**: Enable debug logging, allow all origins
- **Staging**: Production-like but with relaxed rate limits
- **Production**: Strict security, optimized caching, monitoring

### Scaling Considerations

- Use external cache storage (Redis/Memcached)
- Implement proper log rotation
- Monitor resource usage and adjust worker processes
- Use external load balancer for multiple nginx instances

## 📚 Additional Resources

- [NGINX Documentation](https://nginx.org/en/docs/)
- [NGINX Rate Limiting](https://www.nginx.com/blog/rate-limiting-nginx/)
- [NGINX Caching Guide](https://www.nginx.com/blog/nginx-caching-guide/)
- [NGINX Security Headers](https://www.nginx.com/blog/adding-security-headers-nginx-plus/)
