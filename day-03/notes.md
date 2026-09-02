# Day 3 — Monitoring and performance

Day 2 used logs and `--describe`. Today you add **CloudWatch**, so you can say whether the broker was CPU-bound, disk-bound, or simply idle while the application was timing out.

Today's work is done in two places: the Kafka CLI in the notebook, and the **AWS Console** for all CloudWatch metrics, logs and alarms. Commands: [commands.md](commands.md).

The lab follows a deliberate order — switch monitoring on, generate your own traffic, then read the graphs. Metrics only exist while something is happening, so you create the load first and read your own data afterwards.

Use your own topic/group (`orders-userN` / `cg-userN-support`).

---

## Monitoring Kafka cluster health

Health is not one green light. For MSK, combine:

| Check | Tool |
|-------|------|
| Cluster state | `aws kafka describe-cluster` → `ACTIVE` |
| Offline / URP | Topic `--describe` + CloudWatch `OfflinePartitionsCount` if present |
| Broker process resources | CloudWatch PER_BROKER CPU, disk, memory |
| Consumer delivery | Group lag (CLI today, CloudWatch lag metrics if enabled) |

A cluster can be `ACTIVE` while one topic has no leader or lag is 50,000.

---

## AWS CloudWatch metrics

Namespace: `AWS/Kafka`. Dimension always includes **Cluster Name** (your MSK cluster name). PER_BROKER metrics add **Broker ID**.

### Two switches, often confused

| Switch | Produces | Lands in | Set in |
|--------|----------|----------|--------|
| **Enhanced monitoring** | Numeric metrics — CPU, disk, bytes | CloudWatch **Metrics** | MSK → cluster → Properties → Monitoring |
| **Broker log delivery** | Broker `server.log` lines | CloudWatch **Logs**, one stream per broker | MSK → cluster → Properties → Log delivery |

Turning one on does not turn on the other. A cluster can have complete metrics and no logs at all.

### Monitoring levels

The level decides which metrics exist:

| Level | What exists |
|-------|-------------|
| `DEFAULT` | Cluster-level basics only — **no per-broker CPU or disk** |
| `PER_BROKER` | Adds `CpuIdle`, `KafkaDataLogsDiskUsed`, `MemoryUsed` — **the minimum for useful troubleshooting** |
| `PER_TOPIC_PER_BROKER` | Adds a per-topic breakdown |
| `PER_TOPIC_PER_PARTITION` | Adds partition-level detail |

Almost every real troubleshooting question is per-broker — *which broker is hot?* — so `PER_BROKER` is the practical floor.

### Why a metric shows no data

This is nearly always configuration rather than a broken query. Check in order:

1. Console **region** matches the cluster's region
2. Exact **Cluster Name** string matches MSK
3. Dimension group is **Broker ID, Cluster Name**, not cluster-level only
4. Monitoring level is at least **`PER_BROKER`** — `CpuIdle` does not exist below it
5. Traffic has actually happened, and 2 to 3 minutes have passed for it to surface

`SumOffsetLag` can be absent even when CLI lag works. When it is, `kafka-consumer-groups.bat --describe` is the authoritative lag source.
---

## Broker health monitoring

Useful PER_BROKER metrics:

| Metric | How to read it |
|--------|----------------|
| `CpuIdle` | High idle = CPU not the bottleneck. Low idle = CPU pressure |
| `KafkaDataLogsDiskUsed` | Percent of Kafka log volume. High → produce risk, URP |
| `RootDiskUsed` | OS disk, not the log volume |
| `MemoryUsed` / `MemoryFree` | Pressure, paging |
| `SwapUsed` | Should stay near 0 |

Compare **three** broker IDs (or however many your cluster has). One hot broker + partition leaders stacked on it is a skew story, not “MSK is down.”

---

## Consumer lag monitoring

Still authoritative: `kafka-consumer-groups.bat --describe`.

CloudWatch may expose `SumOffsetLag`, `MaxOffsetLag`, `EstimatedMaxTimeLag` with dimensions Cluster Name, Consumer Group, Topic. If those metrics are missing in the account, say so and use the CLI.

Lag in CloudWatch is delayed versus CLI. For an incident in the last five minutes, trust `--describe`.

---

## Disk utilization monitoring

`KafkaDataLogsDiskUsed` per broker. This is the **Kafka log volume**, not the broker's root disk and not your Windows `C:` drive.

Disk is the most unforgiving MSK metric: high CPU makes things slow, but a **full log volume stops the broker accepting writes altogether**, and recovery from that is slow and manual. That asymmetry is why disk deserves the tightest alarm.

### What retention means, and why it belongs here

**Retention** is how long Kafka keeps a message before deleting it, whether or not anyone read it:

| Setting | Meaning |
|---------|---------|
| `retention.ms` | Delete messages older than this age |
| `retention.bytes` | Once a partition exceeds this size, delete its oldest data |

Whichever limit is reached first wins. Kafka deletes whole **segment files**, so disk usage falls in steps rather than smoothly.

Disk usage and retention are the same problem from opposite ends. If disk keeps climbing, either more data is arriving than before, or retention is holding data longer than the volume can take. You have two levers: store less, or keep it for less time.

Retention also caps what you can recover: you can only replay messages **still on disk**. Changing `retention.ms` is a **Day 4** exercise — today you read the graph and form an opinion about whether retention suits the volume.

---

## Monitoring alerts and notifications

A CloudWatch alarm has four parts:

| Part | Meaning | Example |
|------|---------|---------|
| **Metric** | What is watched | `KafkaDataLogsDiskUsed` |
| **Threshold** | The line it must cross | above 80 percent |
| **Period and datapoints** | How long it must stay across before firing | 2 consecutive 5-minute periods |
| **Action** | Who is told | an SNS topic that emails the on-call engineer |

The **datapoints** part matters more than people expect. An alarm that fires on a single spike fires constantly, and a team that receives constant alerts stops reading them — that is alert fatigue, and it is how real outages get missed. Requiring two or three consecutive periods filters out blips while still catching a trend.

Today you **review** the alarms that already exist, then **create** one alarm per critical risk:

| Metric | Risk | Threshold | Statistic |
|--------|------|-----------|-----------|
| `CpuIdle` | Broker out of CPU headroom | below 20 for 2 periods | Average |
| `KafkaDataLogsDiskUsed` | Log volume filling | above 80 percent | Average |
| `SumOffsetLag` | Consumer group falling behind | above 10000, tuned to the topic | Maximum |

If an alarm for a metric already exists, review it rather than creating a second one.

**An alarm is a notification, not a diagnosis.** It tells you something crossed a line; it never tells you why. You still read the logs and run `--describe`.

---

## Identifying slow producers

Evidence: app logs (`TimeoutException`, latency), CloudWatch `BytesInPerSec` against the timeout timestamps.

If `BytesInPerSec` is high and `CpuIdle` is low, the brokers are busy and back-pressure is expected. If `BytesInPerSec` is **flat** while the application logs timeouts, the traffic never reached the broker — look at the network path, or at `acks` and ISR, not at "slow produce code". There is no point tuning a broker that never received the messages.

### Measuring instead of guessing

`kafka-producer-perf-test` ships with Kafka and settles the most common argument in production — *is Kafka slow, or is the application slow?*

```bat
kafka-producer-perf-test.bat --topic %TOPIC% --num-records 2000 --record-size 1024 --throughput 1000 --producer.config %CLIENT% --producer-props bootstrap.servers=%BOOTSTRAP%
```

It reports achieved throughput plus average and maximum latency. Run it **from the same host as the application**:

| Result | Conclusion |
|--------|------------|
| Perf test fast, application slow | The cluster is fine. The problem is the application's code or configuration. |
| Perf test also slow | The problem is shared — the broker, the network path, or that host |
| Large gap between average and maximum latency | Something paused: a leader change, a garbage-collection pause, or a slow disk |

It is also how you create traffic on a quiet cluster so the graphs have something to show.

---

## Identifying slow consumers

Lag climbing, members still in the group, CPU on **app** hosts high, broker `BytesOutPerSec` modest → slow consumer. Lag climbing, no members → stopped consumer (Day 2 recovery).

---

## Broker performance issues

Low `CpuIdle` on the leader of a hot partition. Disk high. Network dropped packets (`NetworkRxDropped` / `NetworkTxDropped`). Maintenance window (MSK state).

Do not restart MSK brokers as a first action in this workshop.

---

## Network latency

Client `request.latency` vs broker. Off-VPC Windows lab clients use public listeners (**9196**); latency should still be low within the lab network. If the producer is in another region, latency is an architecture ticket, not an SG typo.

SG still causes **timeouts**, which look like latency in some client logs. Distinguish: never connects vs slow acks.

---

## Common performance bottlenecks

| Bottleneck | Evidence |
|------------|----------|
| Stopped consumer | No members, lag = log-end − stuck offset |
| Slow consumer | Members present, lag up, app CPU/GC |
| Hot partition | One partition lag/bytes dominate |
| Broker CPU | Low CpuIdle on leader |
| Broker disk | KafkaDataLogsDiskUsed high |
| ISR / acks=all | Timeouts + URP |
| Client path | Off-VPC Windows lab client (public **9196**) works; in-VPC app host fails |

---

## Correlating application behaviour with Kafka metrics

Use the **same time window** for every piece of evidence. Take the first and last error timestamp from the application log, then look at broker metrics for exactly that window.

The Day 2 sample logs carry timestamps from a past date, so CloudWatch holds nothing for those exact minutes. That is the normal situation when a ticket arrives with logs attached from earlier in the day: you read the log for what the application experienced, and you use a live window to establish whether the problem is still happening. Keep the two clearly labelled and do not force one onto the other.

1. Log timestamp  
2. `--describe` lag and ISR  
3. CloudWatch for that 15-minute window on the **leader broker id** from `--describe`

If logs scream timeout and CpuIdle is 90% and disk is 20%, the broker is not the bottleneck.
