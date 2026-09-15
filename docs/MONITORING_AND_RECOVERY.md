# Production Monitoring, Observability & Disaster Recovery — LensIQ

## 1. Healthcheck & Metrics Endpoints

LensIQ microservices expose standard health and telemetry interfaces:

| Microservice | Endpoint | Protocol | Purpose | Response Sample |
| :--- | :--- | :--- | :--- | :--- |
| **Node.js Backend** | `GET /api/v1/health` | HTTP | Service liveness & supported sources | `{"status":"healthy","version":"1.0.0"}` |
| **Python AI Engine** | `GET /health` | HTTP | Process liveness | `{"status":"ok","service":"ai-service"}` |
| **Python AI Engine** | `GET /status` | HTTP | GPU/CPU device state & model loaded | `{"status":"ready","model":"yolov8n.pt","device":"cpu"}` |
| **Python AI Engine** | `GET /metrics` | Prometheus | Formatted metric gauges for Prometheus scraper | `ai_processed_frames_total 12840` |
| **Streaming Gateway** | `GET http://gateway:8889/` | HTTP | WebRTC / HLS media server status | `200 OK` |

---

## 2. Prometheus & Grafana Configuration

### Prometheus Scrape Target (`prometheus.yml`):
```yaml
scrape_configs:
  - job_name: 'lensiq-backend'
    metrics_path: '/api/v1/metrics'
    scrape_interval: 15s
    static_configs:
      - targets: ['backend:3001']

  - job_name: 'lensiq-ai-service'
    metrics_path: '/metrics'
    scrape_interval: 10s
    static_configs:
      - targets: ['ai-service:8000']
```

### Key Performance Indicators (KPIs) to Alert On:
1. **AI Processing Latency (`ai_model_latency_ms > 250ms`)**:
   - Indicates CPU/GPU contention on inference server.
2. **Camera Offline Ratio (`offline_cameras / total_cameras > 0.05`)**:
   - Triggers automated incident generation for Branch Security.
3. **Internal Auth Failures (`http_requests_total{status="401", path="/api/v1/internal/*"} > 5`)**:
   - Alerts on potential secret mismatch or unauthorized intrusion attempt.
4. **Active WebRTC Sessions vs System Capacity**:
   - Ensures media gateway network throughput remains below 80% link bandwidth.

---

## 3. Streaming Reconnection & Resilience Logic

The Flutter client and Node.js backend implement a 3-tier reconnection strategy:

```
[Active Stream Playback]
           |
      Stream Interrupted (Network glitch / Camera reboot)
           |
           v
[State: Reconnecting / Warning]
           |
    Retry 1: Wait 1s (Backoff)
           |
    Retry 2: Wait 2s
           |
    Retry 3: Wait 5s
           |
    Retry 4: Request new ephemeral stream token from Backend
           |
           +---> Success: Resume WebRTC / HLS playback seamlessly
           |
           +---> 5 Consecutive Failures:
                 Mark Camera Status -> 'OFFLINE'
                 Log Audit Event: `CAMERA_STREAM_DROPPED`
                 Dispatch FCM Notification to Branch Security
```

---

## 4. Supabase Database Backup & PITR Strategy

### Point-in-Time Recovery (PITR):
* Enabled on Supabase Enterprise / Pro projects.
* Continuous WAL (Write-Ahead Logging) archiving allows granular restoration to any specific second within the last 7 to 30 days.

### Daily Encrypted Automated Dumps:
For multi-cloud disaster recovery, run an automated cron job backing up schema and row data:
```bash
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backups/lensiq_db_${TIMESTAMP}.sql.gz"

# Dump database excluding vault secrets if using external KMS
pg_dump "$DATABASE_URL" | gzip > "$BACKUP_FILE"

# Encrypt backup file with AES-256
openssl enc -aes-256-cbc -salt -in "$BACKUP_FILE" -out "${BACKUP_FILE}.enc" -pass file:/secrets/backup_key.bin

# Ship to isolated cold storage bucket
aws s3 cp "${BACKUP_FILE}.enc" s3://lensiq-disaster-recovery-backups/
```

### Database Performance Indexes:
Migration `20260915000005_production_performance_indexes.sql` establishes composite and partial indexes for high-frequency queries:
* `idx_incidents_company_brand_status`: Speeds up multi-tenant dashboard aggregation.
* `idx_incidents_created_at_desc`: Accelerates chronological incident feeds.
* `idx_cameras_lookup`: Instant multi-tenant camera resolution.
* `idx_notification_records_unread`: Rapid mobile notification badge retrieval.
