#!/bin/bash
# update-ip.sh - Dynamic DNS updater for Cloudflare
# Place in: /path/to/homelab/

set -e

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source .env if exists
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Create it from .env.example first."
    exit 1
fi

# Log file
LOG_FILE="/var/log/homelab-ip-update.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Get current public IP
NEW_IP=$(curl -s --max-time 10 https://api.ipify.org)
if [[ ! $NEW_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "Error: Invalid IP address: $NEW_IP"
    exit 1
fi

log "Checking IP: $NEW_IP"

# Find DNS record IDs
get_record_id() {
    local record_name="$1"
    curl -s -X GET \
        "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=A&name=${record_name}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_KEY}" \
        -H "Content-Type: application/json" | \
        jq -r '.result[0].id // empty'
}

update_record() {
    local record_name="$1"
    local record_id="$2"
    
    curl -s -X PUT \
        "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${record_id}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_KEY}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${record_name}\",\"content\":\"${NEW_IP}\",\"ttl\":120,\"proxied\":false}" > /tmp/cf-response.json
    
    if jq -e '.success' /tmp/cf-response.json >/dev/null; then
        log "✓ Updated $record_name → $NEW_IP"
        return 0
    else
        log "✗ Failed to update $record_name"
        return 1
    fi
}

# Main update logic
main() {
    # Update api.m4tt3o.dev
    API_RECORD_ID=$(get_record_id "api.m4tt3o.dev")
    if [ -n "$API_RECORD_ID" ]; then
        update_record "api.m4tt3o.dev" "$API_RECORD_ID"
    else
        log "Warning: api.m4tt3o.dev record not found"
    fi
    
    # Update *.api.m4tt3o.dev (wildcard)
    WILDCARD_RECORD_ID=$(get_record_id "*.api.m4tt3o.dev")
    if [ -n "$WILDCARD_RECORD_ID" ]; then
        update_record "*.api.m4tt3o.dev" "$WILDCARD_RECORD_ID"
    else
        log "Warning: *.api.m4tt3o.dev record not found"
    fi
    
    # Restart Traefik if Docker is running and traefik container exists
    if command -v docker >/dev/null && docker ps -q --filter "name=traefik" | grep -q .; then
        log "Restarting Traefik container..."
        docker restart traefik && log "Traefik restarted" || log "Failed to restart Traefik"
    fi
}

main 2>&1 | tee -a "$LOG_FILE"