# Day 2 — Commands (do these in order)

**Platform:** Windows 10 **Command Prompt (CMD) only** for every command below.

**Easier option:** [lab.ipynb](lab.ipynb) — CMD cells + **log reading guide** ([README-lab.md](README-lab.md)).

**Open CMD:** Start → type `cmd` → Enter. Do **not** use PowerShell for Kafka or lab `.bat` scripts.

**How you connect:** bootstrap with `-public` and port **9196**, plus `%USERPROFILE%\client-scram.properties` from Day 1.

Read [notes.md](notes.md) for explanations. This file is the **step-by-step lab**.

**Each lab window — paste first:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

---

## Setup — copy and paste

Do AWS credentials first if `aws sts get-caller-identity` fails — see [day-01/commands.md](../day-01/commands.md) **Setup §A**.

**One-time clone** (if needed):

```bat
cd %USERPROFILE%
git clone https://github.com/atingupta2006/Apache-Kafka-on-AWS.git
```

**Once per VM** (if you have not run setup yet):

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\start-lab.bat
```

**Every lab window:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

No questions on the second command. New terminal → paste `set-kafka-lab.bat` again.

**Quick check:**

```bat
echo %TOPIC% %GROUP%
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

**Expect:** your topic/group names, then a topic list in a few seconds.  
**If it hangs or returns an authentication error:** confirm `%BOOTSTRAP%` is a `-public` host on port 9196, and that your SCRAM password file matches your login.

---

## 1. Diagnose consumer lag

Describe your group:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

Describe your topic:

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

**Expect:** a table with partitions. Note for each partition:

- **CURRENT-OFFSET** — where your group last saved progress  
- **LOG-END-OFFSET** — end of the log  
- **LAG** — how many messages are still waiting  

Also note leaders / replicas / ISR from topic describe.

**If the group is missing or empty:** that can happen if you never consumed with this group yet. Continue to lab 4 (recover), then describe again.

**Write down:** one sentence — is lag 0, growing, or large and stuck?

---

## 2. Analyze application logs

Read the sample logs in **CMD** (`type` shows the whole file):

```bat
cd %USERPROFILE%\Apache-Kafka-on-AWS\day-02
type samples\producer-error.log
```

```bat
type %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\consumer-error.log
```

**Expect:** readable log lines with timestamps.

**From the producer sample, record:**

- Exception / error type (for example timeout)  
- Topic name in the log  
- Timestamp of the failure  
- Whether retry lines appear **before** the final error  

**From the consumer sample, record:**

- Group id  
- Any poll timeout / commit failed / disconnect lines  

Mine key lines:

```bat
findstr /i "WARN ERROR TimeoutException NOT_LEADER retry" %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\producer-error.log
```

```bat
findstr /i "WARN ERROR poll timeout CommitFailed Disconnect" %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\consumer-error.log
```

Correlate log times with Day 3 metrics window **10:15–10:30 UTC**.

You will paste these into the assignment.

---

## 3. Investigate broker health

Cluster state:

```bat
aws kafka describe-cluster --cluster-arn %CLUSTER_ARN% --region %REGION% --query "ClusterInfo.{State:State,Brokers:NumberOfBrokerNodes}" --output table
```

**Expect:** State **ACTIVE**, broker count **3** (for this class cluster).

Topic health again:

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

**Expect:** for each partition, compare **Replicas** and **Isr**.  
If Isr lists fewer brokers than Replicas, that partition is **under-replicated**.

Confirm bootstrap DNS from the lab VM (hostname from `%BOOTSTRAP%` — text before `:9196`):

```bat
for /f "tokens=1 delims=:" %%a in ("%BOOTSTRAP%") do set BROKER_HOST=%%a
echo Resolving %BROKER_HOST%
nslookup %BROKER_HOST%
```

**Expect:** DNS answers with **Address(es)**.

Under-replication — saved example output:

```bat
type %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\topic-describe-urp-snippet.txt
```

Optional — refresh bootstrap from AWS:

```bat
aws kafka get-bootstrap-brokers --cluster-arn %CLUSTER_ARN% --region %REGION%
```

Confirm your `BOOTSTRAP` is still a **`-public`** host on port **9196**. From outside the VPC that is the only listener that works; the private `:9096` string times out with no explanatory error.

Optional — connectivity failure reference:

```bat
type %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\wrong-bootstrap-expect.txt
```

Optional — fast local failure (nothing listening; may take ~30s):

```bat
kafka-topics.bat --bootstrap-server 127.0.0.1:9196 --command-config %CLIENT% --list
```

---

## 4. Recover a stopped consumer

### 4.1 Describe before recover

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**Expect:** maybe no active member, or lag on some partitions. Note the LAG values.

### 4.2 Terminal A — start consumer (leave running)

Kafka’s Windows `kafka-console-consumer.bat` breaks with `--group`. Use the course helper:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat
```

**Expect:** window waits for messages. Keep it open.

### 4.3 Terminal B — produce a marker

In a **second** terminal, paste:

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

Then:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat recover-probe
```

(One line — no need to type inside an interactive producer.)

Then `Ctrl+C` to stop the producer.

**Expect in Terminal A:** the line `recover-probe` appears.

### 4.4 Describe after recover

Stop the consumer with `Ctrl+C` in Terminal A (optional after you see the line), then:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**Expect:** LAG on partitions you consumed is **0** or lower than before.

**If the consumer shows nothing:** confirm both terminals use the same `%TOPIC%` and `%GROUP%`; produce again while the consumer is still running.

---

## Assignment

Open [samples/assignment-incident.md](samples/assignment-incident.md).

Fill every section using:

- Sample producer and consumer logs  
- Your group / topic describe output from today’s labs  

Keep answers short and clear.

---

## Quick troubleshooting (Day 2)

| Problem | What to check |
|---------|----------------|
| Wrong shell | Use **CMD**, not PowerShell |
| `--list` / describe hangs | `BOOTSTRAP` has `-public` and **9196** |
| Auth error | Day 1 password file username + password |
| Group missing | Run lab 4 consume once with `%GROUP%` |
| No `recover-probe` in consumer | Consumer started first? Same topic? Use `consume.bat` / `produce.bat` |
| `The syntax of the command is incorrect.` on consumer | Use `scripts\consume.bat` (not `kafka-console-consumer.bat` with `--group`) |
| `nslookup` fails | Hostname spelling; work on the lab VM network |
| Unsure about ISR | Compare `Isr` with `Replicas` on one partition — equal means fully replicated |
