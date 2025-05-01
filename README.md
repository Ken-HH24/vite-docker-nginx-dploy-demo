# A simple vite project using nginx and docker to deploy

## create an nginx.config
```nginx
worker_processes 1;

events {
    worker_connections 1024;
};

http {
    include mime.types;

    root /usr/share/nginx/html;
    index index.html;

    server {
        listen 8080;
        server_name localhost;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
};
```

Let's explain some details of this file
- *root /usr/share/nginx/html*: It tells nginx to find the files to response in `/usr/share/nginx/html` folder.

    - For example. When a user request http://example.com/about.html. Nginx will look for `about.html` in the directory, which will be `/usr/share/nginx/html/about.html`

- *include mime.types*: It instructs Nginx to set the `Content-Type` of response correctly.

- *try_files*: When the server receive a `$uri` request, Nginx will first looks for if there is a *file* called `$uri`, then look for a *directory* called `$uri`. In the end, if no one matches. It will return the `index.html`

## create a dockerfile

```dockerfile
# using node-22 version
FROM node:22 as build

# set /app as workdir
WORKDIR /app

# copy package.json to /app
COPY package*.json ./

# install dependencies
RUN npm install

# copy the project especially node_modules to /app
COPY . .

# build the project
RUN npm run build

# change the enviroment to nginx
FROM nginx:1.27.4

# copy the dist to correspond Nginx default directory
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

# run your Nginx
CMD ["nginx", "-g", "daemon off;"]
```

## vps, domain and ssl

### vps
- vps: [vultra](https://www.namesilo.com/) (connect with ssh)
- domain: [namesilo](https://www.namesilo.com/)
- ssl: [Cloudflare](https://dash.cloudflare.com/login)

After buying the domain on namesilo. You are able to config your *NameServers* to cloudflare. And add a ssl certificate on your vps.

## config your ssl
After adding `cert.pem` and `key.pem` on your vps. You need to modify the `nginx.config` and `Dockerfile`.

### Dockerfile

Adding the `COPY` command to copy these two files.

```Dockerfile
COPY ssl/cert.pem /etc/nginx/ssl/cert.pem

COPY ssl/key.pem /etc/nginx/ssl/key.pem
```

### nginx.config

Add SSL configuration to tell Nginx where the `cert.pem` and `key.pem` files are.

```nginx.config
server {

    # SSL configuration
    listen 443 ssl;
    ssl_certificate         /etc/nginx/ssl/cert.pem;
    ssl_certificate_key     /etc/nginx/ssl/key.pem;

    # ... ...
}
```

## config your domain
After adding the ssl. You also need to config the `nginx.config` to tell Nginx what your domain is. So add the `server_name` config.

```nginx.config
server {
    server_name xxx.xxx www.xxx.xxx;
}
```

# Run your project on vps
I use a simple way to run my project. Here are the steps:
1. push the project to github.
2. clone the project using vps and ssh.
3. use `docker build -t vite-nginx-app:0.0.1 .` command to build the image.
4. use `docker run -d -p 0:80 -p 443:443 vite-nginx-app:0.0.1` command to run the image.

# Reference

- https://www.digitalocean.com/community/tutorials/how-to-host-a-website-using-cloudflare-and-nginx-on-ubuntu-22-04
- https://yeasy.gitbook.io/docker_practice