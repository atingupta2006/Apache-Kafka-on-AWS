# Day 1 — Kafka basics and Amazon MSK

**Today’s goal:** Learn how Kafka stores messages, how your Windows lab connects to Amazon MSK, and complete a **happy path**: connect → list topics → describe → produce → consume.

You will use the **AWS Console**, the **AWS CLI**, and Kafka **`.bat`** tools in **Windows 10 Command Prompt (CMD)**. Step-by-step commands are in [commands.md](commands.md). This file explains the ideas.

**CMD each lab day:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

Do not use PowerShell for Kafka commands — use CMD only (see [README.md](../README.md)).

---

## Before you start — your seat identity

Each person has an AWS login id such as **`user1`**, **`user2`**, **`user3`**, and so on.

Use that **same id** in every place:

| What | Example if you are `user3` |
|------|----------------------------|
| AWS Console / CLI login | `user3` |
| Username in the password file | `user3` |
| Your topic | `orders-user3` |
| Your consumer group | `cg-user3-support` |

If you are `user1`, use `orders-user1` and `cg-user1-support`. Work only on **your** topic and group.

You will be given:

- **AWS Console:** [vinsys23-7 sign-in](https://vinsys23-7.signin.aws.amazon.com/console) (login `userN`)
- Region: **`ap-south-1`**
- Cluster ARN and bootstrap (also in `scripts/lab-defaults.bat` — press **Enter** in `start-lab.bat` to accept)
- Bootstrap must be **one** host ending in **`:9196`** with `-public` in the name (no commas)
- Your SCRAM **password**

**Fast lab setup** (full click / download steps in [commands.md](commands.md)):

1. **Setup §0** — install JDK 21, AWS CLI v2, Git, **7-Zip**, and Kafka 3.8.1 under `C:\kafka\...` (use 7-Zip in CMD — not `tar`)  
2. **Setup §A** — create AWS access keys and run `aws configure`  
3. **Setup §B** — clone the course and run `start-lab.bat`

Later windows (no questions):

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

---

## What is Apache Kafka? (simple picture)

Think of Kafka as a **shared notebook** that many systems write to and read from.

- A **producer** = an app that **writes** a line into the notebook.
- A **topic** = one named notebook (for example `orders-user1`).
- A **consumer** = an app that **reads** lines from that notebook.
- A **broker** = a server that stores the notebook pages.

When one consumer reads a message, the message stays in Kafka. Other consumer groups can still read it later. Kafka keeps a history for a while; it does not remove a message only because someone read it once.

```
Producer writes  -->  Topic (stored on brokers)  -->  Consumer reads
```

---

## Why support engineers care

Tickets often sound like:

- “Orders are not arriving.”
- “The app cannot connect.”
- “Lag is going up.”

Those tickets connect to ideas you learn today: **topic**, **partition**, **offset**, **consumer group**, **broker**, and “can my Windows PC reach MSK?”

Before you change something on a real ticket, decide **where** to look first:

| Where | Ask yourself |
|-------|----------------|
| The app / client | Right bootstrap address? Right user and password? |
| The network path | Can this Windows machine reach port **9196**? |
| Kafka data | Does the topic exist? Correct topic name? Is the group behind (lag)? |
| AWS / MSK | Is the cluster **Active** in the AWS Console? |

---

## Topics and partitions

A **topic** is a named place where messages are stored (your lab topic looks like `orders-user1`).

A topic is split into **partitions**. A partition is one ordered list of messages.

```
Topic orders-user1
  partition 0:  message at offset 0, 1, 2, 3, ...
  partition 1:  message at offset 0, 1, 2, ...
  partition 2:  message at offset 0, 1, 2, 3, 4, ...
```

**Order** is guaranteed **inside one partition**. Messages in partition 0 and partition 1 are not in one single global order.

Why partitions exist: so several consumers in the **same group** can share the work (each member of the group gets some partitions).

**In today’s lab** you **list** topics and **describe** your topic so you can see partitions, leaders, and copies. Your topic is already ready for you to use.

---

## Producers and consumers

A **producer** sends a message to a topic. It must:

1. Know the **bootstrap** address (the broker host list your tools connect to first).
2. **Log in** (in our lab: username + password on a secure connection).
3. Get a success reply that the write worked (often called an **ack**).

A **consumer** reads messages. It remembers progress with an **offset** — a number that means “I have finished up to here.”

If **sending** fails, the message may not be saved yet — or the app timed out and you need to check again.

If **reading** looks empty, check these common causes first:

- Wrong **topic** name.
- Wrong **group** name.
- The consumer is waiting at the **end** of the topic, and a **new** message has not been sent yet.

---

## Consumer groups

A **consumer group** is a named team of consumers that share one topic.

Kafka gives each partition to **one** member of that group at a time. That way two members in the same group do not process the same partition together.

```
Topic with 3 partitions
  group cg-user1-support
    member A  ->  partition 0
    member B  ->  partition 1
    member C  ->  partition 2
```

A **second** group on the same topic keeps its **own** progress (its own offsets). Another team’s reading does not move **your** group’s offsets.

If you have not started a consumer with your group name yet, that group may be missing from `--list`. After you consume once with `--group ...`, the group shows up.

---

## Brokers and replicas

A **broker** is one Kafka server in the cluster. Your lab cluster has **3** brokers.

Each partition has:

- One **leader** broker (clients write and read that partition through the leader).
- **Replicas** on other brokers (copies for safety).

**Replication factor (RF)** = how many copies of each partition exist. In this lab RF is **3** (one leader + two copies).

**ISR** means “in-sync replicas” — the copies that are up to date. On a healthy lab topic, the ISR list should show **all** of those copies.

On MSK you check health with:

- AWS Console or `aws kafka describe-cluster` — is the cluster **Active**?
- `kafka-topics.bat ... --describe` — leaders, replicas, and ISR

---

## Message flow and offsets (happy path)

1. The producer sends a message to the **leader** of a partition.
2. The leader saves it. The other copies update.
3. The producer gets a success reply (when the settings ask for one).
4. A consumer in your group **reads** messages starting from its saved offset.
5. After it finishes a message, it **saves a new offset** (“I am done up to here”).

Offsets are separate for each **group + topic + partition**.

- A low offset (like **0**) is near the oldest message still kept on disk.
- The **end** of the topic is where the next **new** message will be written.

**Lag** means: how many messages are still waiting for your group.

Today, after you produce and consume, run `--describe` on your group. When the consumer has caught up, lag is usually **0** or very small.

---

## Message lifecycle (what “missing message” often means)

| Stage | What it means |
|-------|----------------|
| Sent (produced) | The app got a success reply — or it timed out and you need to verify |
| Stored | The message is on the broker disk |
| Copied (replicated) | Other brokers also have the message |
| Readable | Consumers can read that message |
| Still kept (retained) | Kafka still has it (until time or size limits apply) |
| Deleted | Old data was removed by retention |

If a message seems missing, check first: wrong topic, wrong group, or the consumer is waiting at the end while no new message was sent.

---

## What is Amazon MSK?

**MSK** = Managed Streaming for Apache Kafka. AWS runs the Kafka brokers for you inside a **VPC** (a private AWS network).

Your lab Windows PC / VM connects to MSK like this:

```
Windows lab client
   -- secure connection + username/password (SCRAM) -->
MSK brokers on port 9196
(host names include "-public")
```

**Lab connection details to use:**

| Item | Value |
|------|--------|
| Port | **9196** |
| Auth | Username + password (SCRAM) in `client-scram.properties` |
| Bootstrap | Host names containing `-public`, on port **9196** |

**AWS runs:** the broker machines, the Kafka software, the disks, and many updates.

**You work with:** firewall rules (security groups), public access, usernames and passwords, topic names, group names, and correct client settings.

---

## How you connect from Windows (Day 1 tools)

1. **AWS Console** — confirm cluster state **Active**; copy bootstrap if needed.
2. **AWS CLI** — `describe-cluster`, `get-bootstrap-brokers`.
3. **Kafka `.bat` tools** under `C:\kafka\kafka_2.13-3.8.1\bin\windows`.
4. **Password file** `%USERPROFILE%\client-scram.properties` (username + password).

How to create the password file: run `start-lab.bat` once (see [commands.md](commands.md)).

**If connect fails — check these first:**

| What you see | What to check |
|--------------|----------------|
| Command hangs a long time | Confirm `BOOTSTRAP` is a `-public` host on port **9196**, not the private `9096` endpoint |
| Login / SASL error | Username and password in `client-scram.properties` (no leftover `<password>` text) |
| Login error after pasting a long bootstrap string | Confirm you pasted the **9196** SCRAM bootstrap, not the **9098** IAM one |

---

## What you will practice today (happy path)

Follow [commands.md](commands.md) in order:

0. Paste `start-lab.bat` once (or `set-kafka-lab.bat` if you already ran setup). See [commands.md](commands.md).  
1. Confirm AWS identity and cluster **Active**; **list** topics.  
2. **Describe** your topic (`orders-userN`).  
3. Run topic config describe.  
4. List / describe your consumer group (it may appear after you consume).  
5. Start a consumer, produce a few lines, then describe the group again.

**Success today looks like:**

- `--list` finishes in a few seconds and shows **your** topic. You might also see `orders-demo`. The list you see is the list your account is allowed to see.
- `--describe` shows **3** partitions, **3** copies (RF 3), and a healthy ISR (all copies listed).
- Messages you type in the producer window appear in the consumer window.
- After you consume, group `--describe` shows your group.

---

## Assignment

Fill in [samples/assignment-topic-card.md](samples/assignment-topic-card.md) using **your** topic and group.

Use short answers from `--describe` and group describe. One sentence for message flow is enough.
