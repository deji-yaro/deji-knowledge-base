# deji-knowledge-base

Notes and guides from my homelab, documenting my learning journey as I go.

This started as personal Obsidian notes for running my own infrastructure, and turned into a habit of writing things down properly: what I built, what broke, and how I fixed it. Sharing it here as I move into DevOps, since a lot of what's in here reflects the kind of work I want to be doing professionally.

## Infrastructure overview

![Homelab infrastructure diagram](_canvas/deji-infra-current_log.png)

*Redacted high-level view of my current homelab setup.*

![Homelab network diagram](_canvas/deji-network-current_log.png)

*Network topology — routing, VLANs, and VPN endpoints (redacted).*

More diagrams (disk layout, physical wiring, camera setup) live in [`_canvas/`](_canvas/), exported as both `.canvas` (editable in Obsidian) and `.png` (quick preview).

## What's in here

- **Virtualization** - Proxmox cluster setup, GPU/USB passthrough, VM management
- **TrueNAS SCALE** - storage, backups, self-hosted apps (Nextcloud, Paperless-ngx)
- **Networking** - pfSense, WireGuard, DNS, VPN configs
- **Cloud** - Azure (VPN gateways, Entra/AD Connect, Exchange admin), AWS (EC2)
- **DevOps** - Docker Compose, Ansible playbooks, CI-adjacent tooling
- **Linux** - day-to-day admin, troubleshooting guides, cheat sheets
- **Security** -  OSINT tooling, recon workflows, hardening notes

## Why this exists

I manage this as an actual homelab, not a lab exercise, real hardware, real network, real mistakes. Writing documentation as I go has become part of how I work, and I'm using this repo to also learn Git properly: version control, commit hygiene, and managing a public vs. private copy of the same knowledge base (the private one lives on my self-hosted Forgejo instance, unredacted).

## Structure

Notes are organized by domain (`deji-it/00-virtualization`, `deji-it/01-network`, `deji-it/02-azure`, etc.), each with `guides/` and `troubleshoot/` subfolders — guides are step-by-step "how I did it," troubleshooting notes are "here's what went wrong and how I diagnosed it."

## A note on redaction

Some identifying details (IPs, hostnames, internal domains) have been stripped or replaced from this public copy. If something looks incomplete, that's likely why.
