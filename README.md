*This project has been created as part of the 42 curriculum by flima.*

# Inception

A complete Docker-based infrastructure built from scratch.

---

## Description

**Inception** is a system administration project from the 42 curriculum that challenges you to build a small but fully functional web infrastructure using **Docker** and **Docker Compose**,  entirely from custom-written `Dockerfile`s.

The goal is to virtualize a multi-service architecture inside a personal virtual machine, gaining hands-on experience with containerization, service isolation, networking, and secret management.

### Services included

| Service | Role |
|--------|------|
| **NGINX** | Reverse proxy with TLS encryption (TLSv1.2/TLSv1.3) on port 443 |
| **WordPress + PHP-FPM** | A content management system running on PHP FastCGI Process Manager |
| **MariaDB** | Relational database server providing persistent storage for WordPress |

All containers run in a custom Docker network and communicate through defined service names. Persistent data is stored in Docker volumes. No `host` network or pre-built DockerHub images are used.

## Instructions

### Prerequisites

- Docker Engine: [Docker](https://docs.docker.com/get-docker/) (v20.10+) and [Docker Compose](https://docs.docker.com/compose/install/) (v2+)
- A [Virtual Machine](https://www.virtualbox.org/) running [Debian](https://www.debian.org/) or Alpine Linux (as per 42 guidelines)
- Make utility (sudo apt update && sudo apt install make)

### Setup

**1. Clone the repository**

```bash
git https://github.com/Filipe-FLima/Inception.git
cd Inception
```

**2. Configure your environment**

Create a `.env` file at the root (or populate `secrets/` as required by your setup):

```env
DOMAIN_NAME=flima.42.fr

PORT=443
WORDPRESS_PORT=9000
MARIADB_PORT=3306

MYSQL_HOSTNAME=mariadb
MYSQL_DATABASE=wordpress
MYSQL_USER=

# WordPress Admin Account
WP_ADMIN=
WP_ADMIN_EMAIL=

# WordPress user Account
WP_USER=
WP_USER_EMAIL=
```

> ⚠️ Passwords and sensitive values should be stored as Docker Secrets, not in `.env`.

**Secrets folder**
 
Create a `secrets/` folder at the root of the repository and populate each file with the corresponding password (plain text, no quotes):
 
```
secrets/
├── mysql_password.txt
├── mysql_root_password.txt
├── wp_user_password.txt
└── wp_admin_password.txt
```
 
```bash
echo "your_db_password"    > secrets/mysql_password.txt
echo "your_root_password"  > secrets/mysql_root_password.txt
echo "your_wp_user_pass"   > secrets/wp_user_password.txt
echo "your_wp_admin_pass"  > secrets/wp_admin_password.txt
```
 
These files are referenced in `docker-compose.yml` as:
 
```yaml
secrets:
  db_password:
    file: ../secrets/mysql_password.txt
  db_root_password:
    file: ../secrets/mysql_root_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
```
 
> Make sure `secrets/` is listed in your `.gitignore` to avoid committing credentials.

**3. Add your domain to `/etc/hosts`**

```bash
echo "127.0.0.1 flima.42.fr" | sudo tee -a /etc/hosts
```

**4. Update the Makefile**
   
Modify the volume paths in the Makefile to match desired locations:
```bash
WP_DATA_DIR = $(HOME)/flima/data/wordpress
MDB_DATA_DIR = $(HOME)/flima/data/mariadb
 ```
Also update the volume paths in `srcs/docker-compose.yml`:
```yaml
volumes:
	mariadb:
    	driver_opts:
    	device: ${HOME}/flima/data/mariadb
	wordpress:
    	driver_opts:
        device: ${HOME}/flima/data/wordpress
```

**5. Build and run**

```bash
make
```

This command will:
- Create the necessary data directories
- Build all Docker images from the Dockerfiles
- Start all containers in detached mode

**Other useful commands:**

- **Stop all services:**
  ```bash
  make down
  ```

- **Stop and remove all containers:**
  ```bash
  make clean
  ```

- **Complete cleanup** (removes containers, images, volumes, and data):
  ```bash
  make fclean
  ```

- **Rebuild everything from scratch:**
  ```bash
  make re
  ```

**6. Access**

Open your browser and navigate to: `https://flima.42.fr`

> NGINX uses a self-signed TLS certificate — accept the browser warning on first visit.

### Useful commands

```bash
# View running containers
docker ps

# View logs for a service
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb
```
---

### Design Choices

#### Virtual Machines vs Docker

| | Virtual Machines | Docker |
|---|---|---|
| **Isolation** | Full OS-level isolation | Process-level isolation via namespaces/cgroups |
| **Weight** | Heavy (GBs per VM) | Lightweight (MBs per image) |
| **Startup** | Minutes | Seconds |
| **Use case** | Full system emulation | Application-level packaging |

In this project, Docker provides a lightweight and reproducible way to isolate each service without the overhead of spinning up multiple VMs.

#### Secrets vs Environment Variables

| | Secrets | Environment Variables |
|---|---|---|
| **Storage** | Mounted as files in `/run/secrets/` | Injected into process environment |
| **Exposure** | Not visible in `docker inspect` | Visible in `docker inspect` and logs |
| **Best for** | Passwords, tokens, sensitive credentials | Non-sensitive config (ports, hostnames) |
| **Scope** | Only services that explicitly declare them | Any container |

This project uses **Docker Secrets** for credentials (database password, WordPress admin password) to avoid leaking sensitive data through environment introspection.

#### Docker Network vs Host Network

| | Docker Network (bridge) | Host Network |
|---|---|---|
| **Isolation** | Full network namespace per container | Shares the host's network stack |
| **Security** | Containers can't reach each other unless linked | Any container can reach all host ports |
| **Port control** | Explicit port mapping required | No port mapping needed |
| **Use case** | Multi-service apps, microservices | Low-latency single-container use cases |

Inception uses a **custom bridge network** (`inception`) so containers can reach each other by service name (e.g., `wordpress` → `mariadb`) while remaining isolated from the host.

#### Docker Volumes vs Bind Mounts

| | Docker Volumes | Bind Mounts |
|---|---|---|
| **Location** | Managed by Docker (`/var/lib/docker/volumes/`) | Explicit path on the host filesystem |
| **Portability** | High — Docker manages lifecycle | Low — depends on host directory structure |
| **Performance** | Optimized for container I/O | Depends on OS and filesystem |
| **Best for** | Persistent app data (DB, uploads) | Dev configs, source code during development |

This project uses **named Docker volumes** for WordPress files and MariaDB data, ensuring data persists across container restarts without coupling to host paths.

---

## Resources

### Docker & Containerization

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Networking Overview](https://docs.docker.com/network/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

### Services

- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI (wp-cli)](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

### TLS / SSL

- [Let's Understand TLS Certificates](https://www.cloudflare.com/learning/ssl/what-is-an-ssl-certificate/)
- [OpenSSL Self-Signed Certificate](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html)

### 42-specific references

- [42 Inception Subject (PDF)](https://cdn.intra.42.fr/pdf/pdf/13751/en.subject.pdf)
- [OmarBR71/inception (reference walkthrough)](https://github.com/codesshaman/inception)

---

### AI Usage

AI was used throughout the development of this project in the following ways:

**Learning and Understanding**  
AI helped me understand new concepts such as Docker, containerization, NGINX, PHP-FPM, and MariaDB, and how these technologies work together.

**Troubleshooting and Problem Solving**  
When errors occurred, AI helped analyze issues, explain their causes, and suggest possible solutions.

**Explanations and Review**  
AI explained configuration options in Dockerfiles, docker-compose.yml, NGINX configs, and shell scripts, and reviewed them for potential issues or improvements.

**Best Practices and Security**  
AI provided guidance on good practices such as running services as non-root users, handling secrets properly, and applying the principle of least privilege.

**Documentation**  
AI helped structure and write this README.

Overall, AI acted as a learning companion, helping me move from unfamiliar concepts to a working implementation that follows project guidelines and industry best practices.

---
