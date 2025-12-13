# Docker Container & Host Metrics Dashboard

**URL:** http://localhost:3010/d/cf3pxjinsh91ca/docker-container-and-host-metrics

## Overview

This dashboard monitors Docker containers and the host system, showing resource usage (CPU, memory, network, disk) for each container and the overall host.

## Key Metrics

### 1. Container CPU Usage
**Panel:** CPU usage per container

**What it shows:** CPU consumption by each container as percentage of total CPU.

**Normal values:**
- **Workers**: 5-20% during processing, near 0% idle
- **PostgreSQL**: 5-30% depending on load
- **Prometheus/Grafana**: < 5%
- **MinIO**: < 5% normally, spikes during uploads

**When to worry:**
- Any container consistently > 80%: May be CPU-bound
- All containers high: Host CPU exhausted
- Worker at 100%: Processing bottleneck

**Action:**
- High worker CPU: Normal during processing, but check for infinite loops
- High PostgreSQL CPU: Review slow queries
- Check host CPU with Node Exporter dashboard

### 2. Container Memory Usage
**Panel:** Memory usage per container with limits

**What it shows:** RAM used by each container, shows limit line if set.

**Normal values:**
- **PostgreSQL**: 500MB - 2GB (grows with shared_buffers)
- **Workers**: 200-500MB each
- **Prometheus**: 200-500MB (depends on retention)
- **MinIO**: 100-300MB
- **Grafana**: 100-200MB

**When to worry:**
- Memory near limit: Container may be killed (OOM)
- Steadily increasing: Possible memory leak
- Sudden spike: Large operation or leak

**Action:**
- Near limit: Increase container memory limit
- Memory leak suspected: Restart container and monitor
- PostgreSQL high: Check for large queries or increase `shared_buffers`

### 3. Container Network I/O
**Panel:** Network traffic in/out per container

**What it shows:** Bytes sent/received by each container.

**Normal behavior:**
- **Workers**: Spikes during audio downloads (transcription)
- **PostgreSQL**: Steady traffic matching app usage
- **MinIO**: Spikes during audio uploads/downloads
- **Prometheus**: Periodic scraping (15s intervals)

**When to worry:**
- Unexpectedly high traffic: Possible attack or misconfiguration
- Zero traffic on active container: Network issue
- Sustained high traffic: May saturate network

**Action:**
- Investigate unexpected traffic patterns
- Check for network loops or broadcast storms
- Review firewall rules

### 4. Container Disk I/O
**Panel:** Disk read/write operations per container

**What it shows:** Disk operations (IOPS) and throughput.

**Normal behavior:**
- **PostgreSQL**: Steady reads/writes
- **Prometheus**: Periodic writes (metric storage)
- **MinIO**: Spikes during file operations
- **Workers**: Temporary file I/O during processing

**When to worry:**
- Very high IOPS: Disk bottleneck
- Zero I/O on database: Possible issue
- Sustained high writes: May wear SSD

**Action:**
- High PostgreSQL I/O: Check for missing indexes or full table scans
- Consider faster storage (SSD/NVMe)
- Review PostgreSQL `work_mem` and `shared_buffers`

### 5. Host CPU Usage
**Panel:** Overall host CPU breakdown

**What it shows:** CPU usage split by type:
- **User**: Application CPU
- **System**: Kernel/OS CPU
- **IOWait**: Waiting for disk I/O
- **Idle**: Unused CPU

**Normal values:**
- Idle: > 20%
- IOWait: < 10%
- User: Varies with load

**When to worry:**
- Idle < 5%: Host CPU exhausted
- IOWait > 30%: Disk bottleneck
- System > 30%: High kernel overhead (check networking)

**Action:**
- High IOWait: Upgrade storage or optimize queries
- Low idle: Add more CPU or optimize workload
- High system: Check for network issues or too many containers

### 6. Host Memory Usage
**Panel:** Total host memory breakdown

**What it shows:** Host RAM usage:
- **Used**: Active memory
- **Cached**: Disk cache (reclaimable)
- **Buffers**: Kernel buffers (reclaimable)
- **Free**: Unused memory

**Normal values:**
- Used: 50-80% of total
- Cached: 10-30% (good for performance)
- Free: > 10%

**When to worry:**
- Free < 5% and cached < 5%: Real memory pressure
- Swap usage: Memory exhausted
- Containers being OOM killed

**Action:**
- Memory pressure: Reduce container memory limits or add RAM
- Check for memory leaks in containers
- Review PostgreSQL `shared_buffers` (shouldn't exceed 25% of RAM)

### 7. Container Restarts
**Panel:** Container restart count

**What it shows:** How many times each container has restarted.

**Normal behavior:**
- Restart count only increases during:
  - Manual restarts
  - Deployments
  - Host reboots

**When to worry:**
- Frequent restarts: Container crash loop
- All containers restarting: Host or Docker issue
- Single container restarting: Application crash

**Action:**
- Check container logs: `docker logs <container-name>`
- Review exit codes: `docker inspect <container-name>`
- Common causes:
  - OOM kills (memory limit too low)
  - Application crashes
  - Health check failures
  - Missing environment variables

### 8. Disk Space Usage
**Panel:** Filesystem usage per mount

**What it shows:** Disk usage for each mounted filesystem.

**Normal values:**
- Root filesystem: < 80% used
- Docker volumes: Varies by data

**When to worry:**
- Any filesystem > 90%: Running out of space
- Rapid growth: Investigate cause
- Docker overlay2 filling up: Clean old images

**Action:**
- Clean Docker: `docker system prune -a --volumes`
- Review largest directories: `du -sh /* | sort -h`
- Expand storage or archive old data
- Check PostgreSQL database size
- Clean old Docker logs: `docker system prune --all --volumes`

## Using This Dashboard

### Quick Health Check
1. **CPU Usage**: All containers < 80%, host has idle capacity
2. **Memory Usage**: No containers near limits, host has free memory
3. **Disk Space**: All filesystems < 80%
4. **Restarts**: No unexpected container restarts

### Performance Investigation

#### App is Slow
1. Check **Container CPU** - is any container maxed out?
2. Check **Host CPU IOWait** - disk bottleneck?
3. Review **Container Memory** - swapping due to memory pressure?
4. Check **Network I/O** - network saturated?

#### Container Keeps Crashing
1. Check **Restarts** panel - which container?
2. Check **Memory Usage** - OOM kill?
3. View logs: `docker logs <container-name> --tail 100`
4. Check resource limits: `docker inspect <container-name>`

### Capacity Planning
Monitor trends for:
1. **CPU Usage**: Plan for CPU upgrade when consistently > 70%
2. **Memory Usage**: Add RAM when free < 20%
3. **Disk Space**: Expand when > 70% used
4. **Network I/O**: May need to consider traffic patterns

## Container-Specific Guidelines

### PostgreSQL Container
**Watch:**
- Memory: Should stabilize after startup
- CPU: Spikes during queries are normal
- Disk I/O: Steady reads/writes

**Tune:**
- `shared_buffers`: 25% of container memory
- `work_mem`: Based on query complexity
- `max_connections`: Based on app needs

### Worker Containers
**Watch:**
- CPU: High during processing is normal
- Memory: Should not grow continuously
- Network: Spikes downloading audio files

**Tune:**
- Memory limit: Based on max audio file size
- CPU: Should not be limited unless needed

### MinIO Container
**Watch:**
- Memory: Relatively stable
- Disk: Growing with stored files
- Network: Spikes during uploads/downloads

**Tune:**
- Ensure fast disk for performance
- Monitor disk space growth

### Prometheus Container
**Watch:**
- Memory: Grows with metric cardinality
- Disk: Grows with retention period
- CPU: Periodic spikes during scraping

**Tune:**
- Retention period: Balance history vs disk space
- Scrape interval: Balance granularity vs overhead

## Common Issues & Solutions

### Issue: Container keeps restarting
**Check:** Restart count increasing
**Debug:**
```bash
docker logs <container-name> --tail 100
docker inspect <container-name> | grep -A 5 State
```
**Common causes:**
- OOM kill: Increase memory limit
- Application crash: Check application logs
- Health check failure: Review health check configuration

### Issue: High CPU usage
**Check:** Container CPU panel
**Action:**
- Identify high-CPU container
- Check if it's temporary (processing) or sustained
- For PostgreSQL: Review slow queries
- For workers: Check if processing is stuck

### Issue: Running out of memory
**Check:** Host memory panel shows low free memory
**Action:**
```bash
# Check which containers use most memory
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"

# Clean up unused resources
docker system prune -a --volumes

# Restart containers with memory leaks
docker restart <container-name>
```

### Issue: Disk space full
**Check:** Disk space usage > 90%
**Action:**
```bash
# Find large directories
du -sh /var/lib/docker/* | sort -h

# Clean Docker system
docker system prune -a --volumes

# Clean old logs
find /var/lib/docker/containers -name "*.log" -mtime +7 -delete

# Check database size
docker exec supabase-db psql -U postgres -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) FROM pg_database;"
```

## Alerting Recommendations

Configure these alerts in `prometheus/alerts.yml`:

- **HighCPUUsage**: Container CPU > 80% for 5 min (WARNING)
- **CriticalCPUUsage**: Container CPU > 95% for 2 min (CRITICAL)
- **HighMemoryUsage**: Container memory > 80% of limit (WARNING)
- **CriticalMemoryUsage**: Container memory > 95% of limit (CRITICAL)
- **ContainerRestarting**: Restart count increasing (CRITICAL)
- **LowDiskSpace**: Disk > 85% full (WARNING)
- **CriticalDiskSpace**: Disk > 95% full (CRITICAL)

## Useful Commands

```bash
# Real-time container stats
docker stats

# Container resource usage
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"

# Check container health
docker inspect --format='{{.State.Health.Status}}' <container-name>

# View container logs
docker logs -f <container-name> --tail 100

# Restart all containers
docker compose -f docker-compose.main.yml restart

# Check disk usage by container
docker system df -v
```

## Best Practices

1. **Set resource limits**: Define CPU and memory limits for all containers
2. **Monitor trends**: Review metrics weekly to spot slow resource leaks
3. **Rotate logs**: Configure log rotation to prevent disk fill
4. **Plan capacity**: Upgrade before resources are exhausted
5. **Test limits**: Verify containers handle memory limits gracefully
6. **Document baseline**: Know normal resource usage patterns
7. **Regular cleanup**: Schedule `docker system prune` monthly
