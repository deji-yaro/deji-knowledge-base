# iperf3 — Network Performance Testing Guide

## What is it?

iperf3 is a tool for **actively measuring network bandwidth** between two machines. It works on a client/server model — one machine listens, the other connects and sends data, then reports how fast the data moved. It tells you the real-world throughput of your network, not just what your switch port is rated for.

---

## Why Use It?

Your switch might say 1Gbps but actual throughput could be 400Mbps due to:

- Bad cables
- Duplex mismatch
- Faulty NIC
- Network congestion
- Virtualization overhead
- Firewall inspection overhead

iperf3 reveals the truth.

---

## Installation

```bash
# Ubuntu/Debian
sudo apt install iperf3

# RHEL/Proxmox
apt install iperf3

# Windows
# Download from https://iperf.fr/iperf-download.php
```

---

## Basic Usage

**Server side** (the machine receiving):
```bash
iperf3 -s
```

**Client side** (the machine sending):
```bash
iperf3 -c <server-ip>
```

This runs a **10 second TCP test** and reports throughput.

---

## Reading the Output

```
[ ID] Interval      Transfer     Bitrate         Retr
[  5] 0.00-10.00s  1.08 GBytes  927 Mbits/sec    6    sender
[  5] 0.00-10.00s  1.08 GBytes  925 Mbits/sec         receiver
```

| Field | Meaning |
|---|---|
| **Transfer** | Total data moved |
| **Bitrate** | Average throughput |
| **Retr** | TCP retransmissions — packet loss indicator, should be 0 or very low |

---

## Useful Flags

### Change Test Duration
```bash
iperf3 -c 10.0.98.251 -t 30    # run for 30 seconds
```

### Test in Reverse
Tests server → client (download) instead of client → server (upload):
```bash
iperf3 -c 10.0.98.251 -R
```

### Parallel Streams
Simulates multiple connections, more realistic load:
```bash
iperf3 -c 10.0.98.251 -P 4    # 4 parallel streams
```

### UDP Test
Useful for testing latency and jitter instead of raw throughput:
```bash
iperf3 -c 10.0.98.251 -u -b 100M    # UDP at 100Mbps
```

### Set Bandwidth Limit
```bash
iperf3 -c 10.0.98.251 -b 500M    # cap at 500Mbps
```

### JSON Output
Useful for scripting and logging:
```bash
iperf3 -c 10.0.98.251 -J > results.json
```

### Bidirectional Test
Tests both directions simultaneously:
```bash
iperf3 -c 10.0.98.251 --bidir
```

### Run Server as Daemon
Run in background without occupying the terminal:
```bash
iperf3 -s -D
```

---

## Real World Scenarios

### Testing VM Network Performance
```bash
# Run server inside VM
iperf3 -s

# Run client on host
iperf3 -c <vm-ip>
```

### Verifying a 10Gbps Link is Actually 10Gbps
```bash
iperf3 -c 10.0.98.251 -P 8 -t 30
```

### Finding Packet Loss on a Link
```bash
iperf3 -c 10.0.98.251 -u -b 1G    # push 1Gbps UDP and watch loss %
```

### Testing Storage Network (iSCSI/NFS)
```bash
iperf3 -c storage-server -t 60 -P 4
```

### Testing Between Two Non-Server Machines
```bash
# Machine A (temporary server)
iperf3 -s

# Machine B (client)
iperf3 -c <machine-a-ip>
```

---

## Similar Tools

| Tool              | Best For                   | Key Difference                      |
| ----------------- | -------------------------- | ----------------------------------- |
| **iperf3**        | Raw bandwidth testing      | Industry standard, simple           |
| **nperf**         | All-in-one web based       | Browser based, no install needed    |
| **netperf**       | Latency + throughput       | More metrics than iperf3            |
| **ping**          | Basic latency              | RTT only, no bandwidth              |
| **mtr**           | Traceroute + ping combined | Shows per-hop latency and loss      |
| **speedtest-cli** | WAN/internet speed         | Tests against speedtest.net servers |
| **qperf**         | RDMA/InfiniBand            | Used in HPC/datacenter environments |
| **nuttcp**        | Similar to iperf           | Older, less common                  |
| **sockperf**      | Latency focused            | Microsecond precision               |

---

## mtr — Most Useful Companion Tool

mtr combines traceroute and ping into a live view of every hop between you and the destination, showing latency and packet loss per hop. Invaluable for finding exactly where a network problem is occurring.

```bash
sudo apt install mtr
mtr 10.0.98.251
```

---

## When to Use What

| Symptom                                  | Tool                                           |
| ---------------------------------------- | ---------------------------------------------- |
| Slow VM network                          | iperf3 between host and VM                     |
| Intermittent drops                       | mtr to find the failing hop                    |
| Internet slow                            | speedtest-cli                                  |
| High latency spikes                      | sockperf or `ping -i 0.1`                      |
| Storage network slow                     | iperf3 with multiple parallel streams (`-P 4`) |
| Need to test without installing anything | nperf in browser                               |

---

## Quick Reference Card

```bash
# Basic server
iperf3 -s

# Basic client test
iperf3 -c <ip>

# 30 second test with 4 streams
iperf3 -c <ip> -t 30 -P 4

# Reverse (download) test
iperf3 -c <ip> -R

# UDP test
iperf3 -c <ip> -u -b 100M

# Bidirectional
iperf3 -c <ip> --bidir

# Save results to JSON
iperf3 -c <ip> -J > results.json

# mtr live hop analysis
mtr <ip>
```
