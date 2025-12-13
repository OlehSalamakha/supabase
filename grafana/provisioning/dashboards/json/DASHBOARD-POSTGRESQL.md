# PostgreSQL Database Dashboard

**URL:** http://localhost:3010/d/bf3pxjibsgt8ge/postgresql-database

## Overview

This dashboard monitors your Supabase PostgreSQL database, showing performance metrics, connection usage, query statistics, and table/index health.

## Key Metrics

### 1. Database Connections
**Panel:** Active/Idle connections gauge

**What it shows:** Current database connections.
- **Active**: Queries currently running
- **Idle**: Connected but waiting

**Normal values:**
- Total connections: 10-50 (depends on usage)
- Active: 1-10
- Idle: 5-20

**When to worry:**
- Total near max connections (default: 100)
- High idle connections (> 50): possible connection leaks
- No connections: Database may be down

**Action:**
- High connections: Check for connection leaks in application code
- Near max: Increase `max_connections` or use connection pooling (Supavisor)
- Monitor idle connections closing properly

### 2. Transactions Per Second (TPS)
**Panel:** Commits/Rollbacks graph

**What it shows:** Database transaction rate.
- **Commits**: Successful transactions
- **Rollbacks**: Failed/cancelled transactions

**Normal behavior:**
- TPS increases with app usage
- Rollback rate < 5% of commits

**When to worry:**
- High rollback rate: Application errors or conflicts
- TPS = 0 when app is active: Database may be unresponsive
- Sudden drop: Possible database issue

**Action:**
- High rollbacks: Check application logs for database errors
- Review slow query log
- Check for deadlocks in PostgreSQL logs

### 3. Query Performance
**Panel:** Query execution time percentiles

**What it shows:** How long queries take to execute (p50, p95, p99).
- **p50**: Median query time
- **p95**: 95% of queries finish within this time
- **p99**: 99% of queries finish within this time

**Typical values:**
- p50: < 10ms
- p95: < 100ms
- p99: < 500ms

**When to worry:**
- p95 > 1 second: Slow queries impacting performance
- p99 > 5 seconds: Very slow queries exist
- Increasing trend: Database under stress

**Action:**
- Run `EXPLAIN ANALYZE` on slow queries
- Add missing indexes
- Review RLS policies (can impact performance)
- Check table bloat and run `VACUUM`

### 4. Database Size
**Panel:** Size over time graph

**What it shows:** Total size of all databases.

**Normal behavior:**
- Steady growth as data accumulates
- Sudden jumps after bulk inserts

**When to worry:**
- Rapid unexpected growth: Check for data issues
- Size near disk capacity: Need to expand storage
- Size not growing when adding data: Possible write issue

**Action:**
- Monitor disk space: `df -h` on host
- Review largest tables:
  ```sql
  SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
  FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;
  ```
- Consider archiving old data

### 5. Cache Hit Ratio
**Panel:** Buffer cache effectiveness

**What it shows:** Percentage of data reads from memory vs disk.
- **High (> 95%)**: Good - data is cached in memory
- **Low (< 90%)**: Poor - frequent disk reads

**When to worry:**
- Cache hit ratio < 90%: May need more memory
- Sudden drop: Large query scanning many rows
- Consistently low: Increase `shared_buffers`

**Action:**
- Low ratio: Consider increasing PostgreSQL memory settings
- Check for full table scans in slow queries
- Review query patterns

### 6. Table Bloat
**Panel:** Dead tuples and bloat estimation

**What it shows:** Unused space in tables (dead rows not yet cleaned).

**Normal behavior:**
- Some dead tuples after updates/deletes
- Regular VACUUM cleans them up

**When to worry:**
- Dead tuple ratio > 20%: VACUUM not keeping up
- Large dead tuple count: Performance degradation
- Bloat percentage > 30%: Wasted disk space

**Action:**
- Manual vacuum: `VACUUM ANALYZE table_name;`
- Check autovacuum settings
- For severe bloat: `VACUUM FULL` (requires table lock)

### 7. Replication Lag (if applicable)
**Panel:** Replication delay graph

**What it shows:** How far behind replicas are from primary.

**Normal values:**
- Lag: < 1 second
- In sync: 0 bytes lag

**When to worry:**
- Lag > 10 seconds: Replication falling behind
- Increasing lag: Replica may be unhealthy
- Lag = 0 but expected data missing: Replication broken

**Action:**
- Check replica status: `SELECT * FROM pg_stat_replication;`
- Review replica logs
- Check network connectivity
- Verify disk space on replica

### 8. Locks
**Panel:** Lock types and wait times

**What it shows:** Database locks preventing concurrent access.

**Normal behavior:**
- Row locks during transactions (transient)
- Few or no long-held locks

**When to worry:**
- Many ExclusiveLock or AccessExclusiveLock: Blocking operations
- Long lock wait times: Queries stuck waiting
- Increasing locks: Possible deadlock situation

**Action:**
- Find blocking queries:
  ```sql
  SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';
  ```
- Kill blocking query (carefully):
  ```sql
  SELECT pg_terminate_backend(pid);
  ```
- Review long-running transactions

## Using This Dashboard

### Daily Health Check
1. **Connections**: Check not near max
2. **TPS**: Verify transactions are processing
3. **Query Performance**: p95 should be stable
4. **Cache Hit Ratio**: Should be > 95%

### Performance Investigation
If app is slow:
1. Check **Query Performance** - are queries slow?
2. Review **Active Connections** - is database overloaded?
3. Check **Cache Hit Ratio** - are we hitting disk too much?
4. Look at **Locks** - are queries blocked?

### Capacity Planning
Monitor these for growth trends:
1. **Database Size** - plan for storage expansion
2. **Connection Count** - may need connection pooling
3. **TPS** - understand transaction load
4. **Query Performance** - plan for optimization work

### Maintenance Alerts
Watch for:
1. **High Dead Tuples** - schedule VACUUM
2. **Low Cache Hit** - consider more RAM
3. **High Connections** - investigate connection leaks
4. **Slow Queries** - review and optimize

## Common Issues & Solutions

### Issue: "Too many connections"
**Symptoms:** Connection errors in application logs
**Check:** Connection count panel
**Fix:**
- Review connection pooling in Supabase (Supavisor)
- Increase `max_connections` (requires restart)
- Find and fix connection leaks

### Issue: Slow queries
**Symptoms:** High p95/p99 query times
**Check:** Query performance panel
**Fix:**
- Enable slow query log: `log_min_duration_statement = 1000`
- Run EXPLAIN ANALYZE on slow queries
- Add missing indexes
- Optimize RLS policies

### Issue: Database growing too fast
**Symptoms:** Rapid size increase
**Check:** Database size panel
**Fix:**
- Identify large tables with query above
- Review data retention policy
- Check for log tables needing rotation
- Consider partitioning large tables

### Issue: High CPU usage
**Symptoms:** Slow performance, high load
**Check:** Active connections, query performance
**Fix:**
- Identify expensive queries in `pg_stat_statements`
- Check for full table scans
- Review indexes
- Consider query optimization or caching

## Useful Queries

Run in Supabase Studio SQL Editor:

```sql
-- Top 10 largest tables
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Current active queries
SELECT pid, usename, state, query, query_start
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Slow queries (requires pg_stat_statements)
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;

-- Connection count by state
SELECT state, count(*)
FROM pg_stat_activity
GROUP BY state;

-- Table bloat (dead tuples)
SELECT schemaname, tablename, n_dead_tup, n_live_tup,
       round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 20;
```

## Best Practices

1. **Monitor regularly**: Check dashboard daily during business hours
2. **Set up alerts**: Configure Alertmanager for critical metrics
3. **Establish baselines**: Know your normal connection count, TPS, query times
4. **Plan maintenance**: Schedule VACUUM during low-usage periods
5. **Review indexes**: Quarterly index review and optimization
6. **Archive old data**: Implement data retention policies
7. **Test backups**: Regularly verify backup restore procedures

## References

- [PostgreSQL Monitoring](https://www.postgresql.org/docs/current/monitoring.html)
- [Supabase Performance](https://supabase.com/docs/guides/platform/performance)
- [pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html)
