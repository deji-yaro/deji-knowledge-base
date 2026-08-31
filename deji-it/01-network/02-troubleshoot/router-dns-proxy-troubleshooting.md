# Router DNS Proxy Troubleshooting — Technicolor CGA4236TCH1
**Author:** deji | **Date:** 2026-05-07  
**Stack:** Technitium DNS → Nginx Proxy Manager → Technicolor CGA4236TCH1

---

## Overview

The goal was to access a home router's web UI via a friendly DNS name (`[DOMAIN]) instead of its raw IP address (`192.168.0.1`), with a valid SSL certificate served by Nginx Proxy Manager (NPM).

After setting up the DNS A record and confirming TCP connectivity on ports 80 and 443, every attempt to access the router via DNS name returned **HTTP 403 Forbidden** — even though accessing via IP worked perfectly.

---

## The Problem: HTTP Host Header Filtering

### What is the HTTP Host Header?

When your browser or any HTTP client makes a request to a web server, it sends a set of **headers** — small pieces of metadata that accompany the request. One of the most important is the `Host` header.

The `Host` header tells the web server **which domain name the client used to reach it**. This matters because a single server (or IP address) can host many different websites simultaneously. The `Host` header is how the server knows which one to serve.

**Example — what a browser sends when you type `https://[DOMAIN]/`:**

```
GET / HTTP/1.1
Host: [DOMAIN]
User-Agent: Mozilla/5.0 ...
Accept: */*
```

**Example — what it sends when you type `https://192.168.0.1/`:**

```
GET / HTTP/1.1
Host: 192.168.0.1
User-Agent: Mozilla/5.0 ...
Accept: */*
```

Notice that only the `Host` value differs — the destination IP is identical in both cases.

### Why the Router Cares

The Technicolor CGA4236TCH1 (and most ISP-grade routers) implements **Host header whitelisting** as a security measure against **Cross-Site Request Forgery (CSRF)** attacks.

CSRF is an attack where a malicious website tricks your browser into making requests to your router on your behalf. By whitelisting only the expected `Host` value (its own IP address `192.168.0.1`), the router rejects any request that arrives with an unexpected hostname — including your friendly DNS name.

This means:

| Request                                | Host Header Seen by Router | Result          |
| -------------------------------------- | -------------------------- | --------------- |
| `https://192.168.0.1/`                 | `192.168.0.1`              | ✅ Allowed       |
| `https://[DOMAIN]/` (no proxy)         | `[DOMAIN]`                 | ❌ 403 Forbidden |
| `https://[DOMAIN]/` (via proxy, fixed) | `192.168.0.1`              | ✅ Allowed       |

### How to Deal With Host Header Filtering

The solution is to place a **reverse proxy** between the client and the router. The proxy receives the request with the DNS name, **rewrites the `Host` header** to the value the router expects (`192.168.0.1`), and forwards it. The router never sees the original DNS name.

```
Browser ──► Nginx Proxy Manager ──► Router
           (rewrites Host header)
Host: [DOMAIN]   →   Host: 192.168.0.1
```

The key Nginx directive that accomplishes this is:

```nginx
proxy_set_header Host 192.168.0.1;
```

---

## Diagnosis Steps

### Step 1 — Confirm TCP Connectivity

```bash
nc -zv 192.168.0.1 80
nc -zv 192.168.0.1 443
```

Both returned success. This ruled out firewall or port issues — the problem was at the HTTP layer, not TCP.

### Step 2 — Confirm Host Header is the Cause

By overriding the `Host` header manually with `curl`, we confirmed that the router accepted the request:

```bash
curl -v -H "Host: 192.168.0.1" http://[DOMAIN]/
```

Response:
```
< HTTP/1.1 301 Moved Permanently
< Location: https://192.168.0.1/
```

A `301` redirect instead of `403` proved conclusively that the router only rejected requests with the wrong `Host` header.

### Step 3 — Identify Where the 403 Was Coming From

After setting up NPM with custom directives, the 403 persisted. Running a full verbose `curl` revealed:

```
< HTTP/2 403
< server: openresty
```

The `server: openresty` header exposed that the 403 was being returned by **NPM itself** (which is built on OpenResty/Nginx) — not the router. NPM was rejecting the request before it ever reached the router.

This pointed to two issues with how NPM was handling the custom configuration.

---

## Root Causes

### Cause 1 — Custom Directives Outside the `location` Block

NPM's Advanced tab accepts custom Nginx configuration, but when directives are entered as bare lines (without wrapping them in a `location {}` block), NPM places them in a part of the config where they do not override the proxy behaviour. NPM was still auto-generating its own `proxy_set_header Host` line, which took precedence and sent `rtr.dejiyaro.com` to the router.

**Evidence:** The curl output showed:
```
* [HTTP/2] [1] [:authority: [DOMAIN]]
> Host: rtr.dejiyaro.com
```
The custom `Host` override was not being applied.

### Cause 2 — HTTP/2 Enabled Upstream

NPM had HTTP/2 support enabled for this proxy host. Nginx was attempting to communicate with the router over HTTP/2, but the router's embedded web server only supports HTTP/1.1. This caused the upstream connection to fail.

---

## The Fix

In the NPM proxy host **Advanced tab**, replace bare directives with an explicit `location /` block:

```nginx
location / {
    proxy_pass https://192.168.0.1;
    proxy_set_header Host 192.168.0.1;
    proxy_ssl_verify off;
    proxy_ssl_server_name off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection upgrade;
}
```

### What Each Directive Does

| Directive | Purpose |
|---|---|
| `proxy_pass https://192.168.0.1` | Forward traffic to the router over HTTPS |
| `proxy_set_header Host 192.168.0.1` | Override the Host header — the core fix |
| `proxy_ssl_verify off` | Skip verification of the router's self-signed certificate |
| `proxy_ssl_server_name off` | Suppress sending the DNS name as the TLS SNI field upstream |
| `proxy_http_version 1.1` | Force HTTP/1.1 upstream (router doesn't support HTTP/2) |
| `proxy_set_header Upgrade / Connection` | Required for HTTP/1.1 keep-alive and WebSocket compatibility |

### NPM UI Settings for This Proxy Host

| Setting | Value |
|---|---|
| Scheme | `https` |
| Forward Hostname / IP | `192.168.0.1` |
| Forward Port | `443` |
| Force SSL | ✅ On |
| HTTP/2 Support | ❌ Off |
| HSTS Enabled | ❌ Off (during troubleshooting) |
| Cache Assets | ❌ Off |
| Access List | Publicly Accessible |

---

## End Result

```
Client (browser)
    │
    │  HTTPS — [DOMAIN]
    │  Let's Encrypt wildcard cert (*.dejiyaro.com)
    ▼
Nginx Proxy Manager (10.0.95.253:443)
    │
    │  HTTPS — 192.168.0.1:443
    │  Host: 192.168.0.1  ← rewritten
    │  SSL verify: off
    ▼
Technicolor CGA4236TCH1 Router (192.168.0.1)
    │
    ✅ 200 OK — Web UI served
```

The router now serves its web UI via `https://rtr.dejiyaro.com` with a valid Let's Encrypt certificate, while the router itself never sees the DNS name.

---

## Key Takeaways

1. **`nc` tests TCP only** — a successful port check does not mean the HTTP layer will work. Always follow up with `curl -v` to inspect actual HTTP headers and responses.
2. **`server:` response header reveals who is rejecting you** — `openresty` means NPM, `WebServer` means the Technicolor router.
3. **In NPM's Advanced tab, always wrap directives in an explicit `location /` block** — bare directives may land outside the proxy context and have no effect.
4. **HTTP/2 must be disabled when proxying to embedded device web servers** — they almost universally only support HTTP/1.1.
5. **Host header filtering is a feature, not a bug** — it protects against CSRF attacks. The correct solution is a proxy that rewrites the header, not disabling the protection.
