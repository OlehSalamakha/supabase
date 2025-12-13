# Node Exporter Full Dashboard

**URL:** http://localhost:3010/d/bf3pxjj4iascgd/node-exporter-full

## Overview

This dashboard provides comprehensive system-level monitoring of your Linux host, showing CPU, memory, disk, network, and system metrics in detail. It's the most detailed view of your infrastructure health.

## Key Metrics

### 1. CPU Usage
**Panel:** CPU Busy / System / User / IOWait

**What it shows:** Breakdown of CPU time:
- **Busy**: Total CPU in use
- **System**: Kernel/OS operations
- **User**: Application code
- **IOWait**: Waiting for disk I/O

**Normal values:**
- Busy: 30-70% during normal load
- System: < 20%
- IOWait: < 10%
- Idle: > 20%

**When to worry:**
- IOWait > 30%: Disk bottleneck - consider SSD upgrade
- System > 30%: High kernel overhead (check for network/disk issues)
- Busy consistently > 90%: Need more CPU capacity
- All cores maxed: Immediate capacity issue

**Action:**
- High IOWait: Check disk performance in other panels
- High System: Review network stats, check for context switching
- High User: Identify CPU-intensive containers
- Consider CPU upgrade if sustained high usage

### 2. System Load
**Panel:** System Load (1m, 5m, 15m averages)

**What it shows:** Number of processes waiting for CPU or disk I/O.

**How to interpret:**
- Load < CPU cores: Good (e.g., < 4 on 4-core system)
- Load = CPU cores: Fully utilized
- Load > CPU cores: System overloaded

**Normal values:**
- For 4-core system: Load < 4 is good
- 1-min load: Can spike temporarily
- 5-min and 15-min: Should be stable

**When to worry:**
- 15-min load > CPU cores: Sustained overload
- Increasing trend: Performance degrading
- Very high load (3x cores): Critical overload

**Action:**
- Identify CPU-intensive processes
- Scale down workload or add resources
- Check for runaway processes

### 3. Memory Usage
**Panel:** Memory Stack / Percent

**What it shows:** RAM usage breakdown:
- **Apps**: Application memory
- **PageTables**: Kernel page tables
- **Slab**: Kernel object cache
- **Cached**: Disk cache (reclaimable)
- **Buffers**: I/O buffers (reclaimable)
- **Free**: Unused memory

**Normal values:**
- Used (apps): 50-80%
- Cached: 10-30% (good for performance)
- Free: > 10%
- Swap used: 0 (ideally)

**When to worry:**
- Free < 5% and cached < 5%: Real memory pressure
- Swap usage > 0: Memory exhausted (severe performance impact)
- Apps using > 90%: Imminent OOM kills

**Action:**
- Memory pressure: Add more RAM
- Check for memory leaks: `docker stats`
- Reduce container memory limits temporarily
- Review PostgreSQL `shared_buffers`

### 4. Memory Swap
**Panel:** Swap usage

**What it shows:** Virtual memory usage on disk.

**Normal values:**
- Swap used: 0 MB
- Swap in/out: 0 MB/s

**When to worry:**
- Any swap usage: Performance will be degraded
- Active swap I/O: System thrashing (very slow)
- Swap > 50% used: Severe memory shortage

**Action:**
- **CRITICAL**: Add RAM immediately
- Identify memory-hungry containers
- Restart containers with memory leaks
- Consider reducing workload until RAM added

### 5. Disk Usage
**Panel:** Disk Space / Inode Usage

**What it shows:**
- **Space**: GB used/available on each filesystem
- **Inodes**: Number of files/directories

**Normal values:**
- Disk space: < 80% used
- Inodes: < 80% used

**When to worry:**
- Space > 90%: Need to free space urgently
- Space > 95%: System may fail
- Inodes > 90%: Too many small files
- Root filesystem full: System instability

**Action:**
- Free space: `docker system prune -a --volumes`
- Find large files: `du -sh /* | sort -h`
- Check Docker: `docker system df -v`
- Archive or delete old data
- Expand filesystem if possible

### 6. Disk I/O
**Panel:** Disk IOps / Throughput / Utilization

**What it shows:**
- **IOps**: Read/write operations per second
- **Throughput**: MB/s read/write
- **Utilization**: % time disk is busy

**Normal values:**
- IOps: Depends on workload
- Throughput: < 80% of disk capacity
- Utilization: < 80%

**When to worry:**
- Utilization > 90%: Disk bottleneck
- Very high IOps with low throughput: Random I/O (slow)
- Sustained high utilization: Performance degraded

**Action:**
- Check which container is causing high I/O
- Review PostgreSQL for missing indexes
- Consider SSD/NVMe upgrade
- Add read cache (bcache, lvmcache)
- Optimize database queries

### 7. Network Traffic
**Panel:** Network Traffic / Errors / Sockets

**What it shows:**
- **Traffic**: Bytes in/out per interface
- **Errors**: Network errors and drops
- **Sockets**: TCP connections

**Normal values:**
- Traffic: Depends on usage
- Errors: 0
- Packet drops: 0
- TCP connections: < 1000

**When to worry:**
- High errors/drops: Network issues
- Traffic near interface limit: Network saturated
- Very high socket count: Connection leak
- Retransmits: Network reliability issues

**Action:**
- Errors: Check cables, switch ports, drivers
- High traffic: Review unexpected traffic sources
- Socket leak: Check application connections
- Consider network upgrade if saturated

### 8. Network Sockets
**Panel:** TCP sockets by state

**What it shows:** TCP connection states:
- **ESTABLISHED**: Active connections
- **TIME_WAIT**: Closing connections
- **CLOSE_WAIT**: Waiting to close
- **Others**: Various transitional states

**Normal values:**
- ESTABLISHED: Depends on app
- TIME_WAIT: < 1000 (clears in 60s)
- CLOSE_WAIT: < 100

**When to worry:**
- Many CLOSE_WAIT: Application not closing connections
- TIME_WAIT very high: High connection churn
- SYN_RECV high: Possible SYN flood attack

**Action:**
- High CLOSE_WAIT: Application connection leak
- Enable TCP connection reuse if appropriate
- Review firewall rules
- Check for connection pool issues

### 9. Filesystem Stats
**Panel:** File Descriptor Usage

**What it shows:** Open files across the system.

**Normal values:**
- Used: < 50% of max

**When to worry:**
- Used > 80%: Approaching file descriptor limit
- Steadily increasing: File descriptor leak
- At limit: System cannot open new files

**Action:**
- Increase limits: `/etc/security/limits.conf`
- Find process with most open files:
  ```bash
  lsof | awk '{print $1}' | sort | uniq -c | sort -n
  ```
- Check for file descriptor leaks in applications

### 10. System Context Switches
**Panel:** Context switches per second

**What it shows:** How often CPU switches between processes.

**Normal values:**
- < 100k/sec on typical systems
- Varies greatly by workload

**When to worry:**
- Very high (> 500k/sec): Scheduler overhead
- Increasing trend: More processes competing
- Correlates with high system CPU

**Action:**
- Review number of running containers
- Check for busy-loop processes
- Consider CPU pinning for critical containers
- May need more CPU cores

### 11. System Interrupts
**Panel:** Interrupts per second

**What it shows:** Hardware interrupt rate.

**Normal values:**
- Depends on I/O workload
- Network and disk I/O generate interrupts

**When to worry:**
- Very high with low I/O: Driver issue
- Sudden spike: Hardware problem
- Correlates with high system CPU

**Action:**
- Usually not actionable without deep system knowledge
- Check for hardware issues
- Review network card driver settings

### 12. System Uptime
**Panel:** Days since last boot

**What it shows:** How long system has been running.

**Normal behavior:**
- Should match expected uptime
- Resets after reboot

**When to worry:**
- Unexpected resets: System crashes
- Very short uptime repeatedly: Boot loop
- Very long uptime: Missing security updates

**Action:**
- Unexpected reboots: Check system logs
- Plan regular maintenance reboots (monthly)
- Apply security patches require reboots

## Using This Dashboard

### Daily Health Check
1. **CPU**: Check busy < 80%, IOWait < 10%
2. **Load**: Should be < number of CPU cores
3. **Memory**: Free > 10%, Swap = 0
4. **Disk**: Space < 80%, utilization < 80%
5. **Network**: No errors or drops

### Performance Investigation

#### System is Slow
1. Check **CPU Busy** - maxed out?
2. Check **IOWait** - disk bottleneck?
3. Check **Memory** - swapping?
4. Check **Disk Utilization** - disk busy?
5. Check **System Load** - overloaded?

#### Identify Bottleneck
- **CPU-bound**: High CPU busy, low IOWait
- **I/O-bound**: High IOWait, moderate CPU
- **Memory-bound**: High swap usage
- **Network-bound**: High network traffic, packet drops

### Capacity Planning
Track trends over weeks:
1. **CPU**: Plan upgrade when consistently > 70%
2. **Memory**: Add RAM when free < 20%
3. **Disk Space**: Expand when > 70%
4. **Disk I/O**: Consider SSD when utilization > 60%

## System Resource Comparison

| Resource | Good | Warning | Critical | Action |
|----------|------|---------|----------|--------|
| CPU Busy | < 70% | 70-85% | > 85% | Add CPU |
| IOWait | < 10% | 10-30% | > 30% | Upgrade disk |
| Memory Free | > 20% | 10-20% | < 10% | Add RAM |
| Swap Used | 0 MB | > 0 MB | Any active I/O | Add RAM urgently |
| Disk Space | < 70% | 70-85% | > 85% | Clean/expand |
| Disk Util | < 60% | 60-80% | > 80% | Optimize/upgrade |
| System Load | < cores | = cores | > cores | Scale resources |

## Common Issues & Solutions

### Issue: High IOWait
**Symptoms:** High IOWait %, slow system
**Cause:** Disk bottleneck
**Solution:**
- Check disk I/O panel for which disk
- Optimize database queries (missing indexes)
- Upgrade to SSD/NVMe
- Add disk cache layer
- Check `docker stats` for I/O-heavy container

### Issue: System Swapping
**Symptoms:** Swap usage > 0, system very slow
**Cause:** Memory exhaustion
**Solution:**
- **Immediate**: Restart high-memory containers
- **Short-term**: Reduce container memory limits
- **Long-term**: Add more RAM
- Check for memory leaks: `docker stats --no-stream`

### Issue: Disk Full
**Symptoms:** Disk space > 95%, services failing
**Cause:** Logs, Docker images, database growth
**Solution:**
```bash
# Check what's using space
df -h
du -sh /* | sort -h

# Clean Docker
docker system prune -a --volumes

# Clean old logs
journalctl --vacuum-time=7d
find /var/log -name "*.log" -mtime +30 -delete

# Clean Docker logs
find /var/lib/docker/containers -name "*.log" -mtime +7 -delete
```

### Issue: High CPU System Time
**Symptoms:** High system CPU %, high context switches
**Cause:** Kernel overhead (network, scheduling)
**Solution:**
- Check network errors panel
- Review running containers: `docker ps | wc -l`
- Check for busy-loop processes
- May need kernel tuning for high-container-count systems

### Issue: Network Packet Drops
**Symptoms:** Errors/drops in network panel
**Cause:** Network issues or saturation
**Solution:**
- Check physical connections
- Review switch/router logs
- Check interface errors: `ip -s link`
- Consider network upgrade
- Review firewall rules

## Alerting Recommendations

Key alerts to configure:

```yaml
# CPU
- High CPU: busy > 80% for 5 min (WARNING)
- Critical CPU: busy > 95% for 2 min (CRITICAL)

# Memory
- High Memory: free < 20% (WARNING)
- Critical Memory: free < 10% OR swap > 0 (CRITICAL)

# Disk
- Low Disk Space: > 80% (WARNING)
- Critical Disk: > 90% (CRITICAL)
- High Disk Util: > 80% for 5 min (WARNING)

# Load
- High Load: > CPU count for 5 min (WARNING)
- Critical Load: > 2x CPU count (CRITICAL)
```

## Useful Commands

```bash
# CPU info
lscpu
cat /proc/cpuinfo

# Memory info
free -h
cat /proc/meminfo

# Disk info
df -h
lsblk
iostat -x 1

# Network info
ip addr
ss -s
netstat -i

# System load
uptime
top
htop

# Process info
ps aux --sort=-%cpu | head -20  # Top CPU
ps aux --sort=-%mem | head -20  # Top memory

# Find large files
find / -type f -size +1G 2>/dev/null

# Disk I/O by process
iotop

# Network connections
ss -tupn
```

## Best Practices

1. **Establish baseline**: Know your normal metrics
2. **Monitor trends**: Weekly review to spot slow degradation
3. **Set alerts**: Don't rely on manual checking
4. **Plan capacity**: Upgrade before resources exhausted
5. **Regular maintenance**:
   - Monthly system updates
   - Quarterly capacity review
   - Clean old logs and data
6. **Document changes**: Note when metrics change and why
7. **Test limits**: Understand system behavior under load
8. **Keep history**: 15 days retention helps identify patterns

## Further Reading

- [Linux Performance Analysis](http://www.brendangregg.com/linuxperf.html)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter)
- [Linux System Monitoring](https://www.kernel.org/doc/html/latest/admin-guide/monitoring.html)
