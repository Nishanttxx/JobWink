# Multi-stage Docker build using official Flutter 3.47.2 / Dart 3.13.2 image
FROM ghcr.io/cirruslabs/flutter:3.47.2 AS build

WORKDIR /app

# Copy dependency definitions
COPY pubspec.yaml pubspec.lock ./

# Print SDK versions before resolving dependencies
RUN which flutter && which dart && flutter --version && dart --version

# Resolve dependencies
RUN flutter pub get

# Copy full application
COPY . .

# Build production web bundle
RUN flutter build web --release

# Production static web server
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
