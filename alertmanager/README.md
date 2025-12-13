# Alertmanager Configuration

This directory contains the Alertmanager configuration for sending alert notifications.

## Quick Setup

1. Edit `alertmanager.yml`
2. Uncomment your preferred notification channel (Telegram, Slack, or Discord)
3. Add your webhook URL or bot credentials
4. Restart Alertmanager: `docker compose restart alertmanager`

## Notification Channels

### Telegram

**Setup:**
1. Create a bot with [@BotFather](https://t.me/botfather)
2. Get your bot token
3. Start a chat with your bot
4. Get your chat ID using: `https://api.telegram.org/bot8208318169:AAFefe8qlpi8AozDkjXf08nYX51U2TSWH8g/getUpdates`

**Configuration:**
```yaml
telegram_configs:
  - bot_token: 'YOUR_TELEGRAM_BOT_TOKEN'
    chat_id: YOUR_CHAT_ID
    parse_mode: 'HTML'
```

### Slack

**Setup:**
1. Go to https://api.slack.com/apps
2. Create a new app → Incoming Webhooks
3. Add webhook to your desired channel
4. Copy the webhook URL

**Configuration:**
```yaml
slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
    channel: '#alerts'
```

### Discord

**Setup:**
1. Go to your Discord server settings
2. Integrations → Webhooks → New Webhook
3. Choose channel and copy webhook URL

**Configuration:**
```yaml
discord_configs:
  - webhook_url: 'https://discord.com/api/webhooks/YOUR/WEBHOOK/URL'
```

## Alert Severity Levels

- **Critical**: Immediate attention required (e.g., service down, out of disk space)
- **Warning**: Should be investigated (e.g., high resource usage, slow performance)

## Testing Alerts

To test your Alertmanager configuration:

```bash
# Send a test alert
curl -X POST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  },
  "annotations": {
    "summary": "This is a test alert",
    "description": "Testing Alertmanager configuration"
  }
}]'
```

## Alert Routing

Current routing configuration:
- **Critical alerts**: Sent immediately, repeat every 4 hours if not resolved
- **Warning alerts**: Grouped for 30 seconds, repeat every 12 hours
- **All other alerts**: Use default receiver

## Silencing Alerts

To temporarily silence alerts:

1. Access Alertmanager UI: `http://localhost:9093`
2. Click "Silences" → "New Silence"
3. Add matchers and duration
4. Save silence

Or use the command line:

```bash
# Silence all alerts matching alertname=HighCPUUsage for 2 hours
amtool silence add alertname=HighCPUUsage --duration=2h --author=admin --comment="Maintenance window"
```

## Environment Variables

You can use environment variables in your configuration:

```yaml
telegram_configs:
  - bot_token: '${TELEGRAM_BOT_TOKEN}'
    chat_id: ${TELEGRAM_CHAT_ID}
```

Then set in `.env` file:
```
TELEGRAM_BOT_TOKEN=your_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
```

## Troubleshooting

### Check Alertmanager logs
```bash
docker compose logs -f alertmanager
```

### Check Alertmanager status
```bash
curl http://localhost:9093/api/v1/status
```

### Reload configuration
```bash
curl -X POST http://localhost:9093/-/reload
```

## Further Reading

- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/)
