# Migration Guide: Iodine to Phusion Passenger + nginx

This document provides a comprehensive guide for migrating your Libreverse Rails application from Iodine to Phusion Passenger with nginx.

## Overview

**Current Setup:**

- Web Server: Iodine
- Process Management: Foreman
- Deployment: Docker

**Target Setup:**

- Web Server: Phusion Passenger + nginx
- Process Management: Passenger + systemd/supervisor (or Docker)
- Deployment: Docker (recommended) or traditional

## Benefits of Migration

1. **Performance**: nginx efficiently handles static files and slow clients
2. **Stability**: Passenger provides process monitoring and auto-restart
3. **Scalability**: Better resource management and horizontal scaling
4. **Security**: Enhanced security features and request filtering
5. **Production-Ready**: Battle-tested in enterprise environments

## Migration Steps

### Phase 1: Preparation

1. **Backup Current System**

    ```bash
    # Create a backup of your current deployment
    docker save your-current-image:tag > libreverse-iodine-backup.tar
    ```

2. **Test in Development**

    ```bash
    # Update Gemfile (already done)
    bundle install
    
    # Test with Passenger standalone
    bundle exec passenger start -p 3000 --environment development
    ```

### Phase 2: Docker-based Migration (Recommended)

1. **Build New Image**

    ```bash
    # Build the new Passenger-enabled image
    docker build -f Dockerfile.passenger -t libreverse:passenger .
    ```

2. **Test the New Image**

    ```bash
    # Test the container
    docker run -p 80:80 -p 443:443 -e RAILS_ENV=production libreverse:passenger
    ```

3. **Update docker-compose.yml (if using)**

    ```yaml
    version: "3.8"
    services:
        web:
            build:
                context: .
                dockerfile: Dockerfile.passenger
            ports:
                - "80:80"
                - "443:443"
            environment:
                - RAILS_ENV=production
                - DATABASE_URL=sqlite3:///data/production.sqlite3
            volumes:
                - app_data:/data

    volumes:
        app_data:
    ```

### Phase 3: Traditional Server Migration (Alternative)

If you prefer traditional server deployment:

1. **Install nginx and Passenger**

    ```bash
    # Ubuntu/Debian
    sudo apt install nginx
    gem install passenger
    sudo passenger-install-nginx-module
    
    # CentOS/RHEL
    sudo yum install nginx
    gem install passenger
    sudo passenger-install-nginx-module
    ```

2. **Configure nginx**

    ```bash
    # Copy nginx configuration
    sudo cp config/nginx.conf /etc/nginx/sites-available/libreverse
    sudo ln -s /etc/nginx/sites-available/libreverse /etc/nginx/sites-enabled/
    sudo rm /etc/nginx/sites-enabled/default
    ```

3. **Configure Passenger**

    ```bash
    # Add Passenger configuration to nginx
    sudo passenger-config about ruby-command
    # Update /etc/nginx/nginx.conf with passenger_root and passenger_ruby
    ```

### Phase 4: Configuration Updates

1. **Environment Variables**
   Update your environment variables to include nginx-specific settings:

    ```bash
    # nginx settings
    export NGINX_WORKER_PROCESSES=auto
    export PASSENGER_MAX_POOL_SIZE=10
    export PASSENGER_MIN_INSTANCES=2
    export PASSENGER_MAX_REQUESTS=1000
    ```

2. **SSL Configuration (Production)**

    ```bash
    # Install Let's Encrypt certificates
    sudo apt install certbot python3-certbot-nginx
    sudo certbot --nginx -d your-domain.com
    ```

3. **Monitoring Setup**

    ```bash
    # Check Passenger status
    sudo passenger-status
    sudo passenger-memory-stats
    
    # nginx logs
    tail -f /var/log/nginx/access.log
    tail -f /var/log/nginx/error.log
    ```

## Configuration Files Created

- `config/nginx.conf` - nginx server configuration
- `Dockerfile.passenger` - Docker configuration with Passenger
- `config/docker-entrypoint-passenger.sh` - Docker startup script
- `config/passenger.conf` - Passenger standalone configuration
- `Procfile.passenger` - Production process configuration
- `Procfile.passenger.dev` - Development process configuration

## Testing the Migration

### 1. Functional Testing

```bash
# Test basic functionality
curl -I http://localhost/
curl http://localhost/health

# Test static file serving
curl -I http://localhost/assets/application.css

# Test application routes
curl http://localhost/your-test-route
```

### 2. Performance Testing

```bash
# Basic load testing with Apache Bench
ab -n 1000 -c 10 http://localhost/

# Memory usage monitoring
watch -n 5 passenger-memory-stats
```

### 3. WebSocket Testing

```bash
# Test Action Cable functionality
# Use browser dev tools to verify WebSocket connections work
```

## Rollback Plan

If issues occur during migration:

### Docker Rollback

```bash
# Stop new container
docker stop libreverse-passenger

# Start previous container
docker run -d --name libreverse-iodine libreverse:iodine

# Or restore from backup
docker load < libreverse-iodine-backup.tar
```

### Traditional Server Rollback

```bash
# Switch back to Iodine
# Update Gemfile to use iodine instead of passenger
bundle install

# Update nginx configuration to proxy to Iodine
# Or disable nginx and run Iodine directly on port 80
```

## Performance Tuning

### nginx Tuning

```nginx
# Add to nginx.conf
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
client_max_body_size 50M;
```

### Passenger Tuning

```nginx
# Passenger-specific tuning
passenger_max_pool_size 20;
passenger_min_instances 3;
passenger_max_instances_per_app 10;
passenger_pool_idle_time 300;
passenger_max_requests 1000;
```

### Rails Tuning

```ruby
# config/environments/production.rb
config.cache_classes = true
config.eager_load = true
config.consider_all_requests_local = false
config.action_controller.perform_caching = true
```

## Monitoring and Maintenance

### Key Metrics to Monitor

- Response times
- Memory usage
- CPU usage
- Error rates
- Request throughput

### Log Files to Monitor

- `/var/log/nginx/access.log`
- `/var/log/nginx/error.log`
- Rails application logs
- Passenger logs

### Regular Maintenance Tasks

```bash
# Restart Passenger processes
sudo passenger-config restart-app /path/to/app

# Reload nginx configuration
sudo nginx -s reload

# Check Passenger status
sudo passenger-status

# Monitor memory usage
sudo passenger-memory-stats
```

## Troubleshooting

### Common Issues

1. **Permission Errors**

    ```bash
    # Fix file permissions
    sudo chown -R www-data:www-data /path/to/app
    sudo chmod -R 755 /path/to/app
    ```

2. **Ruby Path Issues**

    ```bash
    # Check Ruby path
    passenger-config about ruby-command
    which ruby
    ```

3. **Asset Serving Issues**

    ```bash
    # Precompile assets
    RAILS_ENV=production bundle exec rails assets:precompile
    ```

4. **Database Connection Issues**

    ```bash
    # Check database permissions
    ls -la db/
    sudo chown rails:rails db/production.sqlite3
    ```

### Getting Help

- Passenger documentation: <https://www.phusionpassenger.com/docs/>
- nginx documentation: <https://nginx.org/en/docs/>
- Rails guides: <https://guides.rubyonrails.org/>

## Security Considerations

1. **File Permissions**: Ensure proper ownership and permissions
2. **SSL/TLS**: Use strong ciphers and protocols
3. **Rate Limiting**: Configure appropriate rate limits
4. **Security Headers**: Implement security headers in nginx
5. **Regular Updates**: Keep nginx, Passenger, and Rails updated

## Next Steps

After successful migration:

1. Monitor application performance for 24-48 hours
2. Set up proper monitoring and alerting
3. Configure automated backups
4. Plan for horizontal scaling if needed
5. Optimize based on traffic patterns

This migration will provide a more robust, scalable, and production-ready setup for your Libreverse application.
