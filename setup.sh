#!/bin/bash
# setup.sh - Initial homelab setup

set -e

echo "Homelab Docker Setup"
echo "======================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Please run as normal user (not root)"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and back in for group changes"
    echo "Then run this script again."
    exit 0
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
fi

# Create network
echo "Creating Docker network..."
docker network create traefik-network 2>/dev/null || echo "Network already exists"

# Create letsencrypt directory and acme.json
echo "Creating directories and SSL storage..."
mkdir -p letsencrypt
if [[ ! -f letsencrypt/acme.json ]]; then
    touch letsencrypt/acme.json
    chmod 600 letsencrypt/acme.json
    echo "Created acme.json with correct permissions"
fi

sudo mkdir -p /var/log/homelab

# Set permissions
echo "Setting permissions..."
if [[ -f update-ip.sh ]]; then
    chmod +x update-ip.sh
fi
sudo chown -R $USER:$USER letsencrypt
sudo chmod 755 /var/log/homelab

# Copy env file if not exists
if [[ ! -f .env ]]; then
    echo "Creating .env file from example..."
    if [[ -f .env.example ]]; then
        cp .env.example .env
    else
        touch .env
    fi
    echo ""
    echo "IMPORTANT: Edit .env with your actual credentials:"
    echo "nano .env"
    echo ""
    echo "Required changes:"
    echo "1. CLOUDFLARE_EMAIL=your-email@example.com"
    echo "2. CLOUDFLARE_API_KEY=your-dns-api-token"
    echo "3. CLOUDFLARE_ZONE_ID=your-zone-id"
    echo ""
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env with your Cloudflare credentials"
echo "2. Start services: docker compose up -d"
echo "3. Set up cron for IP updates: crontab -e"
echo "   Add: */5 * * * * $(pwd)/update-ip.sh"
echo ""
echo "To start: docker compose up -d"