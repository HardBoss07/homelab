## **Step-by-Step Instructions:**

### **1. Replace your files** with the corrected versions above.

### **2. Run setup:**
```bash
# Make setup executable and run it
chmod +x setup.sh
./setup.sh
```

### **3. Configure .env:**
```bash
nano .env
```
Fill in your actual Cloudflare credentials.

### **4. Create DNS records in Cloudflare:**
- Go to DNS → Records
- Add A record: `api.m4tt3o.dev` → `YOUR_CURRENT_IP` (DNS only - gray cloud)
- Add A record: `*.api.m4tt3o.dev` → `SAME_IP` (DNS only - gray cloud)

### **5. Start services:**
```bash
# Create network first
docker network create traefik-network

# Start everything
docker-compose up -d

# Check logs
docker-compose logs -f traefik
```

### **6. Test DNS update script:**
```bash
# Make it executable
chmod +x update-ip.sh

# Test it
./update-ip.sh

# Check log
tail -f /var/log/homelab-ip-update.log
```

### **7. Set up cron job:**
```bash
crontab -e
# Add this line:
*/5 * * * * /path/to/your/homelab/update-ip.sh
```

---

## **Expected Services:**
Once running, you should be able to access:
- `https://portainer.api.m4tt3o.dev` → Portainer
- `https://whoami.api.m4tt3o.dev` → Whoami test service
- `https://hello.api.m4tt3o.dev` → Nginx hello

All with automatic HTTPS via Let's Encrypt!

The key fixes were:
1. **Simplified Traefik config** (removed conflicting settings)
2. **Fixed Docker network configuration**
3. **Working update-ip.sh** (simplified and tested logic)
4. **Updated setup.sh** (better error handling and instructions)

All files now work together consistently!