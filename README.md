# HomeLab Docker Setup

Self-hosted services with automatic SSL, dynamic DNS, and reverse proxy.

## Architecture
```
┌─────────────────────────────────────────────┐
│                 Cloudflare DNS              │
│  *.api.m4tt3o.dev → Dynamic IP → Your Home  │
└─────────────────────────────────────────────┘
                               │
┌────────────────────────────────────────────────┐
│                    Home Server                 │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐     │
│  │ Service1 │  │ Service2 │  │ Portainer │     │
│  └──────────┘  └──────────┘  └───────────┘     │
│          │           │            │            │
│  ┌──────────────────────────────────────────┐  │
│  │              Traefik Proxy               │  │
│  │  Auto SSL • Auto Discovery • Routing     │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Clone and setup
git clone https://github.com/HardBoss07/homelab.git
cd homelab

# Run setup script
chmod +x setup.sh
./setup.sh

# Configure environment (after setup script creates .env)
nano .env  # Add your Cloudflare credentials

# Create Docker network and start services
docker network create traefik-network
docker-compose up -d

# Check logs
docker-compose logs -f traefik

# Set up dynamic IP updates
chmod +x update-ip.sh
crontab -e
# Add: */5 * * * * /path/to/homelab/update-ip.sh
```

## Services Overview

| Service           | URL                        | Purpose                     |
| ----------------- | -------------------------- | --------------------------- |
| Traefik Dashboard | `traefik.api.m4tt3o.dev`   | Reverse proxy management    |
| Portainer         | `portainer.api.m4tt3o.dev` | Docker container management |
| Whoami            | `whoami.api.m4tt3o.dev`    | Example service 1           |
| Hello             | `hello.api.m4tt3o.dev`     | Example service 2           |

## Adding New Services

1. Add service to `docker-compose.yml`:
```yaml
new-service:
  image: your-image:tag
  environment:
    SERVICE_NAME: new-service
    DOMAIN: ${DOMAIN}
  labels:
    <<: *traefik-default
  # Add custom volumes, ports, etc.
```

2. Restart:
```bash
docker-compose up -d new-service
```

## DNS Configuration

Create in Cloudflare:
- `A` record: `api.m4tt3o.dev` → `YOUR_IP` (DNS only - gray cloud)
- `A` record: `*.api.m4tt3o.dev` → `YOUR_IP` (DNS only - gray cloud)

## Troubleshooting

```bash
# Check if services are running
docker-compose ps

# View Traefik logs
docker-compose logs traefik

# Test DNS resolution
dig api.m4tt3o.dev

# Check service health
docker-compose exec traefik traefik healthcheck
```

## Maintenance

Update all containers:
```bash
docker-compose pull
docker-compose up -d
```

Backup configuration:
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz docker-compose.yml traefik.yml letsencrypt/
```

## Security Notes
- Change default passwords in .env file
- Enable Cloudflare Access for admin panels (recommended)
- Regular updates: `docker-compose pull && docker-compose up -d`
- Monitor logs with `docker-compose logs -f`
- Use firewall: `sudo ufw allow 80,443,22/tcp`