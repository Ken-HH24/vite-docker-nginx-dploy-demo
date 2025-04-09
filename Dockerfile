FROM node:22 as build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM nginx:1.27.4

COPY nginx.conf /etc/nginx/nginx.conf

COPY ssl/cert.pem /etc/nginx/ssl/cert.pem

COPY ssl/key.pem /etc/nginx/ssl/key.pem

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]