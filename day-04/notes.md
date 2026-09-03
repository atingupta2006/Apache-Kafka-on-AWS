# Day 4 — Security, configuration, and message recovery

**Class path:** your own Windows PC + [commands.md](commands.md).

---

## Story for today (read once)

You are on a **production-support** desk for a shared Amazon MSK cluster. Several application teams share the brokers. Each team owns:

| What | Example for seat `user3` | Why it exists |
|------|--------------------------|---------------|
| SCRAM login | `user3` | Proves who you are to Kafka |
| Business topic | `orders-user3` | That team’s order stream |
| Support consumer group | `cg-user3-support` | Bookmark for *their* consumer only |
| ACL practice topic | `acl-lab-user3` | Safe place to see authz failures |

Days 2–3 taught you to find *what* broke (lag, brokers, bad clients). Today you practice three support skills that often land on the same ticket:

1. **Configuration** — what does this topic keep, and for how long?  
2. **Message recovery** — move *this* group’s bookmark carefully and replay.  
3. **Security** — is the failure “wrong password” (authn) or “not allowed” (authz)? And which **front door** did the app use — SCRAM or IAM?

### Why your seat is isolated

Offset reset is a **write to the consumer group**, not a private notebook setting. If you reset `cg-user5-support` while helping yourself, you rewind **user5’s** production-style consumer. That looks like a missing-message incident for them — and you created it.

Same idea for ACLs: experimenting on `orders-userN` could break the path you need for replay. The lab uses `acl-lab-userN` so authz practice stays off the recovery path.

So when materials say “use your `%GROUP%` and `%TOPIC%`,” the background is: **one cluster, many teams — only touch the workload you own.**

---

## Authentication in AWS MSK

This cluster has two authenticated listeners, both TLS:

| Listener | Lab port | Client file | Identity |
|----------|----------|-------------|----------|
| SASL/SCRAM | Public **9196** | `%USERPROFILE%\client-scram.properties` | Kafka SCRAM user |
| IAM | Public **9198** | `%USERPROFILE%\client-iam.properties` | AWS principal (`aws configure`) |

Lab Windows clients sit **outside** the MSK VPC, so they use these **public** ports. Private ports (**9096** / **9098**) are for in-VPC apps — not the lab path.

**Authentication** failure: Kafka does not know **who you are** (bad password, wrong mechanism, wrong bootstrap). You never reach a useful ACL or IAM-policy decision.

Your SCRAM password is already in `client-scram.properties`. PLAINTEXT is not used on this cluster — port **9092** will hang or reset.

Optional: glance at public bootstrap ports in Console — [samples/msk-iam-console.md](samples/msk-iam-console.md).

---

## Authorization using Access Control Lists (ACLs)

After SCRAM auth succeeds, **Kafka ACLs** decide allow/deny on CLUSTER, TOPIC, GROUP.

`kafka-acls.bat` lists ACLs. Principal form: `User:<login>` — for this class `User:user1`, `User:user2`, … matching your login id.

Example: login `user3` → principal `User:user3` → ACL practice topic `acl-lab-user3`.

A produce error `TopicAuthorizationException` is **authorization**, not a timeout. Resetting offsets does not fix it — the bookmark is fine; Write was refused.

**Lab background:** keep `orders-userN` for config + reset + replay. ACL deny/restore practice uses `acl-lab-userN` only.

In production, **ops / platform** often changes ACLs while support keeps the same client and diagnoses the error. In the hands-on, short **WAIT** pauses mean that kind of ACL change has been applied or removed for your seat — then you produce again and read the result.

AWS Console admin rights are **not** the same thing as permission for SCRAM user `userN` to change Kafka ACLs.

---

## SSL/TLS overview

MSK authenticated listeners wrap SASL in TLS (`SASL_SSL`). The client trusts Amazon CAs (default JVM/truststore on the Windows lab client is enough).

TLS problems look like handshake failures or hostname verification errors, not `SaslAuthenticationException`. A successful `--list` using `SASL_SSL` proves TLS plus SCRAM for this lab. Optional certificate inspection with `openssl` (Git Bash) is covered in Day 5 — not required on Windows CMD.

---

## IAM authentication overview

### Story: why teams add IAM (and what is awkward about SCRAM-only)

Imagine the company started on MSK with **SCRAM only**: every app and every support engineer gets a Kafka username/password from Secrets Manager. That works for Days 1–3 style tooling (`kafka-console-producer`, scripts with `client-scram.properties`).

Tickets that keep showing up on a SCRAM-only cluster:

| Pain | What support sees |
|------|-------------------|
| Password sprawl | Many SCRAM users; rotation means updating Secrets Manager **and** every client file / secret mount |
| “Who is this principal?” | Kafka ACL says `User:orders-svc`, but that is **not** the same identity as the AWS role running the ECS task — two identity systems to audit |
| New AWS-native apps | Lambda, ECS, EKS pods already have an **IAM role**. Asking them for a second SCRAM password is extra glue and another secret to leak |
| Break-glass / automation | CI or a bastion already authenticated to AWS; SCRAM forces a second login path just for Kafka |
| Wrong mental model | Someone with strong **AWS Console admin** still cannot fix a SCRAM ACL the way they fix an IAM policy — different control plane |

So the platform team enables a second listener: **IAM authentication**. Clients prove who they are with **AWS SigV4** (same identity AWS already knows). Authorization for that path is **IAM policies** (`kafka-cluster:Connect`, `kafka-cluster:WriteData`, topic ARNs) — **not** `kafka-acls.bat`.

You cannot “see” an IAM deny in `kafka-acls.bat --list`. You see Access Denied (or similar) in the **client** log.

### Are both SCRAM and IAM required, or is IAM enough?

| Question | Practical answer |
|----------|------------------|
| **Must every cluster run both?** | No. MSK can run SCRAM-only, IAM-only, or **both**. |
| **Is IAM alone enough?** | **Yes**, if *every* producer/consumer can use the IAM listener (AWS SDK / `aws-msk-iam-auth`, roles or users with the right `kafka-cluster:*` actions). Many greenfield AWS-only apps aim for IAM-only. |
| **Why keep SCRAM as well?** | Legacy apps, third-party tools, training/lab scripts, or teams that already standardized on Kafka ACLs + passwords. SCRAM is still a valid production choice — it is not “wrong.” |
| **Why this class cluster has both** | Days 1–3 teach the SCRAM + ACL support path (very common). Day 4 adds the IAM door so you can diagnose **wrong listener / wrong client file** — a frequent real ticket. You are not migrating the whole lab to IAM-only. |

**One sentence for tickets:** pick the listener that matches how the **client authenticates**; do not mix SCRAM properties with the IAM port (or the reverse).

### Lab shape (this cluster)

| Listener | Port | Client file | Authn | Authz |
|----------|------|-------------|-------|-------|
| SCRAM | **9196** | `client-scram.properties` | SCRAM user/password | Kafka **ACLs** |
| IAM | **9198** | `client-iam.properties` + IAM jar | AWS credentials (`aws configure` / role) | **IAM policies** |

Mixing the IAM bootstrap (`:9198`) with `client-scram.properties` fails with `UnsupportedSaslMechanismException` (server expects `OAUTHBEARER` / `AWS_MSK_IAM`, not SCRAM). That is not a bad password — it is the wrong front door.

CLASSPATH for the IAM jar on Windows (typical): `C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar`.

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

Committed offset is the **group’s bookmark** (“how far did *this* consumer group get?”). `--describe` shows it. Moving it is a **write** to that group’s metadata — every member of that group feels the change.

Background for class: your seat runs one support group (`cg-userN-support`) against your topic (`orders-userN`). A colleague’s group name is a different bookmark on the same cluster. Resetting theirs is like editing someone else’s change ticket.

---

## Resetting consumer offsets

Support story: “Orders look missing for *our* consumer.” After you confirm the data is still in the log (retention) and the group already read past it, you may rewind **that** group.

```text
--reset-offsets --to-earliest|--to-latest|--to-offset|--to-datetime
--dry-run   then   --execute
```

| Step | Why |
|------|-----|
| Stop your consumers first | Kafka often refuses reset while the group is active |
| `--dry-run` | Shows the new offsets **without** changing anything — your safety net |
| Check group + topic names | Must be **your** `%GROUP%` + `%TOPIC%` only |
| `--execute` once | Applies the plan you already reviewed |
| Then consume / replay | Moving the bookmark alone does not “replay”; the consumer must read again |

`--to-earliest` in class replays **whatever is still retained**, not the entire history of the business. Real tickets more often use `--to-datetime`.

---

## Message replay techniques

Typical recovery path: reset the **affected** group → start the consumer → validate lag and sample records.

For investigation without touching the production bookmark, consume with a **new scratch group** and `--from-beginning`. That is read-only on the log; it does not rewrite the live group’s offsets.

Replay can **duplicate** downstream work (payments, emails). That is why reprocessing rules and idempotent consumers exist.

---

## Best practices for message reprocessing

- Freeze or pause producers if you need a stable log end.
- Dry-run offset reset; record old offsets before execute.
- Prefer a scratch / replay group when you are only investigating.
- Validate: lag, sample records, downstream count.
- Tell the app team: at-least-once delivery → they must handle duplicates (idempotent processing).
- Never reset another team’s (or another seat’s) group “to help” — on a shared cluster that is a real incident.
