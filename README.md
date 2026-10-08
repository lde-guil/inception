*This project has been created as part of the 42 curriculum by lde-guil.*

# Inception

## Description

Inception is a Docker infrastructure project from the 42 curriculum. Its goal
is to build a small, reproducible web stack from Docker images and Docker
Compose, while keeping each main service in its own container.

The stack contains:

- **Nginx**: the public entry point, serving HTTPS on port 443 and redirecting
	HTTP traffic from port 80. It forwards PHP requests to WordPress through
	PHP-FPM.
- **WordPress**: the PHP application server. The container waits for MariaDB,
	downloads WordPress with WP-CLI on first start, creates its configuration,
	and launches PHP-FPM on port 9000.
- **MariaDB**: the relational database server. Its initialization script creates
	the configured database and application user on the first start.

The services communicate through the private `inception` Docker bridge network.
WordPress files and MariaDB data are persisted outside the containers so that
recreating containers does not remove the application or database contents.

## Project Description

### Sources Included

- `srcs/docker-compose.yml` defines the services, networks, ports, environment
	file, dependencies, and persistent volumes.
- `srcs/requirements/nginx/` contains the Nginx image definition and HTTPS
	virtual-host configuration.
- `srcs/requirements/wordpress/` contains the PHP-FPM image definition and the
	WordPress installation/startup script.
- `srcs/requirements/mariadb/` contains the MariaDB image definition and the
	database initialization/startup script.
- `Makefile` provides the main build, cleanup, inspection, and rebuild commands.

### Main Design Choices

- Each service has a single clear responsibility and is built from an Alpine
	Linux base image.
- Nginx is the only public web entry point. MariaDB remains reachable only on
	the Docker network, while PHP-FPM is exposed to the host as required by the
	project configuration but is consumed by Nginx internally.
- Service names (`mariadb` and `wordpress`) are used for container-to-container
	communication instead of hard-coded container IP addresses.
- The containers use restart policies and an init process, and startup scripts
	make first-run initialization automatic.
- Nginx uses a self-signed certificate generated while building the image. A
	browser will therefore show a certificate warning until the certificate is
	trusted locally.

### Virtual Machines vs Docker

| Virtual Machines | Docker containers |
| --- | --- |
| Each VM includes a complete guest operating system and virtual hardware. | Containers share the host kernel and isolate processes using namespaces and cgroups. |
| They provide stronger OS-level isolation but use more disk space and memory. | They start quickly, are lightweight, and are well suited to packaging one service per container. |
| A separate VM is useful when different kernels or full machine isolation are required. | This project uses Docker because its services need consistent packaging and isolated, reproducible environments rather than separate full operating systems. |

### Secrets vs Environment Variables

Environment variables are convenient for configuring containers and are used by
this project through `srcs/.env`. They are appropriate for values such as the
domain name and database name, but passwords in an environment file can be
exposed through files, process inspection, or container metadata.

Docker secrets are designed for sensitive values: they are mounted as files and
can be granted only to the services that need them. A production deployment
should use a secrets manager or Docker secrets for database and WordPress
passwords. This 42 project uses environment variables because they are simple,
portable with Docker Compose, and match the project requirements; do not commit
the `.env` file or real credentials to Git.

### Docker Network vs Host Network

The project uses a user-defined Docker bridge network named `inception`.
Containers can resolve one another by service name while their internal traffic
is isolated from the host network. Only the ports explicitly published by
Compose are exposed to the host.

Host networking would remove much of that isolation and make containers share
the host network namespace. It can be useful for specialized low-latency
cases, but it would make port conflicts and service exposure harder to control.
The bridge network is the better fit for this multi-service web stack.

### Docker Volumes vs Bind Mounts

The Compose file declares `volume_mariadb` and `volume_wordpress` as Docker
volumes, but configures them with the local driver's `type: none` and `o: bind`.
In practice, they persist data in:

- `/home/lde-guil/data/mariadb`
- `/home/lde-guil/data/wordpress`

A Docker-managed named volume lets Docker choose and manage the storage
location, which improves portability and reduces host-specific configuration. A
bind mount maps an explicit host path into a container, making the data easy to
inspect, back up, and locate, but coupling the project to that host path and its
permissions. This project chooses bind-backed volumes to make persistence
visible and controllable while retaining Compose volume declarations.

## Instructions

### Prerequisites

- Linux with Docker Engine and the Docker Compose plugin installed.
- GNU Make.
- `sudo` access, because the Makefile creates and permissions the host data
	directories.
- A local hosts entry mapping the configured domain to the local machine, for
	example:

	```text
	127.0.0.1 lde-guil.42.fr
	```

### Configuration

Create `srcs/.env` before starting the project. It must define the following
names:

```dotenv
DOMAIN_NAME=lde-guil.42.fr
MYSQL_USER=wordpress
MYSQL_PASSWORD=change-me
MYSQL_DATABASE=wordpress
MYSQL_ROOT_PASSWORD=change-me-too
WORDPRESS_VERSION=latest
WORDPRESS_TITLE=Inception
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=change-this-password
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_USER=user
WORDPRESS_PASSWORD=change-this-password-too
WORDPRESS_EMAIL=user@example.com
```

Replace every example value, especially passwords, with local values. Keep
`srcs/.env` private and do not commit it.

### Build and Run

From the repository root:

```bash
make
```

This creates `/home/lde-guil/data`, builds the three images, creates the
containers and network, and starts the services in the background. Once the
containers are ready, open `https://lde-guil.42.fr` in a browser and accept the
self-signed certificate warning for local development.

Useful commands:

```bash
make ps        # Show running containers
make images    # List Docker images
make networks  # List Docker networks
make clean     # Stop containers and remove their Compose volumes
make fclean    # Clean containers, images, volumes, and host data
make re        # Perform fclean, then build and start again
```

The first WordPress startup may take a little while while MariaDB becomes
available and WP-CLI downloads and installs WordPress. If the project is
reinitialized with `make fclean`, all persisted database and WordPress data is
deleted.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker storage documentation](https://docs.docker.com/engine/storage/)
- [Docker networking documentation](https://docs.docker.com/engine/network/)
- [Docker security documentation](https://docs.docker.com/engine/security/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress developer documentation](https://developer.wordpress.org/)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
- [Alpine Linux documentation](https://docs.alpinelinux.org/)

### Use of AI

AI assistance was used to help structure and proofread this README, explain the
requested Docker architecture comparisons, and turn the existing Compose,
Dockerfile, shell-script, and Makefile behavior into concise documentation.
AI was used to write USER_DOC.md and DEV_DOC.md as well.
The project implementation itself was inspected against the repository files;
AI did not replace testing or verification of the commands and configuration.
