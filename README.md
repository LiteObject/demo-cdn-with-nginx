# How to create a CDN locally with NGINX

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

## Explain nginx.conf

```conf
# the default server
server {
  listen 80;

  # the root of files to serve
  root /usr/share/nginx/html; 

  # indexes if no file is specified
  index index.html index.htm;
}

```

The `nginx.conf` file is the main configuration file for Nginx. It contains global configuration settings as well as server blocks that define how requests are handled.

In this simple example, there is a single server block that defines the default server.

The `listen 80;` line tells Nginx to listen for incoming requests on port 80.

The `root` directive specifies the root folder that contains the files to be served, in this case `/usr/share/nginx/html`.

The `index` directive defines what file should be served if the request URI is a directory - here it will check for `index.html` and `index.htm`.

Additional server blocks can be added for virtual hosts. Inside server blocks you can configure location blocks, authentication, SSL, logging and more.