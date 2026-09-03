# Day 4 — Commands

**Where you work:** your own Windows 10 PC / VM (same machine as Days 1–3).  
**Shell:** **Command Prompt (CMD) only** — not PowerShell.  
**Theory / story:** [notes.md](notes.md) — read **Story for today** once before the labs. Optional Jupyter: [lab.ipynb](lab.ipynb) (same steps).

Kafka produce/consume/ACL/offset work is on **CMD**. Optional glance at public ports in Console: [samples/msk-iam-console.md](samples/msk-iam-console.md).

### Lab background (short)

You share one MSK cluster with other seats, like teams sharing production brokers. Your seat owns `orders-userN` + `cg-userN-support`. Offset reset rewrites **that group’s bookmark** — if you point the command at another seat’s group, you create an incident for them.

| Today’s work | Use these | Leave alone |
|--------------|-----------|-------------|
| Config, reset, replay | `%TOPIC%` + `%GROUP%` | Other seats’ groups / topics |
| ACL deny / restore | `%ACL_TOPIC%` only | Do not practice Deny on `%TOPIC%` |
| Before any reset | Stop your own `consume.bat` | — |

---

## Before you start (every CMD window)

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

Check your seat:

```bat
echo LOGIN=%LOGIN% TOPIC=%TOPIC% GROUP=%GROUP% ACL_TOPIC=%ACL_TOPIC%
echo BOOTSTRAP=%BOOTSTRAP%
echo BOOTSTRAP_IAM=%BOOTSTRAP_IAM%
```

**Expect:** `userN`, `orders-userN`, `cg-userN-support`, `acl-lab-userN`,  
`BOOTSTRAP` …**:9196**, `BOOTSTRAP_IAM` …**:9198**.  
If empty → run `scripts\start-lab.bat` once, then `set-kafka-lab.bat` again.

Those four names are *your* team’s slice of the shared cluster. Confirm they match your login before any reset or ACL step.

---

## 1. Review topic configuration

Support story: before you touch offsets, confirm what the topic still holds (RF, ISR, retention defaults).

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

**Expect:** RF=3, full ISR.

Optional (often empty — that is OK; broker defaults still apply):

```bat
kafka-configs.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --entity-type topics --entity-name %TOPIC% --describe
```

---

## 2. Reset consumer offsets

Support story: “Our consumer already passed the messages we need.” You rewind **your** group’s bookmark on **your** topic — same change control you would use in production (dry-run first).

**Stop your consumers first** (Kafka often refuses reset while the group is active).

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

Confirm the line shows **your** `%GROUP%` and partitions for **your** `%TOPIC%` only.

**Dry-run** (nothing changes yet):

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --topic %TOPIC% --reset-offsets --to-earliest --dry-run
```

**Execute** (only after dry-run looks correct):

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --topic %TOPIC% --reset-offsets --to-earliest --execute
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**Expect after execute:** LAG **> 0** (bookmark moved; replay not done yet).  
Lab uses `--to-earliest` to see the effect; real tickets usually use `--to-datetime`.

---

## 3. Replay messages

Moving the bookmark is not enough — start the consumer so it **reads again**. That is the replay.

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --from-beginning --max-messages 25 --timeout-ms 60000
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**If LAG still > 0:** run the same `consume.bat` line again.

---

## 4a. SCRAM ACLs on `%ACL_TOPIC%`

**How this lab mirrors production:** support keeps the same SCRAM client while **ops / platform** changes Write ACLs. Produce can fail with `TopicAuthorizationException` even though login still works. Practice on **`%ACL_TOPIC%`** (`acl-lab-userN`) so the drill does not break your orders recovery path.

### Steps

**A — list**

```bat
kafka-acls.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list --topic %ACL_TOPIC%
```

**B — produce OK**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-ok
```

**WAIT** until the room announces **GO DENIED** (Deny Write is in place for your seat).

**C — produce must fail**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-denied-test
```

**Expect:** `TopicAuthorizationException` (auth succeeded; Write was denied). Read the error text.  
Optional: `--list` again and look for a **Deny** on Write for `User:%LOGIN%`.

**WAIT** until the room announces **GO RESTORED** (Deny removed).

**D — produce OK again**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-restored
```

**Learning:** only the ACL changed. Offset reset would **not** fix `TopicAuthorizationException`.

---

## 4b. IAM listener (same Windows PC)

**Background (why this exists):** SCRAM-only clusters force every app to carry a Kafka password and use Kafka ACLs. Many AWS apps already have an **IAM role** — a second password is awkward to rotate and audit. IAM auth lets those apps use AWS identity on port **9198**, with **IAM policies** for allow/deny.

**Both or only IAM?** Neither is mandatory forever. **IAM alone is enough** if every client can use IAM. **Both** is common during migration and whenever some tools still use SCRAM (this class: Days 1–3 SCRAM, Day 4 also opens the IAM door). Full story: [notes.md](notes.md) — *IAM authentication overview*.

Wrong client file on the IAM port is a common support mistake — you will force that failure once, then list topics the correct way.

### One-time prep (if not done on Day 1)

```bat
copy %USERPROFILE%\Apache-Kafka-on-AWS\day-04\samples\client-iam.properties.example %USERPROFILE%\client-iam.properties
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\install-iam-jar.bat
dir C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar
```

Confirm `aws configure` already works on this PC.

### Required — wrong mix (must fail)

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP_IAM% --command-config %CLIENT% --list
```

**Expect:** `SCRAM-SHA-512 not enabled` / mechanisms `[OAUTHBEARER, AWS_MSK_IAM]`.

### Attempt — correct IAM list

```bat
set CLASSPATH=C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar;%CLASSPATH%
kafka-topics.bat --bootstrap-server %BOOTSTRAP_IAM% --command-config %CLIENT_IAM% --list
```

**Expect:** a topic list (or note the full error text if it fails).  
Do **not** point `%CLIENT_IAM%` at port **9196**.

---

## Assignment

Fill [samples/assignment-recovery.md](samples/assignment-recovery.md).

---

## Quick troubleshooting

| Problem | What to do |
|---------|------------|
| Empty variables | `start-lab.bat` once, then `set-kafka-lab.bat` |
| Reset refused | Stop consumers; dry-run → execute again |
| ACL produce before GO DENIED | Wait for the announcement; do not change offsets |
| IAM jar missing | `install-iam-jar.bat` |
| Hang | Confirm `-public:9196` or `:9198`, not private `:9096` |
