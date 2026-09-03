# Day 4 — Security, configuration, and message recovery

**Platform:** Windows 10 **Command Prompt (CMD)** — same as Days 1–3.

**Today’s goal:** handle the part of a Kafka ticket where you must **change something** — permissions, topic settings, or consumer position — without creating a second incident.

Lab steps are in [commands.md](commands.md).

**Your seat (same as before):** login `userN` → topic `orders-userN` → group `cg-userN-support` → ACL practice topic `acl-lab-userN`.

**Start each lab window** — paste:

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

---

## Story for today

### One cluster, many teams

Picture an online shop. Orders flow through **Amazon MSK** (Kafka managed by AWS).

Several applications share the **same cluster** — the same brokers. Sharing brokers does not mean sharing data:

| Team | Their topic (example) | Their consumer group (example) |
|------|------------------------|--------------------------------|
| Website checkout | `orders.checkout` | `cg-checkout-fulfillment` |
| Warehouse | `orders.warehouse` | its own group |
| Reporting | reads some topics | its own group |

A **consumer group** is a bookmark in a book: *this application has read up to here.* Each team has its own bookmark, even on the same topic.

That is why one rule appears again and again today: work only on **your own** topic and group. If you move another team’s bookmark, their application re-reads old messages or skips new ones. To them it looks like an incident — and it was caused from outside their team.

Applications also need to prove who they are before Kafka accepts them. Some use a **password** (SCRAM). Newer ones use their **AWS identity** (IAM). Both can be switched on at the same time, on different ports. Sending the password settings to the IAM port is one of the most common real-life mistakes, and it produces an error that looks like a wrong password but is not.

### A ticket that arrives on Monday morning

> **Ticket:** “Fulfillment stopped overnight. Lag is high, some orders look missing, and publishing fails now and then. Please reset the offsets to the beginning.”

The application team has already restarted their consumer twice. Nothing improved, so they are asking you for the one action they have heard of.

Resetting offsets first would be a mistake. It changes their live bookmark, it can deliver the same order twice to the systems downstream, and it does nothing at all if the real problem is a permission or a deleted message. So before changing anything, you answer three questions — and those three questions are exactly today’s labs.

**Question 1 — are the messages even still there?**  
Kafka deletes old messages after a time limit, whether anyone read them or not. If the topic keeps seven days of data and the order is nine days old, no reset will bring it back. Reading the topic configuration first tells you whether recovery is possible, so you never promise a fix that cannot work.

**Question 2 — did our own application already read past them?**  
Looking at that team’s group shows where their bookmark sits. If the bookmark is already ahead of the orders in question, Kafka delivered those messages and the problem lives further downstream. If the data is still in the log and only the position is wrong, a careful rewind followed by reading again can replay it — for that one group and topic. Replay is also how the same order reaches the next system twice, so it is planned and announced, not improvised.

**Question 3 — is this really a permission problem?**  
Sometimes publishing fails because the login still works but the account is no longer allowed to write. Sometimes a password change broke the login itself. Sometimes an application was pointed at the wrong port for its type of login. None of these are fixed by restarting the consumer or resetting offsets. Telling them apart needs only the error name, once you know which name belongs to which layer.

Two words separate the last group of problems, and they are worth keeping precise:

| Word | The question it answers | Typical error |
|------|--------------------------|---------------|
| **Authentication** | Who are you? | `SaslAuthenticationException` |
| **Authorization** | Are you allowed to do this? | `TopicAuthorizationException` |

Days 2–3 were about finding *what* broke. Today is about changing things safely and reading security errors correctly.

### How the lab maps to the story

In class you play support for one team on a shared cluster. The names are smaller, the situation is the same:

| In the story | In the lab |
|--------------|------------|
| The checkout service’s login | your login `userN` |
| `orders.checkout` | `%TOPIC%` → `orders-userN` |
| The fulfillment consumer group | `%GROUP%` → `cg-userN-support` |
| A throwaway topic for testing permissions | `%ACL_TOPIC%` → `acl-lab-userN` |

Permission tests run on the ACL practice topic on purpose. Breaking write access on your orders topic would also block the recovery work, and then two exercises fail for one mistake.

During the ACL lab you will see **WAIT**, then **GO DENIED** and later **GO RESTORED**. That mirrors how these tickets actually run: the platform team changes the rule, and support keeps the same client and reports what the application now sees.

---

## Authentication in AWS MSK

Authentication answers one question: **who is connecting?** Until the cluster has an answer, nothing else is evaluated — there is no point asking whether a stranger is allowed to write to a topic.

This cluster has two authenticated doors, both encrypted with TLS:

| Door | Port used in the lab | Client file | Identity it proves |
|------|----------------------|-------------|--------------------|
| SASL/SCRAM | public **9196** | `%USERPROFILE%\client-scram.properties` | a Kafka username and password |
| IAM | public **9198** | `%USERPROFILE%\client-iam.properties` | your AWS identity (`aws configure`) |

Your lab PC sits outside the cluster’s private network, so it uses the **public** endpoints above. Ports **9096** and **9098** are the private equivalents used by applications running inside the same VPC. They are not reachable from your desk, which is why a hang on those ports is a network story and not a password story.

There is no open, no-login port on this cluster. That is on purpose: an open port on a shared order stream would let any machine on the network read customer orders. Port **9092**, the plain Kafka default, simply hangs or resets here.

When authentication fails, the message is about **identity** — a rejected password, an unknown user, or a mechanism the port does not accept. Adding permissions cannot help, because the cluster never learned who you are.

Your password is already written into `client-scram.properties`, so the lab never asks you to type it again. If you want to see the two public endpoints in the AWS Console, there is a short optional walk-through in [samples/msk-iam-console.md](samples/msk-iam-console.md).

---

## Authorization using Access Control Lists (ACLs)

Once the cluster knows who you are, it checks what you may do. On the SCRAM door that check uses **Kafka ACLs**.

An ACL is a small rule with four parts: a **principal** (who), an **operation** (Read, Write, Describe, …), a **resource** (a topic, a consumer group, or the cluster), and either **Allow** or **Deny**. Your principal is written as `User:` plus your login, so seat `user3` is `User:user3`.

Two rules explain most authorization surprises:

- **No matching Allow means refused.** This cluster is set up so that missing permission is a refusal, not a free pass. A brand-new topic cannot be used until someone grants access to it.
- **Deny beats Allow.** If both rules exist for the same thing, the Deny wins. That is what makes a Deny useful in an emergency — it takes effect at once, without having to find and remove every Allow first.

You can list rules with `kafka-acls.bat --list`. Reading them is a normal support task, and it is often how you prove that a ticket is a permission ticket.

Changing rules is a different level of access. Editing ACLs counts as a **cluster-wide** action, so a normal application account cannot do it — that sits with the platform team. This often surprises people who have full rights in the AWS Console, because Console rights and Kafka ACL rights are two separate systems. An AWS administrator can still be refused when editing ACLs as a SCRAM user.

That split is why the exercise is arranged this way: the Deny is applied for your seat, and your part is what support actually does — run the same publish command again and read the result.

When a Deny on Write is active, publishing fails with `TopicAuthorizationException`. Notice what that error already tells you: the login worked and the network worked, and only permission is missing. No offset reset, consumer restart, or retention change will move it.

---

## SSL/TLS overview

Both doors wrap the login and the data in TLS (`SASL_SSL`), so credentials and order data are encrypted while crossing the network. Since the brokers use certificates issued by Amazon, the standard Java trust store on your PC already trusts them and nothing has to be installed.

This matters for troubleshooting because TLS failures look different from login failures. A TLS problem appears as a handshake error or a hostname mismatch, and it happens *before* any username is examined. A `SaslAuthenticationException`, by contrast, means TLS already succeeded and the credentials were rejected.

This also saves work: a successful `--list` on port 9196 has already proved TLS, the network path, and your password in one command. That is why this course does not spend lab time checking certificates by hand.

---

## IAM authentication overview

### Why IAM authentication exists

Imagine the shop had started with **SCRAM only**. Every application, script, and support tool gets a Kafka username and password kept in Secrets Manager. It works, and plenty of production clusters run exactly like this.

The problems show up as the number of applications grows:

| What happens | Why it becomes a problem |
|--------------|--------------------------|
| Every application carries a Kafka password | Rotating one password means updating the secret **and** every client that uses it. Miss one and that application starts failing hours later. |
| Kafka keeps its own list of users | Kafka knows `User:orders-svc`; AWS knows an IAM role. Nobody can see both lists in one place, so checks like “who still has access?” have to be done twice. |
| Applications on AWS already have an identity | A service on ECS, EKS, or Lambda runs under an IAM role. Giving it a second Kafka password adds one more secret to store and possibly leak. |
| Two teams own half the answer | Kafka permissions sit with the Kafka team, AWS permissions with the cloud team, so neither can answer “who can touch orders?” on their own. |

IAM authentication removes the extra password. The application connects using the **AWS identity it already has**, and permission is granted by an **IAM policy** — actions such as `kafka-cluster:Connect`, `kafka-cluster:WriteData` and `kafka-cluster:ReadData` on named topic ARNs.

One consequence is worth remembering before you troubleshoot it. On the IAM door, `kafka-acls.bat --list` shows nothing useful, because there are no Kafka ACLs involved for that connection. An IAM refusal appears as an access-denied message in the **client’s own log**, so on an IAM ticket you ask for the application log rather than a list of ACLs.

### Do you need both, or is IAM enough?

| Question | Answer |
|----------|--------|
| Must a cluster have both? | No. MSK can run SCRAM only, IAM only, or both together. |
| Is IAM on its own enough? | Yes — provided every producer and consumer can authenticate with IAM. New systems built entirely on AWS often choose IAM only. |
| Then why keep SCRAM? | Applications outside AWS, partner integrations, and third-party tools cannot get AWS credentials. They still need a username and password, so SCRAM stays. |
| Why does this cluster have both? | Days 1–3 use the SCRAM path because it is common in support work, and Day 4 adds IAM so you have seen both doors — including what it looks like when a client is sent to the wrong one. |

So neither choice is “correct” in general. The right question on a ticket is not *should this be IAM?* but **which door was this client built for?** — and then whether it is using the matching port and file.

### The two doors side by side

| Door | Port | Client file | Proves identity with | Decides allow or deny |
|------|------|-------------|----------------------|-----------------------|
| SCRAM | **9196** | `client-scram.properties` | username and password | Kafka ACLs |
| IAM | **9198** | `client-iam.properties` plus the IAM library | AWS credentials or role | IAM policies |

The IAM door needs one extra file on the client: `aws-msk-iam-auth.jar`, normally at `C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar`. It is the code that signs the connection with your AWS credentials, so without it on the classpath the login cannot be attempted at all.

Mix them up and the error is very specific: sending `client-scram.properties` to port **9198** reports that SCRAM is not enabled, and lists the login types that port does accept. Read the message literally and it is the answer — right cluster, wrong door — and no password change will help.

---

## Troubleshooting authentication failures

Each of these means the cluster could not agree on who you are:

| Signal | Most likely cause |
|--------|-------------------|
| `SaslAuthenticationException` on **9196** | Wrong SCRAM password or username |
| `UnsupportedSaslMechanismException` on the IAM port | SCRAM client file sent to port 9198 |
| IAM login fails with an AWS error | Missing `kafka-cluster:Connect`, or expired/absent AWS credentials |
| Nothing happens at all, then a timeout | Network or Security Group — the login was never attempted |

The last row is worth separating from the rest. A refusal is an answer, and it arrives quickly. Silence followed by a timeout means the connection never reached a broker, so no credential was ever checked. Chasing passwords in that case wastes the first ten minutes of an incident.

Two of these failures are captured in [samples/auth-fail.log](samples/auth-fail.log). Reading a real log next to this table is the fastest way to learn which line to look for.

---

## Troubleshooting authorization failures

These mean the cluster knows exactly who you are and is refusing this specific action:

| Signal | Most likely cause |
|--------|-------------------|
| `TopicAuthorizationException` | A Deny, or no Allow, for that operation on that topic |
| `GroupAuthorizationException` | The consumer group is not permitted for this principal |
| `ClusterAuthorizationException` | A cluster-wide action, such as editing ACLs, needs platform-level access |
| Works on connect, fails on publish or read (IAM door) | The IAM policy is missing `WriteData` or `ReadData` for that topic ARN |

Two habits come out of this table. First, quote the exception name in the ticket, because the name already identifies the layer. Second, remember that a **Deny always wins** over an Allow, so “but we granted access last week” does not settle anything until the Deny rules have been listed too.

---

## Topic configuration parameters

Topic settings decide how long data survives, how safe writes are, and how large a message may be. On a recovery ticket you read them **before** taking action, because they set the limits of what recovery can achieve.

Two commands show the picture, and they answer slightly different questions:

- `kafka-topics.bat --describe` — partitions, replication factor, and the in-sync replica list, so you can see whether the topic is healthy right now.
- `kafka-configs.bat --describe` — the settings applied specifically to this topic.

The settings that come up most in support work:

| Setting | What it controls |
|---------|------------------|
| `retention.ms` | How long messages are kept before deletion |
| `retention.bytes` | How much data a partition keeps before the oldest is deleted |
| `min.insync.replicas` | How many copies must confirm a write when the producer asks for full acknowledgement |
| `unclean.leader.election.enable` | Whether an out-of-date replica may become leader, which risks losing recent messages |
| `max.message.bytes` | The largest message the topic accepts |
| `cleanup.policy` | Whether old data is deleted or compacted by key |

Read them, quote them in the ticket, and leave them alone unless the lab says otherwise. Changing a topic setting during an incident, with no note of the previous value, is how a small ticket becomes a long one.

---

## Retention policies

Retention is the rule that deletes old messages. Kafka applies it whether or not anyone has read them, and it applies per partition.

Time and size limits work together — whichever is reached first triggers deletion. Deletion happens in whole segment files, so disk usage falls in steps rather than smoothly.

There are two levels, and this is where people get caught. The brokers hold defaults (`log.retention.ms`, `log.retention.bytes`), and a topic can override them with `retention.ms` and `retention.bytes`. If `kafka-configs.bat --describe` prints nothing for your topic, that does not mean “no retention” — it means the topic is using the broker defaults.

An example makes it concrete. `retention.ms=604800000` is seven days. A request to replay “the orders from last Tuesday” that arrives nine days later cannot be met, because those messages were deleted before the ticket was even written. Spotting that early lets you say “this has to be recovered from the source system” at the start of the incident instead of an hour into it.

Retention is therefore the first thing to check on any missing-message ticket. It decides whether replay is even an option.

---

## Common configuration settings used during troubleshooting

| Setting | The question it helps answer |
|---------|------------------------------|
| `min.insync.replicas` compared with the ISR list | Are publish timeouts caused by too few in-sync copies? |
| `unclean.leader.election.enable` | Could recent messages have been lost during a leader change? |
| `retention.ms` | Were the “missing” messages simply deleted by age? |
| `auto.offset.reset` | Where does a brand-new consumer group start reading? |
| `acks` and `delivery.timeout.ms` | Was the producer waiting for more confirmation than the cluster could give? |

`auto.offset.reset` deserves a note, because it explains a common confusion. It applies **only** when a group has no stored position — a new group, or one whose offsets expired. An existing group ignores it completely, which is why editing it never moves an existing consumer and never replaces a proper offset reset.

---

## Configuration validation

Validation means proving, with output, that the system is in the state you claim.

Describe the topic or group **before** the change and **after** it, and keep both. Paste the values that matter — replication factor, in-sync replicas, retention, offsets and lag — into the ticket.

“We restarted the consumer and it looks fine” is not validation. It records an action, not a result, and it leaves the next engineer with no way to tell what changed. A named test message that you can find again in the output is the smallest honest proof that the path works end to end.

---

## Investigating missing messages

“Missing” is a claim, not a diagnosis. In practice it resolves into one of six situations, and they need different answers:

| # | Situation | How you recognise it | What actually helps |
|---|-----------|----------------------|---------------------|
| 1 | It was never published | Producer log shows an error or no acknowledgement | Fix the producer; there is nothing in Kafka to recover |
| 2 | Published to another topic or partition | Describe the topic; check the message key | Correct the application’s target |
| 3 | Another group read it, not this one | The other group’s offsets moved, yours did not | Explain the ownership; do not move anyone’s bookmark |
| 4 | This group already read past it | Committed offset is ahead of the message | Kafka delivered it — investigate downstream |
| 5 | Retention deleted it | Message is older than `retention.ms` | Recover from the source system; replay is impossible |
| 6 | The consumer received it but did not process it | The record is still in the log | Read it in a separate scratch group and inspect it |

Cases 1, 4 and 5 are the ones where an offset reset would be pure risk with no benefit, and they are also the most commonly requested. Working through this list before touching offsets is the difference between a recovery and a self-inflicted incident.

---

## Consumer offset management

A committed offset is a group’s **bookmark**: how far this consumer group has read in each partition. `--describe` shows the committed offset, the end of the log, and the difference between them, which is the lag.

The important detail is that the bookmark belongs to the **group**, not to you or your terminal. Changing it is a write that every member of that group feels immediately. That is what makes a reset a genuine production change and not a local setting.

Ownership follows from that. Your lab group, `cg-userN-support`, stands for one team’s consumer in the story. Any other group name is another team’s bookmark, and moving it is like editing someone else’s change ticket while they are on call for it.

---

## Resetting consumer offsets

A reset moves the bookmark. It does not delete messages, it does not create messages, and it does not bring back anything retention has already removed.

You choose where to move it to:

```text
--reset-offsets --to-earliest | --to-latest | --to-offset <n> | --to-datetime <timestamp>
--dry-run   then   --execute
```

`--to-earliest` replays everything still on disk, which is fine in a lab and rarely what a real ticket wants. `--to-datetime` starts from the moment the incident began, which is why it is the usual production choice — it replays what is needed and no more.

The sequence matters as much as the flag:

| Step | Why it is in this order |
|------|--------------------------|
| Stop your consumers | Kafka refuses to move the bookmark while the group is actively reading, and a half-applied reset is worse than none |
| Check the group and topic names | This is the last moment to notice you are aiming at the wrong team’s group |
| Run with `--dry-run` | Prints the offsets it *would* set and changes nothing — a free review of the plan |
| Run with `--execute` once | Applies exactly the plan you just read |
| Start a consumer again | The bookmark alone changes nothing; the messages are re-read only when a consumer runs |

Immediately after `--execute`, lag looks large. That is the expected picture: the bookmark has moved back, and nothing has been re-read yet. It is a checkpoint, not a problem.

Recording the old offsets before you execute costs one command and is what makes the change reversible.

---

## Message replay techniques

Replay is not a special Kafka feature. It is a consumer reading messages that were read once before, which is why a reset alone does nothing until something consumes again.

Two approaches cover almost every ticket, and picking the right one avoids most of the risk:

**Recover a live consumer.** Reset that group, start its consumer, then confirm lag returning to zero and spot-check messages. Use this when the team’s own consumer genuinely needs to process the data again.

**Investigate without touching anything.** Read the topic from the beginning under a **new, throwaway group name**. The live group’s bookmark is untouched, so nothing is reprocessed and no downstream system is affected. Use this whenever the question is “is the message actually in Kafka?” — which is most of the time.

The risk in replay is downstream, not in Kafka. Kafka is happy to deliver the same order twice; the payment service, the email service, and the warehouse may not be. That is why replay is announced before it is run, and why the applications that expect it are built to recognise an order they have already handled.

---

## Best practices for message reprocessing

These are the habits that keep a replay from becoming its own incident:

- **Confirm the data is still there** before promising recovery — retention decides that, not effort.
- **Dry-run every reset**, and write down the current offsets first so the change can be undone.
- **Prefer a scratch group** while investigating; only touch a live group when that team’s consumer really must reprocess.
- **Change one thing, then validate** with lag and a named test message you can recognise.
- **Warn the receiving teams** before replaying. Kafka guarantees at-least-once delivery, so duplicates are expected behaviour and the consumer is responsible for handling them safely.
- **Never reset a group you do not own.** On a shared cluster that is not a favour, it is an incident with someone else’s name on it.
