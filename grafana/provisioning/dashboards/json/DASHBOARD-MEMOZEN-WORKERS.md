# MemoZen Workers Dashboard

**URL:** http://localhost:3010/d/memozen-workers/memozen-workers

## Overview

This dashboard monitors the three MemoZen worker processes that handle audio note processing:
- **Transcription Worker** - Converts audio to text using OpenAI Whisper
- **Analysis Worker** - Generates title, summary, keywords using OpenAI GPT
- **Embedding Worker** - Creates vector embeddings for semantic search

## Key Metrics

### 1. Worker Status (Up/Down)
**Panel:** Worker Status gauges

**What it shows:** Whether each worker is running and responding to metrics requests.
- **Green (1)**: Worker is healthy and running
- **Red (0)**: Worker is down or unreachable

**Action:**
- If red: Check worker logs with `docker logs memozen-{worker-type}-worker`
- Restart worker: `docker restart memozen-{worker-type}-worker`

### 2. Worker Health Status
**Panel:** Gauge display at top right

**What it shows:** Combined health status of all workers.

**When to worry:**
- Any worker showing DOWN status
- Workers frequently restarting (check uptime)

### 3. Worker Queue Depth
**Panel:** Time series graph (middle left)

**What it shows:** Number of notes waiting in queue for each worker (future metric).

**Normal behavior:**
- Queue = 0: No notes waiting
- Queue < 10: Healthy processing
- Queue > 50: Possible bottleneck

**Action if queue grows:**
- Check worker logs for errors
- Verify OpenAI API is accessible
- Consider scaling workers (run multiple instances)

### 4. Worker Processing Time
**Panel:** Time series graph (middle right)

**What it shows:** How long it takes to process each note (p50 and p95 percentiles).
- **p50 (median)**: Half of notes process faster than this
- **p95**: 95% of notes process faster than this

**Typical values:**
- **Transcription**: 5-30 seconds (depends on audio length)
- **Analysis**: 10-60 seconds (GPT processing time)
- **Embedding**: 1-5 seconds (fast embedding generation)

**When to worry:**
- p95 > 5 minutes: OpenAI API may be slow
- Sudden spikes: Check OpenAI status or network issues
- Increasing trend: May indicate API throttling

**Action:**
- Check OpenAI API status: https://status.openai.com
- Review worker logs for timeout errors
- Verify network connectivity to OpenAI

### 5. Worker Processing Rate
**Panel:** Stacked bar chart (bottom)

**What it shows:** Number of notes processed per second, split by success vs errors.
- **Green bars**: Successful processing
- **Red bars**: Errors

**Normal behavior:**
- Rate depends on app usage
- Error rate should be < 1%

**When to worry:**
- High error rate (red bars)
- Processing rate = 0 when notes are uploaded

**Action if errors are high:**
- Check worker logs: `docker logs memozen-{worker-type}-worker`
- Common issues:
  - Invalid OpenAI API key
  - Audio file format issues (transcription)
  - OpenAI API rate limits
  - Database connection errors

## Using This Dashboard

### Daily Monitoring
1. **Quick health check:** Look at Worker Status gauges - all should be green
2. **Performance check:** Review processing times - should be stable
3. **Error check:** Look for red bars in processing rate chart

### Troubleshooting Slow Processing
1. Check **Processing Time** panel - which worker is slow?
2. Check **Queue Depth** - is queue growing?
3. Review logs for the slow worker
4. Check OpenAI API status if all workers are slow

### Troubleshooting Failures
1. Check **Processing Rate** - which worker has errors?
2. View worker logs: `docker logs -f memozen-{worker}-worker --tail 100`
3. Common fixes:
   - Restart the worker: `docker restart memozen-{worker}-worker`
   - Check OpenAI API key in `.env` file
   - Verify database is accessible

### Monitoring During Load
If you expect high usage:
1. Watch **Queue Depth** - should not grow continuously
2. Monitor **Processing Time p95** - should remain stable
3. Check **Processing Rate** - should increase with load

## Alert Configuration

Recommended alerts (see `prometheus/alerts.yml`):
- **WorkerDown**: Worker unavailable for > 2 minutes (CRITICAL)
- **WorkerHighErrorRate**: Error rate > 10% for 10 minutes (WARNING)
- **WorkerProcessingSlow**: p95 > 5 minutes for 10 minutes (WARNING)
- **WorkerQueueGrowing**: Queue growing for 15 minutes (WARNING)

## Useful Queries

Run these in Prometheus (http://localhost:9090) for deeper analysis:

```promql
# Total notes processed by worker
sum by(worker_type) (worker_processing_total)

# Current error rate
sum by(worker_type) (rate(worker_processing_errors_total[5m]))
  / sum by(worker_type) (rate(worker_processing_total[5m]))

# Average processing time
sum by(worker_type) (rate(worker_processing_duration_seconds_sum[5m]))
  / sum by(worker_type) (rate(worker_processing_duration_seconds_count[5m]))

# Worker uptime
time() - process_start_time_seconds{service="worker"}
```

## Tips

- **Time range**: Use "Last 15 minutes" for real-time monitoring
- **Auto-refresh**: Enable 5s refresh for live updates
- **Zoom**: Click and drag on any graph to zoom into a time period
- **Annotations**: Hover over points to see exact values and timestamps
