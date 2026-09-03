# Day 5 assignment — one scenario write-up

Pick **one** scenario (1 to 5) and write it up as though handing it to a colleague who was not in the room.

Your ids: topic `orders-userN`, group `cg-userN-support`.

Label every fact **`[log]`** or **`[live]`**.

---

## Which scenario?

Scenario number: ___

Ticket title (from the notebook): ___

---

## 1 — Symptom

What the ticket claimed, in the reporter's words — not your diagnosis.

---

## 2 — Scope

One topic and group, or cluster-wide? How did you establish that?

---

## 3 — Evidence (minimum three facts)

| # | Label | Fact | Timestamp if known |
|---|-------|------|-------------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

---

## 4 — Diagnosis

Which layer was at fault?

- [ ] Application / processing
- [ ] Consumer (stopped, slow, or evicted)
- [ ] Broker / capacity
- [ ] Network path / wrong endpoint
- [ ] Authorization / ACL
- [ ] Not a Kafka problem — cluster healthy

One paragraph explaining why, citing your evidence.

---

## 5 — The one fix

What you changed (or what you recommended), and why that one and not the others the ticket suggested.

---

## 6 — Validation

| Check | Result |
|-------|--------|
| Named test message used | |
| Appeared in consumer output? | |
| Final `LAG` | |
| CloudWatch metric checked (if applicable) | |

---

## 7 — What you would not do

| Action you avoided | Why |
|--------------------|-----|
| | |
| | |

---

## 8 — Ticket close (three to five sentences)

Write the update you would post on the ticket — symptom, finding, action, validation, and any follow-up for another team.

---

## 9 — Reflection (one sentence each)

**How did you know it was (or was not) a Kafka problem?**

**What would you have broken if you had done the obvious thing the ticket asked for?**
