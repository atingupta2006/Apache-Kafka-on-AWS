# Day 2 assignment — incident write-up

Use **your** topic and group.

- Topic: `orders-userN` (example: `orders-user2`)
- Group: `cg-userN-support`

Also use [producer-error.log](producer-error.log), [consumer-error.log](consumer-error.log), and your `--describe` output from today's labs.

Label every fact **`[log]`** (from the saved sample files) or **`[live]`** (from commands you ran today).

---

## Symptom

One short paragraph: what failed for the producer, what happened to the consumer, and what the business impact would be (for example "orders stopped appearing in the dashboard").

---

## Evidence

| Source | Label | What you saw |
|--------|-------|--------------|
| Producer log | `[log]` | |
| Consumer log | `[log]` | |
| Consumer group `--describe` (before recover) | `[live]` | |
| Consumer group `--describe` (after recover) | `[live]` | |
| Topic `--describe` (ISR healthy?) | `[live]` | |
| Test message `recover-probe` consumed? | `[live]` | |

---

## Producer and consumer configuration (from the log headers)

| Setting | Value in log | What it means in plain words |
|---------|--------------|------------------------------|
| Producer: `acks` | | |
| Producer: `delivery.timeout.ms` | | |
| Consumer: `max.poll.interval.ms` | | |
| Consumer: `enable.auto.commit` | | |

---

## Troubleshooting approach

Numbered steps you actually used — for example: read logs for timeline → confirm bootstrap → `--describe` lag → probe produce/consume → compare before/after lag.

---

## Probable root cause

One or two sentences. Name the **layer**: application, consumer, broker, or network path.

---

## Recommended resolution

What you would do in production, based on the evidence. Include what you would **not** do and why (for example "would not reset offsets — the saved position was not the problem").

---

## Ticket update (optional)

Write two or three sentences as though closing a ticket — symptom, what you found, what you validated.
