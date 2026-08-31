## Symptom Profile
- **Web vault works fine** — all data visible, editable, functional
- **Mobile app (Android) and browser extensions show empty vaults** — no logins, no OTP codes, no items
- **Server appears healthy** — no obvious crashes, web UI responsive

This is a **client-server sync/version mismatch** issue, not a data loss event.

---

## Root Cause Analysis

### Most Likely Causes (in order of probability)

1. **Vaultwarden server version is outdated** relative to client expectations
   - Bitwarden clients (official and compatible) enforce minimum server API versions
   - Older Vaultwarden builds may lack endpoints or response formats that newer clients expect
   - Clients silently fail to parse responses → empty vault display

2. **Database schema migration pending or partially applied**
   - If Vaultwarden was updated but container wasn't fully restarted, migrations may be incomplete
   - Web UI might tolerate this better than mobile/extension clients

3. **SSL/TLS certificate issues affecting specific clients**
   - Android and extensions are stricter about cert validation than desktop browsers
   - Self-signed or expired certs can cause silent sync failures
   - *Less likely here since web UI worked, but worth ruling out*

4. **Reverse proxy misconfiguration**
   - Missing headers (`X-Real-IP`, `X-Forwarded-Proto`) can break client auth flows
   - WebSocket support missing (needed for real-time sync)
   - *Unlikely if web UI worked fine, but possible*

5. **Client-side cache corruption**
   - Android app or extension cached stale/broken state
   - Clearing app data or reinstalling sometimes fixes it
   - *Usually a secondary fix, not the root cause*

---

## Diagnostic Steps

### 1. Check Vaultwarden Version
```bash
docker exec <vaultwarden_container> vaultwarden --version
# or
docker inspect <vaultwarden_container> | grep "Image"
```

Compare against [latest release](https://github.com/dani-garcia/vaultwarden/releases).

### 2. Review Container Logs
```bash
docker logs <vaultwarden_container> --tail 100
```

Look for:
- Schema migration warnings
- API errors on `/api/sync` endpoints
- TLS handshake failures
- Database connection issues

### 3. Test API Endpoint Directly
```bash
curl -k https://<your-vaultwarden-domain>/api/sync \
  -H "Authorization: Bearer <your_token>" \
  -v
```

Check response code and body. A `200` with empty data suggests a parsing issue; a `4xx/5xx` indicates server-side problems.

### 4. Verify SSL Certificate (if applicable)
```bash
openssl s_client -connect <your-domain>:443 -servername <your-domain>
```

Ensure cert is valid, not self-signed (unless explicitly trusted on all clients), and properly chained.

### 5. Check Reverse Proxy Config (if used)
Ensure these headers are passed:
```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Host $host;
```

WebSocket support:
```nginx
location /notifications/hub {
    proxy_pass http://<vaultwarden_ip>:3012;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

---

## Fix: Update Vaultwarden Container

### Step-by-Step

1. **Pull latest image**
```bash
docker pull vaultwarden/server:latest
# or pin to specific version (recommended for production)
docker pull vaultwarden/server:1.37.1
```

2. **Stop existing container**
```bash
docker stop <vaultwarden_container>
docker rm <vaultwarden_container>
```

3. **Redeploy with same volume mounts and env vars**
```bash
docker run -d \
  --name vaultwarden \
  -e WEBSOCKET_ENABLED=true \
  -e SIGNUPS_ALLOWED=false \
  -v /path/to/data:/data \
  -p 8080:80 \
  -p 3012:3012 \
  vaultwarden/server:1.37.1
```

Adjust env vars and ports to match your existing config.

4. **Verify container health**
```bash
docker logs <vaultwarden_container> --tail 50
```

Look for successful startup and any migration messages.

5. **Test sync from clients**
   - Force sync in Android app (pull down on vault list)
   - Reload browser extension
   - Verify items appear

---

## Post-Fix Validation

- [ ] All vault items visible on Android
- [ ] OTP codes generating correctly
- [ ] Browser extension syncing without errors
- [ ] Web vault still functional
- [ ] No errors in container logs after client sync attempts

---

## Prevention

1. **Pin Vaultwarden versions** in your compose/deploy scripts — don't rely on `:latest` in production
2. **Monitor GitHub releases** for Vaultwarden — subscribe to RSS or use a tool like Watchtower (with caution)
3. **Test updates in staging** before applying to production if you have multiple users
4. **Keep backups** of your Vaultwarden data directory before any update
   ```bash
   tar czf vaultwarden-backup-$(date +%F).tar.gz /path/to/vaultwarden/data
   ```

---

## Notes

- This issue is **not data loss** — your SQLite/PostgreSQL database is intact
- The web UI is more tolerant of version mismatches because it's served directly by Vaultwarden
- Mobile apps and extensions use the official Bitwarden API contracts, which are stricter
- Always check [Vaultwarden release notes](https://github.com/dani-garcia/vaultwarden/releases) before updating — breaking changes are rare but documented