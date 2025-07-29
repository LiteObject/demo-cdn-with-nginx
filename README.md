# How to create a CDN Proxy locally with NGINX

## What this project does
This project demonstrates how to use NGINX as a **local CDN proxy** that:
- Routes requests to external CDNs (like Optimizely)
- Adds CORS headers to solve cross-origin issues
- Provides a single local endpoint for multiple external CDN resources
- Acts as a reverse proxy for CDN content

**Note**: This is not a true CDN (which requires geographic distribution), but rather a local proxy that helps access external CDNs more easily and solve common CORS issues in web development.

## What is CDN?
A content delivery network, or CDN, is a geographically distributed network of servers that help deliver internet content more efficiently. A CDN allows for the fast delivery of assets needed for loading internet content such as HTML pages, JavaScript files, CSS files, image files and videos by distributing cached copies of them to numerous edge servers located closer to the user.

## What is NGINX?
Nginx is a free, open-source web server created by Igor Sysoev. It is commonly used for serving static files, as a reverse proxy, load balancer, mail proxy and HTTP cache. Some key things to know about Nginx:

- High performance: Nginx is known for being a very fast and lightweight web server due to its asynchronous and event-driven architecture. It can serve static files very quickly and is able to handle thousands of concurrent connections efficiently.

- Reverse proxy: Nginx can act as a reverse proxy, sitting in front of application servers like PHP-FPM, Node.js, Ruby on Rails etc. This improves performance by caching responses and load balancing requests across multiple backends.

- Load balancer: Nginx's load balancing capabilities allow it to distribute traffic evenly across multiple servers. This increases application scalability and availability. Features like weighted round-robin help control traffic distribution.

- HTTP server: At its core, Nginx serves HTTP requests and can deliver static files very quickly. It also supports features like URL rewriting, access control lists and more.

- Open source: Nginx is free, open source software available on Linux, BSD, Mac OS X and more. The code is actively maintained by a developer community.

- Small memory footprint: Compared to traditional web servers, Nginx has a very small memory footprint which makes it suitable for low-powered devices and high traffic workloads.

## Explanation of the `Dockerfile`

### FROM
The `FROM` instruction in a `Dockerfile` sets the base image for subsequent instructions. This line indicates that the build should use the official nginx image tagged as latest as the starting point.

### COPY . .
The `COPY` instruction in a `Dockerfile` is used to copy new files, directories (or remote file URLs) from the host machine into the filesystem of the container.

### EXPOSE 80

The `EXPOSE` instruction in a `Dockerfile` informs Docker that the container listens on the specified network ports at runtime. It does not actually publish the ports, it only defines which ports the container wants to expose.

### CMD [ "nginx", "-g", "daemon off;"]

The `CMD` instruction in a Dockerfile defines what command gets executed when the container starts. Here it is running the nginx web server process.

The `-g` parameter passed to nginx tells it to run in the foreground instead of as a daemon. Running in the foreground means the nginx process will be tied to the terminal and log output will be sent to stdout/stderr.

This is useful for development and debugging purposes so you can see nginx logs. In a production setting you'd typically want nginx to run as a daemon in the background.

So in summary, this line is configuring the Docker container to start the nginx web server process on container startup, and run it in the foreground for easier logging and debugging.

## Build the image

    docker build -t my-cdn .

The `-t` flag tags the image, in this case with the name `my-cdn`. Tagging the image allows it to be easily referred to later, for example when running a container from the image.

this command is building a Docker image using the instructions in the Dockerfile in the current directory, and tagging the resulting image as 
`my-cdn`. This allows the image to then be run as a container using 
`docker run my-cdn` for example.

## Run the container

    docker run -d -p 8080:80 --name local-cdn my-cdn

`-d` runs the container in detached/background mode so it doesn't block the terminal

`-p 8080:80` publishes port 80 inside the container to port 8080 on the host machine, so traffic on 8080 will be forwarded to the Nginx server inside

`--name local-cdn` names the container "local-cdn" for easy reference later

`my-cdn` specifies the image name to use, which was tagged when building

## Explain nginx.conf

Our nginx.conf demonstrates a CDN proxy setup with the following features:

```conf
# Events block - connection processing
events {
    worker_connections 1024;
}

# HTTP context with DNS resolver
http {
    # Configure DNS resolver for upstream server name resolution
    resolver 8.8.8.8 valid=1200s;
    
    # Main server block - handles all incoming requests on port 80
    server {
        listen 80;
        server_name localhost;
        
        # Enable debug logging for troubleshooting
        error_log /var/log/nginx/error.log debug;
        access_log /var/log/nginx/access.log;
        
        # Location block for redirecting to Google
        # Example of proxying requests to an external site
        location /redirect-to-google {
            # Alternative: Use 301 redirect instead of proxy
            # return 301 https://www.google.com;
            proxy_pass https://www.google.com;
        }
        
        # Location block for proxying Optimizely CDN datafiles
        # This acts as a CORS-enabled proxy for accessing external CDN resources
        location /datafiles/ {
            # Don't forward the original request body to upstream
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            
            # Proxy requests to Optimizely's CDN
            proxy_pass https://cdn.optimizely.com/datafiles/;
            
            # Add CORS headers to allow cross-origin requests
            add_header 'Access-Control-Allow-Methods' 'GET,OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
            
            # Set the Host header to match the upstream server
            proxy_set_header Host cdn.optimizely.com;
        }
        
        # Document root directory for serving static files
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
```

This configuration creates a **local CDN proxy** that:

### Key Features:
- **DNS Resolution**: Uses Google's DNS (8.8.8.8) to resolve upstream server names
- **External Site Proxy**: `/redirect-to-google` demonstrates basic proxying to external sites
- **CORS-Enabled CDN Proxy**: `/datafiles/` route proxies to Optimizely's CDN while adding CORS headers
- **Cross-Origin Support**: Adds necessary CORS headers to allow web applications to access external CDN resources
- **Static File Serving**: Still serves local static files from `/usr/share/nginx/html`
- **Debug Logging**: Enabled for troubleshooting proxy issues

### Why This Setup is Useful:
1. **Solves CORS Issues**: Web browsers block cross-origin requests by default. This proxy adds the necessary CORS headers.
2. **Single Endpoint**: Instead of making requests to multiple CDNs, your application can use one local endpoint.
3. **Development-Friendly**: Allows testing CDN integrations locally without dealing with CORS restrictions.
4. **Flexible Routing**: Can easily add more CDN proxies by adding additional location blocks.

### Example Usage:
Instead of directly accessing:
```
https://cdn.optimizely.com/datafiles/your-file.json
```

Your application can use:
```
http://localhost:8080/datafiles/your-file.json
```

And get the same content with proper CORS headers for cross-origin access.