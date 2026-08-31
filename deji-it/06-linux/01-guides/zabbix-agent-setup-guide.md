# Connecting a Zabbix Agent to the Zabbix Server

A practical guide covering setup, configuration, and troubleshooting — based on real-world experience.

---

## Prerequisites

- Zabbix server installed and running (this guide assumes it's on a known IP, e.g. `[ZABBIX_SERVER_IP]`)
- [OS] machine to be monitored with `zabbix-agent` installed
- Network connectivity between the two machines

---

## Step 1 — Install the Zabbix Agent

```bash
sudo apt update
sudo apt install zabbix-agent
```

Enable and start the service:

```bash
sudo systemctl enable zabbix-agent
sudo systemctl start zabbix-agent
```

---

## Step 2 — Configure the Agent

Edit the main config file:

```bash
sudo nano /etc/zabbix/zabbix_agentd.conf
```

The three critical settings to get right:

```ini
# IP of your Zabbix server — controls which host is allowed to connect
Server=[ZABBIX_SERVER_IP]

# Same IP, used for active checks (agent reaches out to server)
ServerActive=[ZABBIX_SERVER_IP]

# Must match EXACTLY the hostname configured in the Zabbix dashboard
Hostname=[HOSTNAME]
```

> **Important:** `Hostname` is case-sensitive and must match character-for-character what is set under **Configuration > Hosts** in the Zabbix web UI.

---

## Step 3 — Restart the Agent

After any config change, always do a full stop/start rather than just restart to ensure old processes are fully cleared:

```bash
sudo systemctl stop zabbix-agent
sleep 2
sudo systemctl start zabbix-agent
sudo systemctl status zabbix-agent
```

---

## Step 4 — Add the Host in the Zabbix Dashboard

1. Go to **Configuration > Hosts > Create Host**
2. Set **Host name** — must match `Hostname=` in the agent config exactly
3. Under **Interfaces**, add an **Agent** interface:
   - IP: the agent machine's IP (e.g. `[AGENT_IP]`)
   - Port: `10050`
4. Assign a **Template** (e.g. `[TEMPLATE_NAME]`)
5. Click **Add**

After 60–90 seconds, go to **Monitoring > Hosts** and the ZBX icon should turn green.

---

## Verification Checklist

Run these on the agent machine to confirm everything is healthy before blaming the network:

```bash
# Is the agent running?
sudo systemctl status zabbix-agent

# Is it listening on port 10050?
sudo ss -tlnp | grep 10050

# What do the active config values look like?
grep -E "^Server|^ServerActive|^Hostname" /etc/zabbix/zabbix_agentd.conf

# Any errors in the log?
sudo tail -30 /var/log/zabbix/zabbix_agentd.log
```

Test connectivity **from the Zabbix server** to the agent:

```bash
nc -zv [AGENT_IP] 10050
```

---

## Common Pitfalls

### 1. `Server=` still set to `127.0.0.1`

**Symptom in log:**
```
failed to accept an incoming connection: connection from "[ZABBIX_SERVER_IP]" rejected, allowed hosts: "127.0.0.1"
```

The default config has `Server=127.0.0.1`. This tells the agent to only accept connections from localhost. If your Zabbix server is on a different machine, you must change this to the server's IP.

**Fix:** Set `Server=[ZABBIX_SERVER_IP]` and do a full stop/start.

---

### 2. `Hostname` mismatch

**Symptom:** Agent appears connected but no data comes in, or active checks fail silently.

The default config ships with `Hostname=Zabbix server` — this is the name of the Zabbix server itself, not your monitored host. The value must match the **Host name** field in the dashboard exactly.

**Fix:** Set `Hostname=[HOSTNAME]` in the config and restart the agent.

---

### 3. Config change didn't take effect after `systemctl restart`

**Symptom:** You edited the config, restarted, but the log still shows the old behaviour.

Old agent processes can linger. A simple `restart` sometimes isn't enough.

**Fix:**
```bash
sudo systemctl stop zabbix-agent && sleep 2 && sudo systemctl start zabbix-agent
```

---

### 4. Firewall blocking port 10050

**Symptom:** `nc -zv [AGENT_IP] 10050` times out or is refused from the Zabbix server.

**Fix:**
```bash
# Check UFW status
sudo ufw status

# Allow the port if UFW is active
sudo ufw allow 10050/tcp
sudo ufw reload
```

Also check any external firewall rules (cloud security groups, hypervisor firewalls, VLANs) if the two machines are on different subnets.

---

### 5. Wrong subnet / no route between server and agent

**Symptom:** `nc` from the Zabbix server fails, but works from another machine on a different subnet.

If your Zabbix server is on `[SUBNET_1]` and your agent is on `[SUBNET_2]`, make sure there is a route between the two subnets. This may require hypervisor-level network config, VLAN trunking, or static routes.

**Diagnosis:** Always run the `nc` test from the Zabbix server itself, not from a third machine.

---

### 6. Agent not enabled in the dashboard

**Symptom:** Everything looks right but the host shows as disabled (greyed out).

**Fix:** Go to **Configuration > Hosts**, find the host, and make sure the **Enabled** toggle is on.

---

## Quick Reference — Key Files and Ports

| Item | Value |
|---|---|
| Agent config file | `/etc/zabbix/zabbix_agentd.conf` |
| Agent log file | `/var/log/zabbix/zabbix_agentd.log` |
| Agent listen port | `10050` (server → agent, passive checks) |
| Server port | `10051` (agent → server, active checks) |
| Service name | `zabbix-agent` or `zabbix-agent2` |

---

## Useful Commands at a Glance

```bash
# Full restart (recommended after config changes)
sudo systemctl stop zabbix-agent && sleep 2 && sudo systemctl start zabbix-agent

# Watch live log output
sudo tail -f /var/log/zabbix/zabbix_agentd.log

# Test port from Zabbix server
nc -zv [AGENT_IP] 10050

# Verify running config values
grep -E "^Server|^ServerActive|^Hostname" /etc/zabbix/zabbix_agentd.conf
```