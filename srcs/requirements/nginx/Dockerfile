# Base image: Debian bookworm
FROM debian:bookworm

# Install Nginx (web server) and OpenSSL (TLS certificate toolkit)
RUN apt-get update && \
	apt-get install -y nginx openssl && \
	rm -rf /var/lib/apt/lists/*

# Create a directory to store the TLS certificate and private key
RUN mkdir -p /etc/nginx/ssl

# Generate a self-signed TLS certificate (RSA 4096, SHA-256)
RUN openssl req -newkey rsa:4096 -x509 -sha256 -nodes \
	-out /etc/nginx/ssl/tls_certificate.crt \
	-keyout /etc/nginx/ssl/tls_certificate.key \
	-subj "/C=NL/ST=NH/L=Amsterdam/O=42/OU=CODAM/CN=flima.42.fr"

# Copy the Nginx server configuration into the container
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTPS port
EXPOSE 443

# Run Nginx in the foreground so the container stays alive
CMD ["nginx", "-g", "daemon off;"]