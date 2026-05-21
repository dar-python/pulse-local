# FoodPulse EC2 GHCR Deployment

This deployment path moves EC2 to pull-only runtime images from GitHub Container Registry. EC2 must not build Docker images locally.

DuckDNS and Certbot should be configured after this GHCR pull-only deployment is working from `127.0.0.1:8080`.

## GitHub Configuration

Add these repository secrets:

- `EC2_HOST`: EC2 public IP or DNS name.
- `EC2_USER`: SSH user, for example `ubuntu`.
- `EC2_SSH_PRIVATE_KEY`: private key for the EC2 SSH user.
- `GHCR_USERNAME`: GitHub user or machine user that can pull the GHCR images.
- `GHCR_PAT`: GitHub personal access token with package read access for GHCR pulls.

Add this repository variable:

- `APP_DIR`: EC2 app directory, for example `/home/ubuntu/food-pulse`.

The workflow uses `GITHUB_TOKEN` to push images to GHCR and uses `GHCR_USERNAME` plus `GHCR_PAT` only on EC2 for `docker login ghcr.io`.

The deploy workflow must keep these permissions so `GITHUB_TOKEN` can read the repository and push GHCR packages:

```yaml
permissions:
  contents: read
  packages: write
```

## Required EC2 Files

The deploy workflow copies only `docker-compose.prod.yml`. It does not overwrite production env files.

Create or preserve these files on EC2:

- `/home/ubuntu/food-pulse/laravel-backend-api/.env`
- `/home/ubuntu/food-pulse/.env.mysql`

Warning for existing database volumes: the EC2 server already has the Docker volume `food-pulse_mysql_data`. For an existing MySQL Docker volume, do not randomly change `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, or `MYSQL_ROOT_PASSWORD`. MySQL initialization variables are mainly applied only when the database directory is first created. The Laravel `DB_*` values must match the actual credentials inside the existing initialized database. If `.env.mysql` is created from `.env.mysql.example`, use the same credentials as the existing volume or Laravel may fail database login after deployment.

Use `.env.mysql.example` as the template for `.env.mysql` and replace the passwords:

```bash
cd /home/ubuntu/food-pulse
cp .env.mysql.example .env.mysql
nano .env.mysql
```

The Laravel database values in `laravel-backend-api/.env` must match `.env.mysql`:

```dotenv
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=pulselocal
DB_USERNAME=pulselocal
DB_PASSWORD=<same value as MYSQL_PASSWORD>
ML_SERVICE_URL=http://ml-service:8001
```

Do not commit `.env`, `.env.mysql`, `.pem`, tokens, or secrets.

## Stop the Old Local-Build Stack Safely

From the EC2 app directory, stop the old Compose stack without deleting database volumes:

```bash
cd /home/ubuntu/food-pulse
docker compose down
```

Do not run `docker compose down -v`. Do not run `migrate:fresh`.

## Manual Pull-Only Deploy

Run these commands from `/home/ubuntu/food-pulse`:

```bash
docker login ghcr.io
IMAGE_TAG=latest docker compose -f docker-compose.prod.yml pull
IMAGE_TAG=latest docker compose -f docker-compose.prod.yml up -d --remove-orphans
IMAGE_TAG=latest docker compose -f docker-compose.prod.yml exec -T laravel-api php artisan migrate --force
IMAGE_TAG=latest docker compose -f docker-compose.prod.yml exec -T laravel-api php artisan config:cache
IMAGE_TAG=latest docker compose -f docker-compose.prod.yml exec -T laravel-api php artisan route:cache
docker image prune -f
```

Do not run `docker compose build` on EC2.

## Verify

```bash
docker compose -f docker-compose.prod.yml ps
curl http://127.0.0.1:8080/api/health
docker compose -f docker-compose.prod.yml exec -T ml-service python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8001/health', timeout=2).read().decode())"
```

The production Compose file binds Laravel nginx to `127.0.0.1:8080:80`. The ML service and MySQL service are reachable only inside the Docker network and do not publish host ports.

After these checks pass, configure host-level Nginx, DuckDNS, and Certbot so public HTTP/HTTPS terminates on the host reverse proxy and forwards to `http://127.0.0.1:8080`.
