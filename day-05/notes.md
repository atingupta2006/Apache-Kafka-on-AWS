# Day 5 — Production support scenarios

Today you reuse everything from Days 1 to 4. There is no new product — only the **playbook** applied to five realistic tickets.

Commands: [commands.md](commands.md). Daily checklist: [samples/ops-checklist.md](samples/ops-checklist.md).

Use **your own** resources only: `userN` → `orders-userN` / `cg-userN-support` / `acl-lab-userN` / ACL principal `User:userN`.

---

## The playbook — use it on every scenario

| Step | What you do | Why this order |
|------|-------------|----------------|
| **1. Symptom** | Write what the ticket claims, in the reporter's words | Separates what was *reported* from what you *find* |
| **2. Scope** | One topic and group, or the whole cluster? | Decides urgency and who needs telling |
| **3. Evidence** | Logs, `--describe`, CloudWatch — label each fact `[log]` or `[live]` | Without labels, a report mixes past incident with current health |
| **4. One fix** | Make a single change | Two changes at once means you never learn which one worked |
| **5. Validate** | Named test message + `LAG` 0 | "It's running" is not proof |

**Hard rules:** do not reset offsets as your first action. Do not restart MSK. Do not touch another seat's group.

---

## Two kinds of evidence

| Kind | Source | Proves |
|------|--------|--------|
| **`[log]`** | Saved application logs in `samples/` or attachments | What the *application* experienced during that incident |
| **`[live]`** | Commands you run today + CloudWatch **Last 1 hour** | Whether the path is healthy *right now* |

Sample logs carry historical timestamps. CloudWatch will not have data for those exact minutes. That is normal — read the log for the application's story, and use live evidence for current cluster health. Do not force one onto the other.

**CloudWatch today:** AWS Console, time range **Last 1 hour**, same as Day 3. No CLI required.

---

## Scenario 1 — Deployed applications

**Ticket shape:** "Dashboard stopped updating. Fix Kafka."

**Your job:** Prove whether the cluster is the problem, using three evidence types together:

1. Read the **saved producer and consumer logs** (Day 2 samples) — build a timeline
2. Run **live** `--list`, probe produce/consume, `--describe` lag
3. Check **live** `CpuIdle` and disk in CloudWatch

**Likely conclusion:** cluster healthy; consumer stuck or evicted from its group. Restore the consume path; escalate application processing time to the app team.

**Test messages:** `s1-probe` — a message whose text you chose so you can recognise it in the output.

---

## Scenario 2 — Infrastructure and performance

**Ticket shape:** "Cannot connect to Kafka. Is the cluster down?"

**Your job:** Rule out cluster outage, then isolate the client path:

1. Cluster **Active**, expected broker count
2. Bootstrap is **`-public`** on **9196** for this lab PC
3. `nslookup` resolves the hostname
4. Topic ISR = Replicas; group state
5. CloudWatch `CpuIdle` / disk per broker

**Likely conclusion:** cluster up; reporting service has wrong endpoint or network path. Escalate with bootstrap string, nslookup output, and the exact Kafka error — do not change Security Groups yourself.

**Test message:** `s2-restore`

---

## Scenario 3 — Missing messages and reprocessing

**Ticket shape:** "Order missing from the database. Replay Kafka from this morning."

**Your job:** Decide whether replay would help **before** running anything:

| Check | If true |
|-------|---------|
| Message never produced | Nothing to recover in Kafka |
| Group already read past it | Kafka delivered it; fix the consumer or database |
| Retention deleted it | Replay cannot recover it |
| Data still on disk, position wrong | Targeted reset with **dry-run first** |

**Likely conclusion:** replay is the wrong fix when the committed offset is already past the message. Say so, and recommend `--to-datetime` instead of `--to-earliest` if replay is still wanted.

---

## Scenario 4 — Security and configuration

**Ticket shape:** "Authorization error. Reset offsets to clear it."

**Your job:** Read the exception name — it tells you which gate failed:

| Exception | Layer |
|-----------|-------|
| `SaslAuthenticationException` | Wrong credentials |
| `UnsupportedSaslMechanismException` on 9198 | Wrong client file for the IAM port |
| `TopicAuthorizationException` | ACL deny — offset reset will **not** help |

**Likely conclusion:** fix the permission, not the offsets. Wrong-listener demo (SCRAM client on 9198) proves listener and auth type must match.

**Test message:** `s4-probe` / `s4-restored`

---

## Scenario 5 — End-to-end incident

**Ticket shape:** Multiple symptoms in one afternoon — publish failures, lag, missing orders.

**Saved log:** [samples/scenario-5-app.log](samples/scenario-5-app.log)

**Your job:**

1. Read the **whole** log as a timeline before acting
2. Separate **symptoms** from **causes** — the first error is rarely the root cause
3. Notice **two different missing orders**: one never published, one published but not written downstream
4. Pick **one** primary fix; validate with `s5-validate`
5. Write a six-part summary: symptom, timeline, root cause, impact, actions taken, follow-up

**Key finding to defend:** neither missing order is recoverable by replaying Kafka.

---

## Production support best practices

### Daily health (see [ops-checklist.md](samples/ops-checklist.md))

Cluster **Active**, ISR = RF on critical topics, lag not trending up, disk under threshold, no leftover deny ACLs on lab topics.

### The three habits from this week

1. **Evidence before change** — gather, then act
2. **One change at a time** — then validate
3. **Validate with a named test message** — not "the process is running"

### Path contrast (repeat until automatic)

| Client | Port | Who |
|--------|------|-----|
| Lab Windows VM | Public **9196** SCRAM | You, in this course |
| App in VPC | Private **9096** or **9098** IAM | Real production apps |

A successful lab `--list` proves the **lab path**. It does not prove an in-VPC app's Security Group or DNS.
