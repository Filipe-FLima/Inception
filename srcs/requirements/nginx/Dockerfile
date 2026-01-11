# Use debian buster as base image
FROM debian:buster

# Install nginx and openssl
RUN apt-get update && \
	apt-get install -y nginx openssl && \
	rm -rf /var/lib/apt/lists/*

# Creat a new path to store the ssl certificate
RUN mkdir -p /etc/nginx/ssl

# Generate self certificate of size 4096bits
RUN openssl req -newkey rsa:4096 -x509 -sha256 -nodes \
	-out /etc/nginx/ssl/inception.crt \
	-keyout /etc/nginx/ssl/inception.key \
	-subj "/C=NL/ST=NH/L=Amsterdam/O=42/OU=CODAM/CN=flima.42.fr"

# Copy the new  nginx configuration into nginx folder
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 443

# Start nginx in the foreground, ensuring the container remains alive 
CMD ["nginx", "-g", "daemon off;"]