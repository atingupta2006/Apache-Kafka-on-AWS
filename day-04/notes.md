# Day 4 — Security, configuration, and message recovery

Days 2–3 found *what* broke. Today you handle **who is allowed**, **what the topic keeps**, and **how to replay** without making a second incident.

**Class path:** your own Windows PC + [commands.md](commands.md).  
IAM Console verify (if needed): [samples/msk-iam-console.md](samples/msk-iam-console.md).

Reset offsets only on **your** assigned group and topic (`cg-userN-support` + `orders-userN`). Do not reset a shared group, or a group belonging to another seat.

---

## Authentication in AWS MSK

This cluster has two authenticated listeners, both TLS:

| Listener | Lab port (off-VPC clients) | Client file | Identity |
|----------|----------------------------|-------------|----------|
| SASL/SCRAM | Public **9196** | `%USERPROFILE%\client-scram.properties` | Kafka SCRAM user (Secrets Manager) |
| IAM | Public **9198** | `%USERPROFILE%\client-iam.properties` | AWS principal (`aws configure`) |

Lab Windows clients are **outside the MSK VPC**, so they use **public** listeners only. Private **9096/9098** are for in-VPC apps — not the lab path.

**This class cluster already has IAM + SCRAM enabled** (SG **9196** / **9198**). Students do not create MSK in class. Verify/enable steps for other clusters: [samples/msk-iam-console.md](samples/msk-iam-console.md).

**AWS admin vs Kafka ACL edit:** Console admin does not mean SCRAM `userN` can change ACLs. In this course the instructor applies Deny/Remove during Day 4 WAIT pauses (platform step). Students diagnose the produce failure.

Authentication failure: Kafka does not know **who you are** (bad password, wrong mechanism, wrong bootstrap). You never reach ACL or IAM policy evaluation in a useful way.

(Trainer note — Secrets Manager SCRAM secrets use names like `AmazonMSK_userN` and need a customer KMS key. Students do not configure this in the lab.)

PLAINTEXT is not enabled. Port 9092 will hang or reset.

---

## Authorization using Access Control Lists (ACLs)

After SCRAM auth succeeds, **Kafka ACLs** decide allow/deny on CLUSTER, TOPIC, GROUP.

`kafka-acls.bat` lists and changes ACLs. Principal form: `User:<your-principal>` — for this class that is `User:user1`, `User:user2`, … matching your AWS login id.

Example: login `user3` → ACL principal `User:user3` → ACL lab topic `acl-lab-user3`.

A produce error `TopicAuthorizationException` is **authorization**, not a timeout. Fixing it with `--reset-offsets` does nothing.

Use the ACL lab topic assigned to you (`acl-lab-userN`), not your main orders topic unless told.

In the hands-on, a short **WAIT** means the instructor (platform role) applied or removed a Deny Write. That matches production: ops changes ACLs; support engineers diagnose the client error.

---

## SSL/TLS overview

MSK authenticated listeners wrap SASL in TLS (`SASL_SSL`). The client trusts Amazon CAs (default JVM/truststore on the Windows lab client is enough).

TLS problems look like handshake failures or hostname verification errors, not `SaslAuthenticationException`. A successful `--list` using `SASL_SSL` proves TLS plus SCRAM for this lab. Optional certificate inspection with `openssl` (Git Bash) is covered in Day 5 — not required on Windows CMD.

---

## IAM authentication overview

IAM listener uses AWS SigV4 via `aws-msk-iam-auth`. Authorization is **IAM policies** (`kafka-cluster:Connect`, `kafka-cluster:WriteData`, topic ARNs), **not** `kafka-acls.bat`.

You cannot “see” IAM denies in `kafka-acls.bat --list`. You see Access Denied in client logs.

Day 1–3 did not use this listener. Mixing the IAM bootstrap (`:9198` public) with `client-scram.properties` fails with `UnsupportedSaslMechanismException` (server has `OAUTHBEARER, AWS_MSK_IAM`, not SCRAM). That is not a bad password.

CLASSPATH for the IAM jar on Windows (typical): `C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar`.

---

## Troubleshooting authentication failures

| Signal | Likely |
|--------|--------|
| `SaslAuthenticationException` on **9196** | Wrong SCRAM secret or username |
| `UnsupportedSaslMechanismException` on IAM port | IAM bootstrap + SCRAM client file |
| IAM: `Failed to create new Connection` / AWS error | Role missing `kafka-cluster:Connect`, or clock/credentials |
| Hang | SG, not auth |

---

## Troubleshooting authorization failures

| Signal | Likely |
|--------|--------|
| `TopicAuthorizationException` | ACL deny or missing ACL on that topic |
| IAM produce/consume fail after connect works | Policy missing WriteData/ReadData on topic ARN |
| Group join fail | ACL on GROUP or IAM `Connect`/`AlterGroup` |

Deny + allow both exist: **deny wins**.

---

## Topic configuration parameters

`kafka-configs.bat --describe` / `kafka-topics.bat --describe`. Support-relevant: `retention.ms`, `retention.bytes`, `min.insync.replicas`, `unclean.leader.election.enable`, `max.message.bytes`, `cleanup.policy`.

Do not change topic config unless the lab says so. Confirm current values with describe first.

---

## Retention policies

Records leave the log when **time** or **size** retention hits, per partition. Consumers cannot read deleted offsets. That is not a producer failure.

Broker defaults are often `log.retention.ms` / `log.retention.bytes`. Topic `retention.ms` / `retention.bytes` **override** those. If `kafka-configs.bat --describe` dynamic config is empty, the topic is still on broker defaults — not “unconfigured.”

`retention.ms=604800000` ≈ 7 days. If the app commits weekly and you replay “from yesterday” after 8 days, the data is gone.

---

## Common configuration settings used during troubleshooting

| Setting | Why you look |
|---------|----------------|
| `min.insync.replicas` vs ISR | `acks=all` timeouts |
| `unclean.leader.election.enable` | Possible loss after election |
| `retention.ms` | “Missing” old messages |
| `auto.offset.reset` | New group behaviour |
| `acks` / `delivery.timeout.ms` | Producer logs (Day 2) |

---

## Configuration validation

Describe **before** and **after** any change. Screenshot or paste ISR, RF, retention. If validation is “we restarted the consumer,” that is not config validation.

---

## Investigating missing messages

Decision tree:

1. Never produced? Producer log / no ack.
2. Produced, wrong topic/partition? `--describe` + keys.
3. Produced, wrong group? Other group’s offsets moved; yours did not.
4. Produced, offset already past it? Group already committed ahead.
5. Produced, **retention** deleted it? Offset out of range.
6. Produced, consumer bug / filter? Record still in log — consume with `--from-beginning` in a **scratch group**, not by resetting production.

---

## Consumer offset management

Committed offset is the group’s bookmark. `--describe` shows it. Moving it is a **write** to the group.

---

## Resetting consumer offsets

```text
--reset-offsets --to-earliest|--to-latest|--to-offset|--to-datetime
--dry-run   then   --execute
```

Only your assigned `%GROUP%` + `%TOPIC%`. Dry-run must match the partitions you expect (confirm with describe). Execute once.

`--to-earliest` replays **whatever is still retained**, not the entire history of the business.

---

## Message replay techniques

Reset + start consumer. Or consume in a new group `--from-beginning` for investigation without moving production offsets.

Replay can **duplicate** downstream (payments, emails). That is why reprocessing rules exist.

---

## Best practices for message reprocessing

- Freeze or pause producers if you need a stable log end.
- Dry-run offset reset; record old offsets.
- Prefer a replay group for investigation.
- Validate: lag, sample records, downstream count.
- Tell the app team: at-least-once → they must be idempotent.
- Do not reset a shared group “to help a colleague.”
