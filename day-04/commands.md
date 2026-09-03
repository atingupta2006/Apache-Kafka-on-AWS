# Day 4 — Commands

**Platform:** Windows 10 **Command Prompt (CMD)** — not PowerShell. Same PC you used on Days 1–3.

**Read first:** [notes.md](notes.md) — **Story for today**. It explains the ticket these labs are based on.

**Easier option:** [lab.ipynb](lab.ipynb) — the same steps with the explanations beside each command ([README-lab.md](README-lab.md)).

---

## Setup — each lab window

**Paste this first, in every new CMD window:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

This sets `BOOTSTRAP`, `BOOTSTRAP_IAM`, `CLIENT`, `CLIENT_IAM`, `TOPIC`, `GROUP`, `ACL_TOPIC` and the Kafka `PATH`, so every command below can be pasted as written.

Check the four names you own today:

```bat
echo LOGIN=%LOGIN% TOPIC=%TOPIC% GROUP=%GROUP% ACL_TOPIC=%ACL_TOPIC%
echo BOOTSTRAP=%BOOTSTRAP%
echo BOOTSTRAP_IAM=%BOOTSTRAP_IAM%
```

**Expect:** your login, `orders-userN`, `cg-userN-support`, `acl-lab-userN`, a `BOOTSTRAP` ending in **:9196** and a `BOOTSTRAP_IAM` ending in **:9198**.

If anything is empty, run `scripts\start-lab.bat` once, then `set-kafka-lab.bat` again.

Take the extra ten seconds to read those names now. Later in this lab you will move a consumer grou’ position, and the only thing standing between “recovery” and “someone els’ incident” is having the right group name in the command.

| Toda’ work | Use | Do not touch |
|--------------|-----|--------------|
| Topic config, offset reset, replay | `%TOPIC%` and `%GROUP%` | Any other group or topic |
| Permission (ACL) exercise | `%ACL_TOPIC%` only | Never on `%TOPIC%` |

---

## 1. Review topic configuration

**The ticket asks for a replay. This step decides whether a replay is even possible.**

Retention deletes old messages on a schedule, so the first job is to see what the topic keeps and whether it is currently healthy.

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

**Expect:** 3 partitions, replication factor 3, and the ISR list matching the replica list. Matching lists mean every copy is up to date, so nothing here is at risk.

Now look at the settings applied to this topic specifically:

```bat
kafka-configs.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --entity-type topics --entity-name %TOPIC% --describe
```

**Expect:** possibly an empty result. That is normal and it does **not** mean retention is switched off — an empty list means this topic follows the broker defaults instead of its own override. Saying “no retention configured” on a ticket when you saw an empty list is a common and expensive mistake.

Write down what you found. If the messages a ticket asks about are older than the retention period, the honest answer is that they cannot be replayed from Kafka at all.

---

## 2. Reset consumer offsets

**Now the actual change.** The consumer group has read past the messages the team needs, so you move its bookmark back.

First stop anything that is consuming in your group — Kafka refuses to move the position while the group is active, and a half-applied reset is worse than none:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**Expect:** one row per partition with `CURRENT-OFFSET`, `LOG-END-OFFSET` and `LAG`. Confirm the group name is yours and the topic is yours. Note the current offsets — that is what makes this change reversible.

Then ask Kafka what it *would* do. This changes nothing:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --topic %TOPIC% --reset-offsets --to-earliest --dry-run
```

**Expect:** a table of partitions with the new offset it proposes. Read it before continuing. In production this printout is the change plan you would attach to the ticket.

Only if that looks right, apply it:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --topic %TOPIC% --reset-offsets --to-earliest --execute
```

Check the result:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**Expect:** `LAG` is now large. That is success, not a problem — the bookmark moved back and nothing has re-read the messages yet.

This lab uses `--to-earliest` because the effect is easy to see. A real ticket usually uses `--to-datetime` with the time the incident started, so you replay only what is needed instead of the whole topic.

---

## 3. Replay messages

**Moving the bookmark does not replay anything.** Messages are re-read only when a consumer runs, so start one:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --from-beginning --max-messages 25 --timeout-ms 60000
```

**Expect:** older messages from Days 1–3 appearing again. Those are the same records, delivered a second time — exactly what “replay” means, and exactly why the systems downstream have to be warned first.

The limit of 25 messages keeps this quick. Check how far the group got:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**If `LAG` is still above 0:** run the same `consume.bat` line again. Each run reads the next batch and commits its progress, so the lag falls in steps.

Lag reaching 0 plus recognising your own messages in the output is the validation. “The consumer is running” is not.

---

## 4a. Permissions on `%ACL_TOPIC%`

**A different failure, same ticket.** Publishing now fails for a reason that has nothing to do with offsets, and this exercise is how you learn to recognise it in one glance.

Everything here runs on `%ACL_TOPIC%` (`acl-lab-userN`), never on your orders topic. Breaking write access on `%TOPIC%` would also block the recovery work you just did.

**A — see the rules that exist**

```bat
kafka-acls.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list --topic %ACL_TOPIC%
```

**Expect:** Allow rules for your principal `User:%LOGIN%`. Reading the rules is a normal support action and is often how you prove a ticket is a permissions ticket.

**B — publish successfully, to establish a baseline**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-ok
```

**Expect:** no error. This proves login, network and permission are all fine right now — which is what makes the next step meaningful.

**WAIT** until the room announces **GO DENIED**. A Deny rule on Write is now in place for your seat, the way a platform team would apply one during an incident.

**C — publish again, and expect it to fail**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-denied-test
```

**Expect:** `TopicAuthorizationException`. Read the wording. Nothing about your password or the network changed between step B and step C — only permission did. Note also that the command may still exit quietly, so the error text matters more than the exit code.

Optional, to see the rule itself:

```bat
kafka-acls.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list --topic %ACL_TOPIC%
```

**WAIT** until the room announces **GO RESTORED**. The Deny has been removed.

**D — publish successfully again**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat %ACL_TOPIC% acl-restored
```

**Expect:** success. Working, then failing, then working, with only the ACL changing, is what proves the cause. That before-and-after pair is the evidence you would attach to a real authorization ticket.

The lesson to carry into Day 5: an offset reset would never have fixed this, because the bookmark was never the problem.

---

## 4b. The IAM door

**Why this section exists.** With SCRAM only, every application carries a Kafka password that somebody must store and rotate. Applications running on AWS already have an identity, so many clusters add a second door where the client authenticates with **AWS credentials** instead. On that door, allow and deny come from **IAM policies**, not from `kafka-acls`.

You do not need both doors — IAM alone is enough when every client can use it, and SCRAM stays when some clients cannot. The reason you try both today is the failure in the middle: pointing a client at the wrong door produces an error that looks like a bad password. Details are in [notes.md](notes.md).

### One-time preparation

Skip this if Day 1 already set it up:

```bat
copy %USERPROFILE%\Apache-Kafka-on-AWS\day-04\samples\client-iam.properties.example %USERPROFILE%\client-iam.properties
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\install-iam-jar.bat
dir C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar
```

The jar is the library that signs the connection with your AWS credentials, so the IAM login cannot be attempted without it. Your `aws configure` from the earlier days provides the credentials.

### The mistake, on purpose

Send the **SCRAM** file to the **IAM** port:

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP_IAM% --command-config %CLIENT% --list
```

**Expect:** an error stating that `SCRAM-SHA-512` is not enabled, listing the mechanisms the port does accept (`[OAUTHBEARER, AWS_MSK_IAM]`).

Read that message as an answer rather than a fault: right cluster, wrong door. In production this arrives as “the application suddenly cannot authenticate,” and people spend hours resetting a password that was never wrong.

### The correct IAM connection

```bat
set CLASSPATH=C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar;%CLASSPATH%
kafka-topics.bat --bootstrap-server %BOOTSTRAP_IAM% --command-config %CLIENT_IAM% --list
```

**Expect:** a list of topics. Same cluster, same data, different door and different identity.

If it fails instead, keep the exact error text — an IAM refusal names a missing action such as `kafka-cluster:Connect`, which is a very different escalation from a wrong password. The `CLASSPATH` applies only to the current window, so set it again in a new one.

Never point `%CLIENT_IAM%` at port **9196**. That is the same mistake in the opposite direction.

---

## Assignment

Write up the recovery as a change record someone else could follow: [samples/assignment-recovery.md](samples/assignment-recovery.md).

---

## Quick troubleshooting

| Problem | What to do |
|---------|------------|
| Variables are empty | Run `scripts\start-lab.bat` once, then `set-kafka-lab.bat` |
| Reset is refused | A consumer in your group is still running — stop it, then dry-run and execute again |
| Publish fails before **GO DENIED** | Do not change offsets; report the error text |
| `LAG` still above 0 after replay | Run the same `consume.bat` line again |
| IAM commands fail on classes or handlers | The jar is missing, or `CLASSPATH` was not set in this window |
| The command hangs instead of failing | Confirm you are using the `-public` host on **9196** or **9198**, not the private **9096** |
