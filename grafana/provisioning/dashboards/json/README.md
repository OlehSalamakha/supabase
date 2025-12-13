# Grafana Dashboards

This directory contains dashboard JSON files and documentation for monitoring your MemoZen infrastructure.

## 📊 Available Dashboards

### 1. MemoZen Workers
**File:** `memozen-workers.json`
**URL:** http://localhost:3010/d/memozen-workers/memozen-workers
**Documentation:** [DASHBOARD-MEMOZEN-WORKERS.md](./DASHBOARD-MEMOZEN-WORKERS.md)

Monitors the three worker processes (transcription, analysis, embedding):
- Worker health and uptime
- Processing times (p50, p95)
- Success/error rates
- Queue depth

**Use this to:** Track worker performance, identify processing bottlenecks, detect errors

---

### 2. PostgreSQL Database
**Source:** Grafana.com Dashboard #9628
**URL:** http://localhost:3010/d/bf3pxjibsgt8ge/postgresql-database
**Documentation:** [DASHBOARD-POSTGRESQL.md](./DASHBOARD-POSTGRESQL.md)

Monitors Supabase PostgreSQL database:
- Connections and transactions
- Query performance
- Cache hit ratio
- Table bloat and locks
- Replication status

**Use this to:** Identify slow queries, monitor connection usage, plan capacity, detect database issues

---

### 3. Docker Container & Host Metrics
**Source:** Grafana.com Dashboard #10619
**URL:** http://localhost:3010/d/cf3pxjinsh91ca/docker-container-and-host-metrics
**Documentation:** [DASHBOARD-DOCKER-CONTAINERS.md](./DASHBOARD-DOCKER-CONTAINERS.md)

Monitors Docker containers and host:
- Per-container CPU, memory, network, disk
- Container restarts
- Host resource usage
- Disk space

**Use this to:** Identify resource-hungry containers, detect container crashes, plan capacity

---

### 4. Node Exporter Full
**Source:** Grafana.com Dashboard #1860
**URL:** http://localhost:3010/d/bf3pxjj4iascgd/node-exporter-full
**Documentation:** [DASHBOARD-NODE-EXPORTER.md](./DASHBOARD-NODE-EXPORTER.md)

Comprehensive Linux system monitoring:
- CPU usage (user, system, IOWait)
- Memory and swap
- Disk I/O and space
- Network traffic and errors
- System load and uptime

**Use this to:** Deep dive into system performance, identify bottlenecks, troubleshoot system issues

---

## 🚀 Quick Start

1. **Access Grafana:** http://localhost:3010
   - Username: `admin`
   - Password: `123123qaqaw` (change in `.env`)

2. **View dashboards:** Browse → Dashboards → MemoZen folder

3. **Set time range:** Use picker in top right (recommend "Last 15 minutes" for real-time)

4. **Enable auto-refresh:** Click refresh dropdown → Set to 5s or 10s

## 📖 Dashboard Documentation

Each dashboard has detailed documentation explaining:
- **What each metric means**
- **Normal vs concerning values**
- **How to interpret the data**
- **Action steps for common issues**
- **Useful queries and commands**

Read the documentation files above before using dashboards in production.

## 🔧 Adding Community Dashboards

To import additional dashboards from [Grafana.com](https://grafana.com/grafana/dashboards/):

1. Visit the dashboard page (e.g., https://grafana.com/grafana/dashboards/13502-minio-dashboard/)
2. Click "Download JSON" button
3. Save the JSON file to this directory
4. **Important:** Edit the JSON and replace all datasource UIDs:
   ```json
   "datasource": {
     "type": "prometheus",
     "uid": "prometheus"
   }
   ```
5. Restart Grafana or wait for auto-reload (30 seconds)

### Recommended Additional Dashboards

- **MinIO Dashboard** (ID: 13502)
  - S3 storage metrics
  - Download: https://grafana.com/grafana/dashboards/13502-minio-dashboard/

## 🎨 Creating Custom Dashboards

To create or modify dashboards:

1. Edit in Grafana UI (Browse → Dashboards → Create Dashboard)
2. Build panels with PromQL queries
3. Export JSON: Dashboard Settings → JSON Model → Copy to clipboard
4. Save to this directory as `custom-dashboard-name.json`
5. Commit to version control

**Tips:**
- Use the Prometheus datasource UID: `prometheus`
- Add tags for easy filtering: `["memozen", "custom"]`
- Set appropriate refresh intervals
- Document your custom metrics

## 📊 Dashboard Best Practices

1. **Start with time range:** Set to recent data (15-30 minutes) for real-time monitoring
2. **Use auto-refresh:** Enable for live dashboards during operations
3. **Learn normal patterns:** Spend time understanding your baseline metrics
4. **Set up alerts:** Don't rely only on dashboards - configure Alertmanager
5. **Review regularly:** Check dashboards daily during business hours
6. **Document changes:** Note when metrics change and why
7. **Share knowledge:** Train team on dashboard interpretation

## 🔍 Troubleshooting Dashboards

### Dashboard shows "No Data"
1. Check Prometheus is scraping targets: http://localhost:9090/targets
2. Verify metrics exist: http://localhost:9090/graph
3. Adjust time range to recent period
4. Check datasource connection in Grafana

### "Failed to upgrade legacy queries"
1. Dashboard has wrong datasource UID
2. Re-import dashboard following steps above
3. Or use provided import script in `MemoZenInfra/`

### Metrics suddenly stopped
1. Check if Prometheus is running: `docker ps | grep prometheus`
2. Check Prometheus logs: `docker logs memozen-prometheus`
3. Verify exporters are running: `docker ps | grep exporter`
4. Check scrape errors: http://localhost:9090/targets

### Dashboard is slow
1. Reduce time range (use last 15 minutes instead of 24 hours)
2. Reduce auto-refresh rate
3. Simplify complex queries
4. Check Prometheus resource usage

## 📚 Additional Resources

- **Main Monitoring Docs:** `../../MONITORING.md`
- **Prometheus:** http://localhost:9090
- **Alertmanager:** http://localhost:9093
- **Prometheus Query Guide:** https://prometheus.io/docs/prometheus/latest/querying/basics/
- **PromQL Examples:** https://prometheus.io/docs/prometheus/latest/querying/examples/

## 🆘 Getting Help

If dashboards aren't working:
1. Check the main monitoring guide: `MemoZenInfra/MONITORING.md`
2. Review Prometheus targets: http://localhost:9090/targets
3. Check Grafana logs: `docker logs memozen-grafana`
4. Verify all exporters are running: `docker ps`
