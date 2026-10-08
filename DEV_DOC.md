# Inception Developer Documentation

## Architecture and Source Layout

The project is a Docker Compose application with one container per main
service:

- `srcs/requirements/nginx/` builds the Nginx HTTPS reverse proxy.
- `srcs/requirements/wordpress/` builds PHP-FPM and installs WordPress with
	WP-CLI on first startup.
- `srcs/requirements/mariadb/` builds MariaDB and initializes its database on
	first startup.
- `srcs/docker-compose.yml` connects the services, publishes ports, loads
	configuration, and declares persistent storage.
- `Makefile` wraps the most common Docker and host-data operations.

The services use the Alpine Linux base image. Nginx communicates with PHP-FPM
at `wordpress:9000`, and WordPress communicates with MariaDB at the service
hostname `mariadb`. All services join the user-defined bridge network
`inception`.

## Prerequisites

Install the following on the host:

- Linux
- Docker Engine
- Docker Compose plugin (`docker compose`)
- GNU Make
- `sudo`, for creating and permissioning the host data directories

Check the installation before building:

```bash
docker --version
docker compose version
make --version
```

## Configuration and Secrets

Create `srcs/.env` before launching Compose. The Compose file loads this file
into all three services. Define these variables:

```dotenv
DOMAIN_NAME=lde-guil.42.fr
MYSQL_USER=wordpress
MYSQL_PASSWORD=replace-me
MYSQL_DATABASE=wordpress
MYSQL_ROOT_PASSWORD=replace-me-too
WORDPRESS_VERSION=latest
WORDPRESS_TITLE=Inception
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=replace-me
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_USER=user
WORDPRESS_PASSWORD=replace-me
WORDPRESS_EMAIL=user@example.com
```

Use unique local values for every password. Keep `srcs/.env` outside version
control and restrict its permissions, for example:

```bash
chmod 600 srcs/.env
```

The current implementation reads credentials from environment variables. A
production deployment should replace this approach with Docker secrets or a
dedicated secrets manager. The `WORDPRESS_VERSION` variable is part of the
configuration contract, although the current startup script downloads the
latest WP-CLI-selected WordPress package rather than interpolating that value.

Add the configured domain to the host's `/etc/hosts` during local development:

```text
127.0.0.1 lde-guil.42.fr
```

The Nginx image generates a self-signed certificate for the configured project
domain during the image build. This is suitable for local testing, not for a
public production endpoint.

## Build and Launch

From the repository root, the standard build is:

```bash
make
```

The `all` target performs these actions:

1. Creates `/home/lde-guil/data`, `/home/lde-guil/data/wordpress`, and
	 `/home/lde-guil/data/mariadb` with `sudo`.
2. Builds the MariaDB, WordPress, and Nginx images.
3. Creates the `inception` network and starts the services in detached mode.

The equivalent Compose command is:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

Startup order is controlled with `depends_on`, and the WordPress startup script
also waits until MariaDB accepts the configured credentials before installing
WordPress. The application is then available at
`https://<DOMAIN_NAME>/` and the administration panel at
`https://<DOMAIN_NAME>/wp-admin`.

## Container and Image Management

Useful Makefile targets:

```bash
make ps        # List running containers
make images    # List local Docker images
make networks  # List Docker networks
make clean     # Stop the Compose project and remove Compose volumes
make fclean    # Clean containers, images, Docker resources, and host data
make re        # Run fclean, then build and launch again
```

Useful direct Compose commands:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml restart nginx
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml down -v
```

Use `down` for a normal stop. `down -v` also removes the Compose volume
objects, but the current volumes are bind-backed, so their host directories are
not removed by that command. `make fclean` explicitly deletes the host data
directories and should only be used after making any required backups.

## Ports and Connectivity

The Compose configuration publishes:

- `80:80`: HTTP, redirected by Nginx to HTTPS.
- `443:443`: HTTPS website and WordPress administration panel.
- `9000:9000`: PHP-FPM, published by the current configuration but normally
	called by Nginx through the Docker network.

MariaDB exposes port 3306 only to the Docker network using Compose `expose`; it
is not published on the host. Service discovery should use `mariadb` and
`wordpress`, not container IP addresses.

## Data and Persistence

The two Compose volumes are configured as local-driver bind mounts:

| Compose volume | Container path | Host path | Contents |
| --- | --- | --- | --- |
| `volume_mariadb` | `/var/lib/mysql` | `/home/lde-guil/data/mariadb` | MariaDB database files |
| `volume_wordpress` | `/srv/www/wordpress` | `/home/lde-guil/data/wordpress` | WordPress core, uploads, configuration, and plugins |

The data remains when containers are recreated or when `make clean` is run. The
MariaDB script initializes the database only when `/var/lib/mysql/mysql` does
not exist. The WordPress script installs WordPress only when `wp-config.php`
does not exist. This makes normal restarts and rebuilds non-destructive.

Back up the host directories before maintenance:

```bash
sudo tar -czf inception-data-backup.tar.gz /home/lde-guil/data
```

To reset the application completely, verify the backup and then run:

```bash
make fclean
```

This removes both persistent data directories as well as Docker resources.

## Troubleshooting

- If WordPress keeps waiting for MariaDB, inspect the MariaDB log and verify
	`MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_DATABASE` in `srcs/.env`.
- If the browser cannot resolve the website, check `/etc/hosts` and the value of
	`DOMAIN_NAME`.
- If port binding fails, check whether another process is using ports 80, 443,
	or 9000.
- If a changed credential is ignored, remember that credentials are persisted
	in the initialized database and WordPress configuration. Change them through
	the application or perform a documented, backed-up reset.
- Inspect the generated Nginx configuration and service state with `docker
	compose -f srcs/docker-compose.yml logs nginx` and `docker compose -f
	srcs/docker-compose.yml ps`.
