# Day 4 — Commands

**Where you work:** your own Windows 10 PC / VM (same machine as Days 1–3).  
**Shell:** **Command Prompt (CMD) only** — not PowerShell.  
**Theory:** [notes.md](notes.md). Optional Jupyter: [lab.ipynb](lab.ipynb) (same steps).

Prefer **AWS Console** for cluster/IAM checks: [samples/msk-iam-console.md](samples/msk-iam-console.md).  
Kafka produce/consume/ACL/offset work stays on **CMD**.

This class cluster already has **SCRAM + IAM** (ports **9196** / **9198**). You do not create MSK in class.

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

**Hard rules**

- Reset offsets only on **your** `%GROUP%` + `%TOPIC%`.
- ACL experiments only on **`%ACL_TOPIC%`**.
- Close any running `consume.bat` before offset reset.

---

## 1. Review topic configuration

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

**Stop consumers first.**

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

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

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --from-beginning --max-messages 25 --timeout-ms 60000
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**If LAG still > 0:** run the same `consume.bat` line again.

---

## 4a. SCRAM ACLs on `%ACL_TOPIC%`

Work only on **`%ACL_TOPIC%`** (`acl-lab-userN`).

**How this lab mirrors production:** app teams produce/consume and diagnose errors. A **platform / ops** change to Kafka ACLs can break Write even when your SCRAM login still works. In class, the instructor applies that platform change during short **WAIT** pauses (often screen-shared). You keep the same client file and only run the produce/list steps below.

### Steps

**A — list**

```bat
kafka-acls.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list --topic %ACL_TOPIC%
```

**B — produce OK**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-ok
```

**WAIT** until the instructor says **GO DENIED** (platform Deny Write is in place for your seat).

**C — produce must fail**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-denied-test
```

**Expect:** `TopicAuthorizationException` (auth succeeded; Write was denied). Read the error text.  
Optional: `--list` again and look for a **Deny** on Write for `User:%LOGIN%`.

**WAIT** until the instructor says **GO RESTORED** (Deny removed).

**D — produce OK again**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-restored
```

**Learning:** only the ACL changed. Offset reset would **not** fix `TopicAuthorizationException`.  
AWS Console admin ≠ SCRAM permission to edit Kafka ACLs — that is a separate platform step (what the instructor just demonstrated).

---

## 4b. IAM listener (same Windows PC)

### One-time prep (if not done on Day 1)

```bat
copy %USERPROFILE%\Apache-Kafka-on-AWS\day-04\samples\client-iam.properties.example %USERPROFILE%\client-iam.properties
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\install-iam-jar.bat
dir C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar
```

Confirm `aws configure` already works on this PC. Optional Console check: [samples/msk-iam-console.md](samples/msk-iam-console.md).

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

With **admin** AWS users this usually lists topics. If it errors, paste the error for the trainer — SCRAM sections are still complete.  
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
| ACL produce denied before GO DENIED | Wait for instructor; do not change offsets |
| IAM jar missing | `install-iam-jar.bat` |
| Hang | Confirm `-public:9196` or `:9198`, not private `:9096` |
