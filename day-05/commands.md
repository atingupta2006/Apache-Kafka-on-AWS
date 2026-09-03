# Day 5 — Commands

**Where you work:** your own Windows 10 PC / VM (same as Days 1–4).  
**Shell:** **Command Prompt (CMD) only**.  
Optional Jupyter: [lab.ipynb](lab.ipynb). Theory: [notes.md](notes.md).

SCRAM unless a step says IAM. Public **9196** / **9198** only.  
Label evidence **`[log]`** (sample files) vs **`[live]`** (commands you run now).  
For CloudWatch metrics/logs, prefer **AWS Console** (Day 3 style) over AWS CLI.

**Each lab window — paste first:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

`CLIENT_IAM` is included after you run the latest `start-lab.bat`.

This sets `TOPIC`, `GROUP`, `ACL_TOPIC`, `BOOTSTRAP`, `BOOTSTRAP_IAM`, `CLUSTER_NAME`, `CLIENT`, and Kafka `PATH`.

**Your ids:** login `userN` → `orders-userN` / `cg-userN-support` / `acl-lab-userN` / `User:userN`.

`BOOTSTRAP` = **public SASL/SCRAM** (**9196**). `BOOTSTRAP_IAM` = **public IAM** (**9198**) when needed.

---

## Scenario 1 — Deployed applications

```bat
type %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\producer-error.log
```

```bat
type %USERPROFILE%\Apache-Kafka-on-AWS\day-02\samples\consumer-error.log
```

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat s1-probe
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat
```

Confirm `s1-probe` (and drain). Ctrl+C. Describe the group again.

Then check the broker side in the **AWS Console**, as on Day 3:

| Metric | Console path | Dimensions |
|--------|--------------|------------|
| `CpuIdle` | CloudWatch → Metrics → `AWS/Kafka` | Broker ID, Cluster Name |
| `KafkaDataLogsDiskUsed` | same | Broker ID, Cluster Name |

Statistic **Average**, Period **1 minute**, time range **Last 1 hour**.

The attached sample logs are from an earlier incident, so CloudWatch holds nothing for their exact timestamps. What matters for the ticket is whether the cluster is healthy **while your own probe succeeds** — healthy metrics plus a successful probe is a complete answer to "is Kafka the problem?"

---

## Scenario 2 — Infrastructure and performance

```bat
aws kafka describe-cluster --cluster-arn %CLUSTER_ARN% --region %REGION% --query "ClusterInfo.{State:State,Brokers:NumberOfBrokerNodes}" --output table
```

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

```bat
aws kafka get-bootstrap-brokers --cluster-arn %CLUSTER_ARN% --region %REGION%
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

```bat
for /f "tokens=1 delims=:" %%a in ("%BOOTSTRAP%") do set BROKER_HOST=%%a
echo Resolving %BROKER_HOST%
nslookup %BROKER_HOST%
```

(Resolves hostname from `%BOOTSTRAP%` — text before `:9196`.)

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

Check `CpuIdle` and `KafkaDataLogsDiskUsed` per Broker ID in the **AWS Console**, time range **Last 1 hour**.

| Finding | Meaning | Your action |
|---------|---------|-------------|
| `CpuIdle` low on **one** broker | Leadership or partition skew | Recommend rebalancing leadership |
| `CpuIdle` low on **all** brokers | Genuine capacity shortage | Escalate to infrastructure with the numbers |
| Disk above 80% | Retention exceeds what the volume can hold | Escalate capacity; review retention |
| Everything healthy | The cluster is not the problem | Say so, and point at the evidence |

**Restore:** if the group has no active members, start `consume.bat` on `%GROUP%` and produce `s2-restore` to prove the path works. You do not resize brokers — you provide the measurement that justifies it.

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat s2-restore
```

---

## Scenario 3 — Missing messages and reprocessing

Dry-run **only** first. Stop any active consumer in `%GROUP%` before `--execute` if the CLI refuses the reset. Reset **only** your own group/topic (`cg-userN-support` / `orders-userN`).

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

```bat
kafka-configs.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --entity-type topics --entity-name %TOPIC% --describe
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --topic %TOPIC% --reset-offsets --to-earliest --dry-run
```

Only after you read the dry-run output:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --topic %TOPIC% --reset-offsets --to-earliest --execute
```

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --from-beginning
```

Validate with `--describe` after consume.

---

## Scenario 4 — Security and configuration

Wrong listener (authentication):

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP_IAM% --command-config %CLIENT% --list
```

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

TLS on the public SCRAM port (**9196**): a successful `--list` with `%CLIENT%` on `%BOOTSTRAP%` proves TLS + SCRAM for this lab. (Optional certificate inspection requires Git Bash/openssl — not required on Windows CMD.)

```bat
kafka-acls.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list --topic %ACL_TOPIC%
```

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% s4-probe
```

```bat
set CLASSPATH=C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar;%CLASSPATH%
```

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP_IAM% --command-config %CLIENT_IAM% --list
```

```bat
kafka-configs.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --entity-type topics --entity-name %TOPIC% --describe
```

If produce to `%ACL_TOPIC%` fails, `--list` ACLs, remove deny (Day 4 section 4a), then:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% s4-restored
```

---

## Scenario 5 — End-to-end

```bat
type %USERPROFILE%\Apache-Kafka-on-AWS\day-05\samples\scenario-5-app.log
```

Note: this sample log covers roughly **16:02 to 16:09** on a past date, so CloudWatch has nothing for those exact minutes. Read the log for what the application experienced, and use live commands plus a **Last 1 hour** CloudWatch view for the cluster's condition now. Keep the two clearly labelled and do not force one onto the other.

Then run, in order, the evidence commands you need from Scenarios 1–4 (cluster state, topic describe, group describe, ACL list, optional CloudWatch). Make **one** restore action only:

- restart your `%GROUP%` consumer (`consume.bat`), **or**
- remove ACL deny on `%ACL_TOPIC%`, **or**
- offset reset: **dry-run then execute** on your own group (same commands as Scenario 3)

Not all three unless evidence clearly requires more than one change.

Validate:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat s5-validate
```

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat
```

Confirm `s5-validate`. Ctrl+C.

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

---

## Best practices

Live checks:

```bat
aws kafka describe-cluster --cluster-arn %CLUSTER_ARN% --region %REGION% --query "ClusterInfo.State" --output text
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

Walk [samples/ops-checklist.md](samples/ops-checklist.md) once at the end of the day.

---

## Quick troubleshooting (Day 5)

| Problem | What to check |
|---------|----------------|
| Wrong shell | Use **CMD**, not PowerShell |
| Consumer syntax error | Use `consume.bat`, not `kafka-console-consumer.bat --group` |
| Log read fails | Use full path with `type ..\day-02\samples\...` or `cd` to day folder |
| IAM list fails | `CLIENT_IAM`, `CLASSPATH`, port **9198** |
