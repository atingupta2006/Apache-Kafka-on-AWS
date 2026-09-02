# Apache Kafka on AWS

**Duration:** 12 Hours (3 Days × 4 Hours)

Lab client: **Windows 10** — all commands in this course run in **Command Prompt (CMD)**.

**Class AWS account:** [vinsys23-7 console](https://vinsys23-7.signin.aws.amazon.com/console) · Region **`ap-south-1`** · Cluster **`msk-kafka-class`**

AWS login ids: **`user1`**, **`user2`**, **`user3`**, … — same id for SCRAM username, topic `orders-userN`, and group `cg-userN-support`.

---

## Windows 10 CMD — read this first

1. Open **Command Prompt** (Start → type `cmd` → Enter). Do **not** use PowerShell for Kafka commands.  
2. In **every new CMD window**, run first: `call %USERPROFILE%\set-kafka-lab.bat`  
3. Use Kafka **`.bat`** tools and course helpers under `scripts\` (see [day-01/commands.md](day-01/commands.md)).  
4. For produce/consume use **`consume.bat`** and **`produce.bat`** — not `kafka-console-consumer.bat` with `--group`.  
5. Bootstrap in `set-kafka-lab.bat` is **one** host `:9196` (no commas).

---

## Install tools + lab setup

Full steps with download links: **[day-01/commands.md](day-01/commands.md)** (Setup §0 → §A → §B).

Short checklist:

1. JDK 21 → `C:\Java\jdk-21` (Adoptium Temurin)  
2. AWS CLI v2 → https://awscli.amazonaws.com/AWSCLIV2.msi  
3. Git → https://git-scm.com/download/win  
4. 7-Zip → https://www.7-zip.org/ (to extract Kafka `.tgz` on Windows CMD)  
5. Kafka 3.8.1 → https://archive.apache.org/dist/kafka/3.8.1/kafka_2.13-3.8.1.tgz → extract to `C:\kafka\kafka_2.13-3.8.1` with 7-Zip (see day-01 commands §0.4–0.5)  
6. `aws configure` + `aws sts get-caller-identity`  
7. Clone + `start-lab.bat`:

```bat
cd %USERPROFILE%
git clone https://github.com/atingupta2006/Apache-Kafka-on-AWS.git
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\start-lab.bat
```

**Every new Command Prompt:**

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

| Day | Materials |
|-----|-----------|
| 1 | [notes](day-01/notes.md) · [commands](day-01/commands.md) · **[Jupyter lab](day-01/lab.ipynb)** (optional, simpler) |
| 2 | [notes](day-02/notes.md) · [commands](day-02/commands.md) · **[Jupyter lab](day-02/lab.ipynb)** |
| 3 | [notes](day-03/notes.md) · [commands](day-03/commands.md) · **[Jupyter lab](day-03/lab.ipynb)** |

**Day 3 variables** (`CLUSTER_NAME`, `ACL_TOPIC`, `BOOTSTRAP_IAM`): if empty after `set-kafka-lab.bat`, run `start-lab.bat` once to regenerate `%USERPROFILE%\set-kafka-lab.bat`, then `git pull` for the latest `scripts\`.
