#01-guides
## Purpose

Optimize the VM for best gaming and daily-use performance.

## CPU Pinning (Advanced)

```bash
# Pin VM cores to specific host cores# Edit VM config
nano /etc/pve/qemu-server/100.conf

# Add CPU affinity
args: -cpu host,hidden=1 -smp 4,cores=4,threads=1 -vcpu vcpunum=0,affinity=0 -vcpu vcpunum=1,affinity=1
```

## Memory Optimization

```bash
# Disable memory ballooning for consistent performance
balloon: 0

# Enable huge pages on host (optional)
echo 'vm.nr_hugepages=4096' >> /etc/sysctl.conf
sysctl -p
```

## Storage Optimization

```bash
# Use virtio-scsi with iothread
scsi0: local-lvm:vm-100-disk-0,iothread=1,size=64G,ssd=1

# Enable write-back caching (if using UPS)
cache=writeback
```

## Network Performance

```bash
# Use virtio network with multiqueue
net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr0,queues=4
```