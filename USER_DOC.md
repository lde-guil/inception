# Inception User Documentation

## What the Stack Provides

This project runs a WordPress website using three Docker services:

- **Nginx** receives web requests. HTTP on port 80 is redirected to HTTPS on
	port 443.
- **WordPress** runs the website through PHP-FPM.
- **MariaDB** stores the WordPress content, users, settings, and other data.

The services communicate on the private Docker network named `inception`.
MariaDB is not intended to be accessed directly from the host. The WordPress
files and database are stored persistently on the host, so a normal container
restart does not erase the website.

## Start the Project

Before the first start, an administrator must:

1. Install Docker Engine, the Docker Compose plugin, GNU Make, and `sudo`.
2. Create and configure `srcs/.env` as described in the developer
	 documentation. Never use real credentials in a file that is committed to
	 Git.
3. Add the domain from `DOMAIN_NAME` to the local hosts file. For the default
	 configuration, add this line:

	 ```text
	 127.0.0.1 lde-guil.42.fr
	 ```

From the repository root, run:

```bash
make
```

The command creates the data directories, builds the images, and starts the
containers in the background. The first launch can take a few minutes while
MariaDB becomes ready and WordPress is downloaded and installed.

## Stop the Project

To stop and remove the containers and their Compose volume declarations while
keeping the host data, run:

```bash
make clean
```

The same operation can be performed directly with Compose:

```bash
docker compose -f srcs/docker-compose.yml down -v
```

To remove the containers, images, Docker resources, and all stored project data
under `/home/lde-guil/data`, run:

```bash
make fclean
```

`make fclean` is destructive. It deletes the WordPress site and MariaDB data;
use it only when a complete reset is intended.

## Access the Website

Open the configured domain over HTTPS:

```text
https://lde-guil.42.fr
```

Replace the domain with the value of `DOMAIN_NAME` if it differs. Nginx uses a
self-signed certificate generated for local development, so the browser will
display a certificate warning the first time. The HTTP address redirects to
HTTPS:

```text
http://lde-guil.42.fr
```

## Access the Administration Panel

Open the WordPress administration panel at:

```text
https://lde-guil.42.fr/wp-admin
```

Sign in with `WORDPRESS_ADMIN_USER` and `WORDPRESS_ADMIN_PASSWORD` from
`srcs/.env`. The regular WordPress user credentials are configured with
`WORDPRESS_USER` and `WORDPRESS_PASSWORD`.

## Locate and Manage Credentials

The configuration file is:

```text
srcs/.env
```

The important credential variables are:

- `MYSQL_USER` and `MYSQL_PASSWORD`: the WordPress database account.
- `MYSQL_ROOT_PASSWORD`: the MariaDB root account.
- `WORDPRESS_ADMIN_USER` and `WORDPRESS_ADMIN_PASSWORD`: the administrator
	account for `/wp-admin`.
- `WORDPRESS_USER` and `WORDPRESS_PASSWORD`: the additional WordPress user.

To change credentials, stop the project, edit `srcs/.env`, and start it again.
Credentials used during the initial WordPress and MariaDB installation are
written into the persistent data. Changing `.env` after initialization does
not automatically change existing database or WordPress passwords. For a clean
reinitialization, back up anything important and run `make fclean`, then
configure the new values and run `make`.

Protect `srcs/.env` with appropriate file permissions and do not share or
commit it. In a production deployment, use a secrets manager instead of a
plain environment file.

## Check Service Health

List the running containers:

```bash
make ps
```

All three containers should be present: `mariadb`, `wordpress`, and `nginx`.
For more detail, use Compose:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Read service logs when a container is starting or the website is unavailable:

```bash
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

The expected startup messages include MariaDB starting, WordPress reporting
that MariaDB is ready, PHP-FPM starting, and Nginx remaining active. A simple
HTTP check confirms that Nginx is responding and redirecting to HTTPS:

```bash
curl -I http://lde-guil.42.fr
```

The response should contain a `301` redirect to an HTTPS URL. If the website
does not load, first check the hosts-file entry, container status, service logs,
and that ports 80, 443, and 9000 are not already in use.
