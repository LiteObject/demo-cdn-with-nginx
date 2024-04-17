FROM nginx:latest

# Copy our nginx config to the container
COPY nginx.conf /etc/nginx/nginx.conf

# Copy our static files to the container
COPY ./html /usr/share/nginx/html

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start nginx
CMD [ "nginx", "-g", "daemon off;" ]