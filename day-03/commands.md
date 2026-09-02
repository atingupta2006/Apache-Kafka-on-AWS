# Day 3 — Commands

**Platform:** Windows 10 **Command Prompt (CMD)** for the Kafka CLI. All **CloudWatch and MSK** work is done in the **AWS Console** — [lab.ipynb](lab.ipynb) has the step-by-step console instructions.

**Easier option:** [lab.ipynb](lab.ipynb) — Kafka CMD cells plus the console walkthrough ([README-lab.md](README-lab.md)).

---

## Setup — Kafka CLI (Jupyter or CMD)

**Each lab window — paste first:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

This sets `REGION`, `CLUSTER_ARN`, `CLUSTER_NAME`, `BOOTSTRAP`, `TOPIC`, `GROUP`, `CLIENT`, and the Kafka `PATH`.

**Time range for every graph today: Last 1 hour.**

Use the relative range buttons in CloudWatch rather than a fixed date. It always covers the traffic you generate in this lab, and it is what you would use on a live incident.

---

## Section 0 — Confirm monitoring and logging (AWS Console)

A cluster only publishes what it has been configured to publish. Two independent switches:

| Switch | Produces | Lands in | Where to set it |
|--------|----------|----------|-----------------|
| **Enhanced monitoring** | Numeric metrics — CPU, disk, bytes | CloudWatch **Metrics**, namespace `AWS/Kafka` | MSK → cluster → Properties → Monitoring |
| **Broker log delivery** | Broker `server.log` lines | CloudWatch **Logs**, one stream per broker | MSK → cluster → Properties → Log delivery |

Both are already enabled on the class cluster. Confirm and record them, because this panel is the first place to look when a metric appears to be missing.

The level must be at least **`PER_BROKER`**, because `CpuIdle` and `KafkaDataLogsDiskUsed` do not exist at `DEFAULT`.

| Level | Gives you |
|-------|-----------|
| `DEFAULT` | Cluster-level basics only |
| `PER_BROKER` | Per-broker CPU, disk, memory — **the minimum for this lab** |
| `PER_TOPIC_PER_BROKER` | Adds per-topic breakdown |
| `PER_TOPIC_PER_PARTITION` | Adds partition-level detail |

---

## Generate load so the graphs have data

CloudWatch draws what happened. Put your own traffic on the cluster first:

```bat
kafka-producer-perf-test.bat --topic %TOPIC% --num-records 2000 --record-size 1024 --throughput 1000 --producer.config %CLIENT% --producer-props bootstrap.servers=%BOOTSTRAP%
```

This writes about 2 MB to `%TOPIC%` in a few seconds. It moves `BytesInPerSec`, nudges `CpuIdle` and disk, and — because you are not consuming yet — creates real lag on `%GROUP%`.

Read the summary line for throughput and latency:

```
2000 records sent, 998.5 records/sec (0.98 MB/sec), 12.34 ms avg latency, 245.00 ms max latency
```

A large gap between average and maximum latency means something paused: a leader change, a garbage-collection pause, or a slow disk.

Metrics appear at 1-minute granularity and can take 2 to 3 minutes to surface.

---

## AWS Console tasks

Full steps are in [lab.ipynb](lab.ipynb). Time range **Last 1 hour** throughout.

| Task | Console path | Dimensions |
|------|--------------|------------|
| Broker CPU | CloudWatch → Metrics → `AWS/Kafka` → **`CpuIdle`** | Broker ID, Cluster Name |
| Broker logs | CloudWatch → Logs → Log groups → `/aws/msk/%CLUSTER_NAME%` | one stream per broker |
| Review alarms | CloudWatch → Alarms → All alarms | filter on `Kafka` |
| Create alarms | CloudWatch → Alarms → Create alarm | see the alarm table below |
| Consumer lag | CloudWatch → Metrics → `AWS/Kafka` → **`SumOffsetLag`** | Cluster Name, Consumer Group, Topic |
| Throughput | CloudWatch → Metrics → `AWS/Kafka` → **`BytesInPerSec`** / **`BytesOutPerSec`** | Cluster Name, then add Broker ID |
| Disk | CloudWatch → Metrics → `AWS/Kafka` → **`KafkaDataLogsDiskUsed`** | Broker ID, Cluster Name |
| Cluster state | MSK → Clusters → `%CLUSTER_NAME%` | expect **Active** |

### Alarms to create

| Metric | Risk it catches | Threshold | Statistic |
|--------|-----------------|-----------|-----------|
| `CpuIdle` | Broker out of CPU headroom | below **20** for **2** consecutive 5-minute periods | Average |
| `KafkaDataLogsDiskUsed` | Log volume filling up | above **80** percent | Average |
| `SumOffsetLag` | Consumer group falling behind | above **10000** — tune to your topic | Maximum |

Requiring two or three consecutive periods rather than one keeps the alarm from firing on momentary spikes.

---

## Kafka CLI — topic and consumer lag

Topic describe — note the **Leader** column, those broker ids are what you select in the console:

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

Consumer group lag:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe --timeout 90000
```

Drain the backlog, keeping the message bodies out of your terminal:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --max-messages 2000 --timeout-ms 90000 > nul
```

`> nul` discards standard output, which is where the message bodies go. The consumer's summary — `Processed a total of 2000 messages` — is written to standard error, so it still appears.

Then re-run the group describe and confirm `LAG` is 0 on every partition.

---

## How to read the metrics together

| CpuIdle | Disk | BytesIn | Lag | What it means |
|---------|------|---------|-----|---------------|
| High | Low | Flat | Flat | Idle and healthy — if the app is failing, the broker is not the cause |
| High | Low | Flat | Growing | Producers stopped, or nothing is consuming |
| Low | Low | High | Low | Busy and coping |
| High | **High** | Flat | Flat | Retention is holding too much data for the volume |
| **Low** | High | High | Growing | Broker saturated — a real capacity incident |

Never escalate on a single metric. One number invites an argument; four correlated numbers invite a fix.

---

## RCA worksheet

Write 4 to 6 sentences linking the Day 2 log timestamps to the metrics, logs, and alarms you looked at today. Include the one action you would take first, and one action you would deliberately avoid.

## Assignment

Fill in [samples/assignment-metrics.md](samples/assignment-metrics.md) with the values you measured.

---

## Quick troubleshooting (Day 3)

| Problem | What to check |
|---------|---------------|
| Wrong shell | Use **CMD**, not PowerShell |
| Empty `%CLUSTER_NAME%` | Run `start-lab.bat` again — it writes `CLUSTER_NAME` |
| Metric has no data | 1. Console region matches `%REGION%`  2. Dimension group is **Broker ID, Cluster Name**  3. Monitoring level is at least `PER_BROKER`  4. Wait 2–3 minutes after generating load |
| `CpuIdle` not listed at all | Monitoring level is `DEFAULT` — raise it to `PER_BROKER` (section 0) |
| No MSK log group | Broker log delivery is off — enable it in MSK → Properties → Log delivery |
| Group `--describe` timeout | Re-run with `--timeout 90000`; a first-attempt timeout on the public endpoint is common |
| Perf test not found | Kafka `bin\windows` is not on `PATH` — re-run `set-kafka-lab.bat` |
