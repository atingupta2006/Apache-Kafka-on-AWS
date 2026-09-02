# Day 3 — Jupyter lab (Kafka CLI + AWS Console)

Same setup as Day 1 — see [day-01/README-lab.md](../day-01/README-lab.md).

Requires `CLUSTER_NAME` in your session file, which `start-lab.bat` writes.

```bat
call scripts\start-jupyter-lab.bat
```

Open **day-03/lab.ipynb**.

## How Day 3 is split

| Where | What you do |
|-------|-------------|
| **Notebook (CMD cells)** | Kafka CLI — generate load, describe the topic, measure and drain consumer lag |
| **AWS Console (browser)** | CloudWatch metrics, CloudWatch Logs, alarms, and MSK cluster state |

Keep both open side by side. The notebook tells you which console screen to open at each step.

## Before you start

1. Confirm the Console region matches your `%REGION%`.
2. Work through **section 0** of the notebook first — it confirms the cluster's monitoring level is at least `PER_BROKER` and that broker log delivery is on. Without those, some metrics and all broker logs are simply not published.
3. Use a **Last 1 hour** time range on every graph, so it covers the traffic you generate in the lab.

## A metric shows no data

Check in this order:

1. Console region matches `%REGION%`
2. Dimension group is **Broker ID, Cluster Name**, not cluster-level only
3. Monitoring level is at least **`PER_BROKER`** — `CpuIdle` and `KafkaDataLogsDiskUsed` do not exist below it
4. You have generated load in this lab session, and 2 to 3 minutes have passed

Command reference: [commands.md](commands.md).
