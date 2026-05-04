# User Documentation — Inception

This document explains how to start, access, manage, and verify the Inception infrastructure stack. It is intended for end users and administrators who need to operate the project after initial setup.

---

## Table of Contents

1. [Services Overview](#1-services-overview)
2. [Starting and Stopping the Project](#2-starting-and-stopping-the-project)
3. [Accessing the Website and Administration Panel](#3-accessing-the-website-and-administration-panel)
4. [Credentials — Location and Management](#4-credentials--location-and-management)
5. [Checking That Services Are Running](#5-checking-that-services-are-running)

---

## 1. Services Overview

The Inception stack runs three services, each in its own isolated Docker container:

| Service | Description | Port |
|---------|-------------|------|
| **NGINX** | Acts as a reverse proxy. It is the only entry point to the stack, handling all HTTPS traffic and forwarding requests to WordPress. | `443` (HTTPS) |
| **WordPress + PHP-FPM** | The content management system. Handles all web application logic and communicates with the database. Not directly accessible from outside — only through NGINX. | Internal (`9000`) |
| **MariaDB** | The relational database. Stores all WordPress content, users, and settings. Not directly accessible from outside. | Internal (`3306`) |

> All communication between services happens through an internal Docker network. Only NGINX is exposed to the host machine.

---

## 2. Starting and Stopping the Project

All project management is done via `make` commands from the **root of the repository**.

### Start the project

```bash
make
```

This will build all Docker images (if not already built) and start all containers in the background.

### Stop the project (keep data)

```bash
make down
```

Stops all running containers without deleting volumes or data. Safe to use between sessions.

### Remove all containers

```bash
make clean
```

Stops and removes all containers. Data volumes are preserved — the database and WordPress files remain intact.

### Full reset (⚠️ deletes all data)

```bash
make fclean
```

Removes containers, images, volumes, and all local data directories. Use this only if you want a completely fresh start.

> After `make fclean`, running `make` will re-build and re-initialize everything from scratch, including the database.

### Rebuild from scratch

```bash
make re
```

Equivalent to running `make fclean` followed by `make`. Useful when you've made changes to Dockerfiles or configuration files.

---

## 3. Accessing the Website and Administration Panel

### Website

Open your browser and go to:

```
https://flima.42.fr
```

> **Note:** The project uses a self-signed TLS certificate. Your browser will show a security warning on the first visit. This is expected — click **"Advanced"** and then **"Proceed"** (or equivalent in your browser) to continue.

### WordPress Administration Panel

The admin panel is available at:

```
https://flima.42.fr/wp-admin
```

Log in with the WordPress admin credentials stored in `secrets/wp_admin_password.txt` (see [Section 4](#4-credentials--location-and-management)).

From the admin panel you can:
- Create, edit, and delete posts and pages
- Manage users and their roles
- Install themes and plugins
- Configure WordPress settings

---

## 4. Credentials — Location and Management

All sensitive credentials are stored as plain-text files inside the `secrets/` folder at the root of the repository. **This folder must never be committed to Git.**

### Credential files

| File | Used for |
|------|----------|
| `secrets/mysql_password.txt` | WordPress database user password |
| `secrets/mysql_root_password.txt` | MariaDB root password |
| `secrets/wp_user_password.txt` | WordPress regular user password |
| `secrets/wp_admin_password.txt` | WordPress administrator password |

### Viewing a credential

```bash
cat secrets/wp_admin_password.txt
```

### Changing a credential

1. Edit the corresponding file with the new password:
   ```bash
   echo "new_secure_password" > secrets/wp_admin_password.txt
   ```
2. Rebuild the stack for the change to take effect:
   ```bash
   make re
   ```

> ⚠️ Changing database passwords after the first run requires a full reset (`make fclean` + `make`), as MariaDB stores the hashed credentials in its data volume.

### WordPress user accounts

| Role | Username | Password location |
|------|----------|-------------------|
| Administrator | Defined in `.env` → `WP_ADMIN` | `secrets/wp_admin_password.txt` |
| Regular user | Defined in `.env` → `WP_USER` | `secrets/wp_user_password.txt` |

---

## 5. Checking That Services Are Running

### Quick status check

```bash
docker ps
```

You should see three containers listed with status `Up`:

```
CONTAINER ID   IMAGE               STATUS         NAMES
xxxxxxxxxxxx   inception-nginx     Up X minutes   nginx
xxxxxxxxxxxx   inception-wordpress Up X minutes   wordpress
xxxxxxxxxxxx   inception-mariadb   Up X minutes   mariadb
```

If any container is missing or shows `Exited`, check its logs (see below).

### Viewing service logs

```bash
# All services at once
docker compose -f srcs/docker-compose.yml logs

# A specific service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb

# Follow logs in real time
docker compose -f srcs/docker-compose.yml logs -f
```

### Verifying NGINX is serving HTTPS

```bash
curl -k https://flima.42.fr
```

A successful response will return HTML from the WordPress homepage. The `-k` flag bypasses the self-signed certificate check.

### Verifying MariaDB is accepting connections

```bash
docker exec -it mariadb mariadb -u root -p
```

Enter the root password from `secrets/mysql_root_password.txt` when prompted. If you reach the MariaDB shell, the database is running correctly.

```sql
SHOW DATABASES;
-- Should include: wordpress
EXIT;
```

### Common issues

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Browser shows "connection refused" | NGINX is not running | Check `docker ps` and `docker compose logs nginx` |
| WordPress shows database error | MariaDB not ready or wrong credentials | Check `docker compose logs mariadb` |
| Browser shows TLS warning | Self-signed certificate | Expected — click "Proceed" to continue |
| Container exits immediately | Misconfigured entrypoint or missing secret file | Check `docker compose logs <service>` for errors |

---

*For setup instructions and technical details, refer to the [README.md](./README.md).*