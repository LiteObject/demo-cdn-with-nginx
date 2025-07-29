FROM nginx:latest

# Copy our nginx config to the container
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static HTML files to the container
COPY ./html /usr/share/nginx/html

# Expose port 80 for HTTP traffic
EXPOSE 80

# Add health check to monitor nginx status
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD [ "nginx", "-g", "daemon off;" ]