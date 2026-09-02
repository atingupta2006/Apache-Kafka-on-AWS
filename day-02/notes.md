# Day 2 — Producer, consumer, and broker troubleshooting

**Platform:** Windows 10 **Command Prompt (CMD) only** — same as Day 1.

**Today’s goal:** Practice a **support ticket** style of work. Day 1 was the happy path (connect, describe, produce, consume). Today something looks broken. You collect evidence in this order:

1. Application logs  
2. Consumer group (lag and offsets)  
3. Brokers and network path  

Lab steps are in [commands.md](commands.md).

**Your seat (same as Day 1):** login `userN` → topic `orders-userN` → group `cg-userN-support`.

**Start each lab window** — paste:

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

(If that file is missing, run once: `call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\start-lab.bat`)

Course files live in `%USERPROFILE%\Apache-Kafka-on-AWS` after you clone (see [README.md](../README.md)).

---

## How to work a ticket today

A good support habit:

1. Write down the **symptom** (what the user sees).  
2. Open **logs** at the time of the problem.  
3. Check **consumer group** lag for your group.  
4. Check **topic describe** and **cluster Active**.  
5. Check **DNS / bootstrap** from the Windows lab VM.  
6. Only then recommend a fix (restart consumer, fix client settings, escalate broker/disk, and so on).

Today’s labs practice those checks. You **describe** lag and recover by starting a consumer again and producing a test line.

---

## Message publishing failures

A **publish failure** means the producer did not get a success reply (ack) for a message.

Possible cases:

- The message never reached the leader broker.  
- The leader saved it, but the client gave up waiting.

On a ticket:

1. Confirm topic name, bootstrap (**9196** public), and that a simple produce from the Windows lab works.  
2. Read the producer log at the incident time.  
3. Then look at broker / topic health.

If produce from the **lab VM** works but the **application host** fails, the MSK cluster is up. Focus on that app’s config and network path.

---

## Producer timeout issues

A **timeout** means the producer waited too long for an ack (you may see `TimeoutException` or “Expiring N record(s)” in logs).

Common causes:

- Leader is changing (you may also see “not leader” style errors, then timeout).  
- Broker is busy or disk is full (CloudWatch helps later in the course).  
- Network path problems: metadata worked once, then produce hangs.  
- Producer waits for all copies (`acks=all`) while copies are behind.

Timeout is a **symptom**. Read the log lines **before** the timeout (retries, disconnect, not-leader). Those lines point to the cause.

Sample log: [samples/producer-error.log](samples/producer-error.log).

---

## Retry behaviour

Producers often **retry** short problems (brief network blip, leader change).

What logs usually mean:

| What you see | Meaning |
|--------------|---------|
| Retry / disconnect / request timed out, then success | Short problem; client recovered |
| Same error until timeout | Retries used up — treat as an incident |
| Timeouts and then duplicate business data | App may not be safe for retries — talk to the app team |

Retries are for temporary problems. They do not fix a wrong password or a missing topic.

---

## Acknowledgement settings (`acks`)

`acks` is a producer setting. It controls how strong the success reply must be.

| `acks` | Simple meaning | Support note |
|--------|----------------|--------------|
| `0` | Do not wait for ack | Fast; hard to prove the write landed |
| `1` | Leader says OK | Written on the leader; risk if that broker dies before copies finish |
| `all` (or `-1`) | Wait until enough copies are in sync | Safer; more timeouts if copies fall behind |

In this workshop you **read** `acks` from logs or from a config dump the app team gives you. Match the setting to the symptom (for example many timeouts while replicas are out of sync and `acks=all`).

---

## Reviewing producer application logs

Focus on the Kafka producer client log lines.

Useful clues:

- Bootstrap address and topic name  
- Timeout / not-leader / unknown topic  
- Login failures  
- Retry lines before the final error  

Open the sample and note **exception type**, **topic**, **timestamp**, and whether **retries** appear first:

[samples/producer-error.log](samples/producer-error.log)

---

## Common client errors (producer and consumer)

| What the log says (simple) | Typical meaning | First check |
|----------------------------|-----------------|-------------|
| Timeout / expiring records | No ack in time | Leader, ISR, disk pressure, network, `acks` |
| Not leader | Client talked to an old leader | Wait for metadata refresh; check election |
| Disconnect | TCP connection dropped | Network / security group / broker restart |
| SASL / authentication | Bad user or password | Password file; correct bootstrap |
| Authorization | Not allowed on that topic | Permissions for your user |
| Unknown topic | Topic missing or stale metadata | `--list` / `--describe` |
| Record too large | Message bigger than limit | Topic and client size settings |

---

## Matching logs to broker behaviour

Use the **same time window**:

1. Note the timestamp of the first timeout (or disconnect) in the log.  
2. Run topic `--describe` — leader, replicas, ISR.  
3. Run `aws kafka describe-cluster` — is state **Active**?  
4. Compare: if logs show timeouts but ISR is full and cluster is Active, check the **client host** path next.

---

## Consumer lag analysis

**Lag** = how far behind your group is.

```
log-end offset   1050   (newest message position)
current offset    980   (where your group last saved progress)
lag                70   (messages still waiting)
```

| Lag pattern | Often means |
|-------------|-------------|
| Lag growing | Consumer slower than produce, or consumer stopped |
| Lag large and flat | Stuck (crash loop, hard message, waiting on another system) |
| Lag zero | Group caught up (still check the app did the right business work) |

Command you will use:

`kafka-consumer-groups.bat ... --group %GROUP% --describe`

**Lab tip:** Start the consumer **first**, then produce a marker line (lab 4). That way you see the new message arrive.

---

## Consumer group rebalancing

When members join or leave a group, Kafka **reassigns** partitions. Consume pauses for a short time. That is a **rebalance**.

Common triggers: deploy / restart, processing too slow, session timeout, new instance.

In logs you may see: revoke partitions, joined group, new assignment.  
**Repeated** rebalances are the problem to investigate — not a single normal rebalance line.

---

## Offset commit issues

Your group only moves forward when the consumer **saves** (commits) an offset.

If the process dies before commit, a restart may read some messages again (at-least-once). That is expected.

If commit fails around a rebalance, those messages may be delivered again after the group stabilizes.

Today you **observe** offsets and lag with `--describe`. You recover a stopped consumer by starting it again and producing a test message.

---

## Slow consumers

A slow consumer is still in the group, but lag climbs. Causes can include: slow downstream API, large poll batches, garbage collection pauses, or one hot partition (many keys landing on one partition).

Use **your** group for the recovery lab.

---

## Reviewing consumer application logs

Focus on the Kafka consumer client log lines.

Sample: [samples/consumer-error.log](samples/consumer-error.log)

Look for:

- Poll interval warnings (processing took too long)  
- Commit failed  
- Disconnect  
- Leave group / revoke partitions  

---

## Consumer connectivity

Same connection idea as Day 1:

Windows lab VM → port **9196** → public bootstrap (`-public`) → SCRAM password file.

If `--list` works from your lab VM, your path to MSK is healthy. If only another machine fails, compare **that** machine’s bootstrap, security group, and password settings.

---

## Broker availability

Check cluster state:

`aws kafka describe-cluster` → **Active** is healthy for class labs.

If the cluster is creating, deleting, or failed, treat that as an AWS / platform issue.

---

## Leader election (overview)

Each partition has one **leader**. Other brokers hold **copies** (replicas). If the leader broker has a problem, Kafka picks a new leader from the up-to-date copies (ISR).

Clients may briefly see “not leader,” then recover after they refresh metadata.

Healthy `--describe` example shape:

`Leader: 1  Replicas: 1,2,3  Isr: 1,2,3`

---

## Under-replicated partitions (URP)

A partition is **under-replicated** when the ISR list is **shorter** than the full replica list (for example RF = 3 but ISR shows only 2).

Effects: less safety; with `acks=all`, produce may wait or fail if not enough copies are in sync.

Causes: slow replica, disk pressure, network, broker down. Fix the broker/replica health — use describe and (later) metrics to support the story.

---

## Network connectivity

| Symptom | Often means |
|---------|-------------|
| Command hangs a long time | Path / firewall / wrong bootstrap value |
| Quick login error | You reached Kafka; check username/password |

If unsure, confirm `BOOTSTRAP` is a `-public` host on port 9196.

---

## DNS resolution

MSK bootstrap names are **DNS names**, not fixed IPs you type by hand.

From the Windows lab VM:

```bat
nslookup <broker-hostname>
```

Use a hostname from your bootstrap string (the part before `:9196`).  
Expect a successful lookup from the lab network.

---

## Security group (firewall) — what the lab needs

Your Windows lab reaches MSK on **TCP 9196** (SCRAM). The broker security group must allow that from the lab network.

If Day 1 `--list` still works, your lab path through the security group is fine. If something else fails, compare that client’s settings to the working lab path.

---

## Disk usage and retention (awareness)

Full broker disks can slow or block produce, and replicas can fall out of ISR.

**Retention** deletes old message files after time or size limits. That is normal lifecycle, not “Kafka randomly lost a produce.”

Today: use topic `--describe` and cluster state. Disk **percent** metrics are practiced with CloudWatch in a later lab day — use cluster/ISR evidence for Day 2.

---

## What you will practice today

Follow [commands.md](commands.md):

1. Diagnose consumer lag.  
2. Read sample producer and consumer logs.  
3. Check broker / topic health and DNS.  
4. Recover a stopped consumer (start consumer → produce `recover-probe` → describe again).

**Success today looks like:**

- You can explain lag using CURRENT-OFFSET, LOG-END-OFFSET, and LAG.  
- You can point to a timeout / retry / disconnect line in a sample log.  
- Cluster is **Active** and topic ISR looks healthy (or you can say what “under-replicated” means).  
- `recover-probe` appears in the consumer window and lag drops.

---

## Assignment

Fill [samples/assignment-incident.md](samples/assignment-incident.md) using the sample logs and your lab describe output.
