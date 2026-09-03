# Day 4 assignment — missing message recovery procedure

Topic: `<your-topic>` (for example `orders-user3`)
Group: `<your-consumer-group>` (for example `cg-user3-support`)

**Why this is written down.** On a real incident the person who runs the recovery is often not the person who reviews it afterwards. A change record lets someone else repeat your steps, see what the system looked like before and after, and undo the change if needed. Filling this in is also the fastest way to notice a step you skipped.

Write it as a record someone else could follow without asking you questions.

---

## 1 — Topic configuration

| Question | Your answer |
|----------|-------------|
| `retention.ms` on your topic (override or broker default) | |
| How old would a message have to be before retention deletes it? | |
| Could you replay a message from one week ago on this topic? | yes / no — why? |

---

## 2 — Decision before any reset

| Check | Result | Conclusion |
|-------|--------|------------|
| Was the message ever produced? | | |
| Has the group already read past it? | | |
| Is it still within retention? | | |
| Should a reset help this specific missing message? | | |

---

## 3 — Offset plan (dry-run output)

Paste the dry-run table exactly as printed — partition and proposed new offset. Nothing has changed yet at this point.

---

## 4 — State after execute (before replay)

| Partition | CURRENT-OFFSET | LOG-END-OFFSET | LAG |
|-----------|----------------|----------------|-----|
| 0 | | | |
| 1 | | | |
| 2 | | | |

---

## 5 — Replay and validation

| Check | Result |
|-------|--------|
| One historical message you saw again | |
| Duplicates observed? | yes / no — example |
| Final `--describe` — LAG on all partitions | |
| Test message after replay consumed successfully? | |

---

## 6 — Downstream duplicate risk

| Question | Your answer |
|----------|-------------|
| What would a duplicate do in the downstream system (database, email, payment)? | |
| Is the consumer idempotent? | |
| Would you ask the application team to **pause the producer** during replay? | yes / no — why? |
| What is the difference between `--to-earliest` and `--to-datetime` for a real ticket? | |

---

## 7 — Authorization (section 4a)

| Question | Your answer |
|----------|-------------|
| Exception while deny was active | |
| Would an offset reset have fixed it? | |
| What restored Write (Deny removed)? | |

---

## 8 — What you would not do

At least one action you deliberately avoided, with the reason.

---

## 9 — Judgement question

A colleague asks you to reset a production group to `--to-earliest` because “a few orders are missing.”

Write the two or three questions you would ask before touching anything, and say which reset target you would probably recommend instead.
