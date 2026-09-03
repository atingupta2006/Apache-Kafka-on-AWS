# MSK — verify or enable IAM authentication (AWS Console)

**Prefer AWS Console UI** for these steps (no AWS CLI required).

This class cluster (`msk-kafka-class`, region `ap-south-1`) was built with **both** SASL/SCRAM and **IAM** enabled, plus public access. Security Group allows **9196** (SCRAM) and **9198** (IAM).

Students normally only **verify**. Use the “enable / create” sections if you build a **new** cluster or find IAM turned off.

---

## A. Verify IAM on an existing cluster (class default)

1. Sign in to the [AWS Console](https://vinsys23-7.signin.aws.amazon.com/console) (region **ap-south-1**).
2. Open **Amazon MSK** → **Clusters** → **`msk-kafka-class`** (or your cluster name).
3. Confirm cluster **Status** = **Active**.
4. Open the **Properties** tab (wording can vary slightly by Console version).

### A1 — Client authentication

Find **Client authentication** / **Security settings**:

| Setting | Expected for this class |
|---------|-------------------------|
| SASL/SCRAM | **Enabled** |
| IAM | **Enabled** |
| Unauthenticated | **Disabled** |

If **IAM = Enabled**, the cluster already supports Day 4 section 4b. No change needed.

### A2 — Public access + bootstrap string

1. Under connectivity / networking, confirm **Public access** is on (SERVICE_PROVIDED_EIPS / public access enabled).
2. Open **View client information** (or **Cluster connection**).
3. Note:
   - **Public SASL/SCRAM** bootstrap → hostnames with `-public` and port **9196**
   - **Public IAM** bootstrap → hostnames with `-public` and port **9198**

For Windows CMD labs, use **one** public host (no commas), for example:

```text
b-1-public.….amazonaws.com:9196     ← SCRAM (%BOOTSTRAP%)
b-1-public.….amazonaws.com:9198     ← IAM (%BOOTSTRAP_IAM%)
```

### A3 — Security Group (if IAM hangs)

MSK → cluster → security group link → **Inbound rules** must allow TCP **9198** from your Windows VM’s public IP (class lab often allows a training CIDR or `0.0.0.0/0` for the class window).

---

## B. Enable IAM on an existing cluster (only if IAM is Off)

Changing authentication can put the cluster into **Updating** for many minutes. Do this **before** class, not during student labs.

1. MSK → your cluster → **Properties** → **Edit** security / authentication (label varies).
2. Enable **IAM** access control (SASL/IAM). Keep **SCRAM** enabled if students still use passwords.
3. Keep **Unauthenticated** off.
4. Save and wait until status returns to **Active**.
5. If public clients need IAM: ensure **Public access** is enabled, then confirm **9198** in client information.
6. Confirm SG inbound **9198**.

Also ensure student AWS identities used for IAM Kafka clients have a data-plane policy allowing actions such as `kafka-cluster:Connect`, `kafka-cluster:DescribeCluster`, and topic/group actions you need (trainer-owned IAM policy). This is **separate** from Console permission to click MSK screens.

---

## C. Create a new MSK cluster with IAM (trainer / new environment)

High-level Console path (provisioning, not a student exercise):

1. **Amazon MSK** → **Create cluster** → Custom create (recommended for class).
2. Choose Kafka version compatible with your client (class uses **3.8.x** tools).
3. Broker size / count: class uses **3 brokers** (RF=3).
4. Networking: VPC + subnets; plan for **public access** if Windows clients are off-VPC.
5. **Security**:
   - Encryption in transit: TLS
   - Client auth: enable **IAM** and **SCRAM** (SCRAM needs Secrets Manager + customer KMS key for secrets)
   - Unauthenticated: off
6. After **Active**: turn on **Public access** if required; open SG **9196** and **9198**.
7. Create SCRAM users/secrets and associate them; create topics/ACLs (or run your provisioning scripts).
8. Copy public SCRAM (**9196**) and public IAM (**9198**) bootstrap strings into student `start-lab.bat` defaults / board.

Exact Console labels change over time; the checklist above is what must be true, not the click-by-click marketing names.

---

## D. What students need on their **own** Windows VM for IAM (Day 4 §4b)

| Item | Why |
|------|-----|
| JDK + Kafka 3.8.1 | Run `kafka-topics.bat` |
| `aws-msk-iam-auth.jar` in `libs\` | IAM client library (`install-iam-jar.bat`) |
| `client-iam.properties` | Mechanism `AWS_MSK_IAM` |
| `aws configure` on that VM | AWS identity for SigV4 |
| IAM policy with `kafka-cluster:*` (or tighter equivalent) | Authorization on the IAM listener |
| `%BOOTSTRAP_IAM%` = one `-public` host **:9198** | Correct listener |

SCRAM labs (sections 1–4a) do **not** need the IAM jar.
