# Developer Documentation — Inception

This document covers everything a developer needs to set up, build, run, and maintain the Inception infrastructure from scratch. It assumes familiarity with the command line, Docker, and basic networking concepts.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Prerequisites](#2-prerequisites)
3. [Environment Setup](#3-environment-setup)
   - [Clone the repository](#31-clone-the-repository)
   - [Configure `.env`](#32-configure-env)
   - [Configure secrets](#33-configure-secrets)
   - [Configure `/etc/hosts`](#34-configure-etchosts)
4. [Build and Launch](#4-build-and-launch)
   - [Makefile reference](#41-makefile-reference)
   - [Docker Compose reference](#42-docker-compose-reference)
5. [Container Management](#5-container-management)
6. [Data Persistence](#6-data-persistence)

---

## 1. Project Structure

```
inception/
├── DEV_DOC.md
├── Makefile
├── README.md
├── secrets
│   ├── mysql_password.txt
│   ├── mysql_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
├── srcs
│   ├── docker-compose.yml
│   └── requirements
│       ├── mariadb
│       │   ├── conf
│       │   │   └── mariadb.cnf
│       │   ├── Dockerfile
│       │   └── tools
│       │       └── mdb-setup.sh
│       ├── nginx
│       │   ├── conf
│       │   │   └── nginx.conf
│       │   └── Dockerfile
│       └── wordpress
│           ├── conf
│           │   └── www.conf
│           ├── Dockerfile
│           └── tools
│               └── wp-setup.sh
└── USER_DOC.md

```

> No pre-built images are used. Every service is built from a custom `Dockerfile` based on either `debian:bullseye` or `alpine`.

---

## 2. Prerequisites

| Tool | Minimum version | Install |
|------|----------------|---------|
| Docker Engine | 20.10+ | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| Docker Compose | v2+ | [docs.docker.com/compose/install](https://docs.docker.com/compose/install/) |
| Make | any | `sudo apt install make` |
| OpenSSL | any | `sudo apt install openssl` |

Verify your installation:

```bash
docker --version
docker compose version
make --version
```

---

## 3. Environment Setup

### 3.1 Clone the repository

```bash
git clone https://github.com/Filipe-FLima/Inception.git
cd inception
```

### 3.2 Configure `.env`

Create a `.env` file at the root of the repository. This file holds all non-sensitive configuration values used by Docker Compose:

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

# WordPress User Account
WP_USER=
WP_USER_EMAIL=
```

> ⚠️ Do **not** store passwords here. Use secrets (see below).

### 3.3 Configure secrets

Create the `secrets/` directory at the root and populate each file with the corresponding password as plain text (no quotes, no trailing newline issues):

```bash
mkdir -p secrets

echo "your_db_password"    > secrets/mysql_password.txt
echo "your_root_password"  > secrets/mysql_root_password.txt
echo "your_wp_user_pass"   > secrets/wp_user_password.txt
echo "your_wp_admin_pass"  > secrets/wp_admin_password.txt
```

These files are mounted into containers at runtime via Docker Secrets and referenced in `docker-compose.yml` as:

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

Inside each container, secrets are accessible as files under `/run/secrets/`:

```bash
# Example: reading the DB password inside the wordpress container
cat /run/secrets/db_password
```

> 🔒 Add `secrets/` to your `.gitignore` to prevent credentials from being committed.

### 3.4 Configure `/etc/hosts`

Since `flima.42.fr` is not a public DNS entry, you must map it to localhost manually:

```bash
echo "127.0.0.1 flima.42.fr" | sudo tee -a /etc/hosts
```

Verify:

```bash
ping -c 1 flima.42.fr
# Should resolve to 127.0.0.1
```

---

## 4. Build and Launch

### 4.1 Makefile reference

All common operations are wrapped in the `Makefile` at the root. Run all commands from the repository root.

| Command | Description |
|---------|-------------|
| `make` | Creates data directories, builds all images, and starts all containers in detached mode |
| `make down` | Stops all running containers, preserving volumes and data |
| `make clean` | Stops and removes all containers; data volumes are preserved |
| `make fclean` | Full teardown — removes containers, images, volumes, and local data directories |
| `make re` | Equivalent to `make fclean && make`; full rebuild from scratch |

> `make fclean` deletes the local data directories defined in the Makefile (`WP_DATA_DIR` and `MDB_DATA_DIR`). This is irreversible.

**Makefile volume path variables** — update these to match your environment before the first run:

```makefile
WP_DATA_DIR  = $(HOME)/flima/data/wordpress
MDB_DATA_DIR = $(HOME)/flima/data/mariadb
```

### 4.2 Docker Compose reference

For more granular control, you can call Docker Compose directly:

```bash
# Build all images without starting
docker compose -f srcs/docker-compose.yml build

# Start all services in detached mode
docker compose -f srcs/docker-compose.yml up -d

# Start and force a rebuild
docker compose -f srcs/docker-compose.yml up -d --build

# Stop all services
docker compose -f srcs/docker-compose.yml down

# Stop and remove volumes (⚠️ destroys data)
docker compose -f srcs/docker-compose.yml down -v

# Build a single service
docker compose -f srcs/docker-compose.yml build nginx
```

---

## 5. Container Management

### Viewing running containers

```bash
docker ps
```

Expected output when fully running:

```
CONTAINER ID   IMAGE                STATUS         NAMES
xxxxxxxxxxxx   inception-nginx      Up X minutes   nginx
xxxxxxxxxxxx   inception-wordpress  Up X minutes   wordpress
xxxxxxxxxxxx   inception-mariadb    Up X minutes   mariadb
```

### Viewing logs

```bash
# All services
docker compose -f srcs/docker-compose.yml logs

# Single service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb

# Follow logs in real time
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

### Opening a shell inside a container

```bash
docker exec -it nginx     sh
docker exec -it wordpress sh
docker exec -it mariadb   sh
```

### Interacting with MariaDB directly

```bash
docker exec -it mariadb mariadb -u root -p
# Enter the password from secrets/mysql_root_password.txt

# Inside the MariaDB shell:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
EXIT;
```

### Inspecting a container

```bash
# Full container metadata (mounts, network, env, etc.)
docker inspect nginx

# Check which networks a container belongs to
docker inspect nginx --format '{{ json .NetworkSettings.Networks }}'

# Check mounted volumes
docker inspect nginx --format '{{ json .Mounts }}'
```

### Verifying secrets are mounted correctly

```bash
docker exec -it wordpress cat /run/secrets/db_password
```

---

## 6. Data Persistence

### How data is stored

The project uses **named Docker volumes** backed by local host directories. This means data survives container restarts and rebuilds — unless `make fclean` or `docker compose down -v` is explicitly run.

| Volume | Backed by (host path) | Contains |
|--------|-----------------------|----------|
| `mariadb` | `$(HOME)/flima/data/mariadb` | All MariaDB database files |
| `wordpress` | `$(HOME)/flima/data/wordpress` | WordPress core files, themes, uploads |

These paths are defined in both the `Makefile` and `srcs/docker-compose.yml`:

```yaml
volumes:
  mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/flima/data/mariadb
  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/flima/data/wordpress
```

### Inspecting volume contents

```bash
# List all Docker volumes
docker volume ls

# Inspect a specific volume
docker volume inspect inception_mariadb

# Browse the data directly on the host
ls ~/flima/data/mariadb
ls ~/flima/data/wordpress
```

### Persistence behaviour by command

| Command | Containers | Images | Volumes | Host data dirs |
|---------|-----------|--------|---------|----------------|
| `make down` | Stopped | ✅ kept | ✅ kept | ✅ kept |
| `make clean` | Removed | ✅ kept | ✅ kept | ✅ kept |
| `make fclean` | Removed | Removed | Removed | ❌ deleted |
| `docker compose down -v` | Removed | ✅ kept | Removed | ✅ kept |

> After `make fclean`, the next `make` will re-initialize MariaDB and WordPress from scratch using the values in `.env` and `secrets/`.

---

*For end-user instructions, refer to [USER_DOC.md](./USER_DOC.md). For project overview and design decisions, refer to [README.md](./README.md).*