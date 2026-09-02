# Day 3 assignment — monitoring and root cause

Topic: `<your-topic>` (for example `orders-user3`)
Group: `<your-consumer-group>` (for example `cg-user3-support`)
Cluster: `<cluster-name>`
Time range used in CloudWatch: Last 1 hour, at `<time you looked>` UTC

## 1 — Monitoring configuration

| Setting | What you found |
|---------|----------------|
| Monitoring level | |
| Broker log delivery enabled? | |
| Log group name | |

## 2 — Load test result

From `kafka-producer-perf-test`:

| Figure | Value |
|--------|-------|
| Records per second | |
| MB per second | |
| Average latency (ms) | |
| Maximum latency (ms) | |

What does the gap between average and maximum latency suggest?

## 3 — Metrics measured

| Metric | Broker / scope | Value | Healthy? |
|--------|----------------|-------|----------|
| `CpuIdle` (lowest of the three brokers) | | | |
| `KafkaDataLogsDiskUsed` (highest) | | | |
| `BytesInPerSec` peak | cluster | | |
| `BytesOutPerSec` peak | cluster | | |
| `SumOffsetLag` peak | group + topic | | |

## 4 — Broker log line

| Time | Level | What the broker said |
|------|-------|----------------------|
| | | |

## 5 — Alarms

| Alarm name | Metric | Threshold | Existing or created by you |
|------------|--------|-----------|-----------------------------|
| | | | |

## 6 — Consumer lag cycle

| Stage | Total LAG |
|-------|-----------|
| After the load test, before consuming | |
| After draining | |

## 7 — Root cause narrative (4 to 6 sentences)

Link the Day 2 log evidence to the metrics you measured today. Label each fact `[log]` or `[live]`.

## 8 — What you would do next in production

One action you would take first, and one action you would deliberately avoid — with the reason for each.
