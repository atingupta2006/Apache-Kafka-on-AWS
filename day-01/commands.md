# Day 1 — Commands (do these in order)

**Platform:** Windows 10 **Command Prompt (CMD) only** for every command below.

**Easier option:** run the same Day 1 lab in **Jupyter** — [lab.ipynb](lab.ipynb) + [README-lab.md](README-lab.md) (one **CMD** cell per step — same commands as below, not Python).

**Open CMD:** Start → type `cmd` → Enter.  
**Do not use PowerShell** for Kafka or lab `.bat` scripts (they break or behave differently).

If you use VS Code, set the terminal profile to **Command Prompt**, not PowerShell.

**How you connect:** bootstrap host names include `-public` and port **9196**, with your SCRAM password file.

Read [notes.md](notes.md) for explanations. This file is the **step-by-step lab**.

---

## CMD rules (every lab day)

| Rule | Why |
|------|-----|
| Run `call %USERPROFILE%\set-kafka-lab.bat` in **each new CMD window** | Sets `JAVA_HOME`, `BOOTSTRAP`, `TOPIC`, `GROUP`, `CLIENT` |
| Use **one** bootstrap host in `%BOOTSTRAP%` (no commas) | Comma lists break `kafka-*.bat` on Windows |
| Use `scripts\consume.bat` / `scripts\produce.bat` for messaging | `kafka-console-consumer.bat --group` fails on CMD |
| Paste commands **one block at a time** | Easier to see errors |
| Two terminals for produce + consume | Consumer must be running before you produce |

---

## Setup — copy and paste

Do these **once** on your Windows 10 lab VM in **CMD**.

### 0. Install tools (JDK, AWS CLI, Git, Kafka)

#### 0.1 JDK 21 → `C:\Java\jdk-21`

We use a path **without spaces** so Kafka’s Windows scripts work.

1. Open this page (Eclipse Temurin / Adoptium JDK 21, Windows x64, JDK):  
   https://adoptium.net/temurin/releases/?os=windows&arch=x64&package=jdk&version=21  
2. Download the **.msi** installer.  
3. Run the installer.  
4. Choose **Custom** (or change the folder) and set the install location to exactly:

```text
C:\Java\jdk-21
```

   Create `C:\Java` first if needed (File Explorer → This PC → Local Disk (C:) → New Folder named `Java`).  
5. Finish the installer.

**Already installed under `C:\Program Files\Java\jdk-21`?** Open **Command Prompt as Administrator** and create a junction (same folder, no spaces):

```bat
mkdir C:\Java 2>nul
mklink /J C:\Java\jdk-21 "C:\Program Files\Java\jdk-21"
```

**Check:**

```bat
C:\Java\jdk-21\bin\java.exe -version
```

**Expect:** a line that contains `21`.  
**If “cannot find…”:** the folder name is wrong — reinstall to `C:\Java\jdk-21`, or use the `mklink` step above.

#### 0.2 AWS CLI v2

1. Download: https://awscli.amazonaws.com/AWSCLIV2.msi  
2. Run the installer → Next → Install (defaults are fine).  
3. **Close and reopen** Command Prompt.

**Check:**

```bat
aws --version
```

**Expect:** `aws-cli/2.x.x ...`  
**If “not recognized”:** reopen CMD, or sign out and sign in.

#### 0.3 Git for Windows

1. Download: https://git-scm.com/download/win  
2. Run the installer (defaults are fine).  
3. Reopen Command Prompt if needed.

**Check:**

```bat
git --version
```

**Expect:** `git version 2.x.x`

#### 0.4 Install 7-Zip (needed to extract Kafka on Windows 10 CMD)

`tar` is **not** available on every Windows 10 lab VM. Use **7-Zip** instead.

1. Download: https://www.7-zip.org/  
2. Run the installer (64-bit x64). Defaults are fine.  
3. Reopen Command Prompt if it was open.

**Check:**

```bat
dir "C:\Program Files\7-Zip\7z.exe"
```

**Expect:** `7z.exe` found.  
**If missing:** reinstall 7-Zip to the default folder.

#### 0.5 Apache Kafka 3.8.1 client → `C:\kafka\kafka_2.13-3.8.1`

Use **this exact download** (Scala 2.13 binary for Kafka 3.8.1):

https://archive.apache.org/dist/kafka/3.8.1/kafka_2.13-3.8.1.tgz

**Download with Command Prompt:**

```bat
mkdir C:\kafka 2>nul
cd %USERPROFILE%\Downloads
curl -L -o kafka_2.13-3.8.1.tgz https://archive.apache.org/dist/kafka/3.8.1/kafka_2.13-3.8.1.tgz
```

**Expect:** a large file in Downloads (about 110–120 MB), not a tiny file.  
**If curl fails:** open the same URL in a browser and save the file into Downloads.

**Check size:**

```bat
dir %USERPROFILE%\Downloads\kafka_2.13-3.8.1.tgz
```

**Extract with 7-Zip (CMD — two steps):**

```bat
cd %USERPROFILE%\Downloads
"C:\Program Files\7-Zip\7z.exe" x kafka_2.13-3.8.1.tgz
"C:\Program Files\7-Zip\7z.exe" x kafka_2.13-3.8.1.tar -oC:\kafka
```

**Expect:** the first command creates `kafka_2.13-3.8.1.tar` in Downloads.  
The second command creates folder `C:\kafka\kafka_2.13-3.8.1`.

**Expect this file:**

```text
C:\kafka\kafka_2.13-3.8.1\bin\windows\kafka-topics.bat
```

**Check:**

```bat
dir C:\kafka\kafka_2.13-3.8.1\bin\windows\kafka-topics.bat
```

**If 7-Zip is in a different folder:** find `7z.exe` in File Explorer, then use that full path in quotes instead of `C:\Program Files\7-Zip\7z.exe`.

**Optional — only if `tar` exists on your VM:**

```bat
where tar
```

If that prints a path, you may use instead:

```bat
cd %USERPROFILE%\Downloads
tar -xzf kafka_2.13-3.8.1.tgz -C C:\kafka
```

Most class VMs should use the **7-Zip** steps above.

#### 0.6 AWS MSK IAM auth jar (needed Day 4 §4b on **your own Windows VM**)

Day 4 section **4b** (IAM listener **9198**) runs on each student’s **own Windows VM**, not on the shared Jupyter lab. Download this jar **once** after Kafka is installed (section 0.5):

```bat
curl -L -o C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar https://repo1.maven.org/maven2/software/amazon/msk/aws-msk-iam-auth/2.3.2/aws-msk-iam-auth-2.3.2-all.jar
```

**Check:**

```bat
dir C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar
```

**Expect:** one file (about 15 MB).  
**If curl fails:** open the URL in a browser and save the file to that exact path.

After you clone the course (section B), you can also run `scripts\install-iam-jar.bat` instead.

### A. AWS CLI credentials (once per VM)

You need AWS access keys so commands like `aws kafka describe-cluster` work.

**A1 — Sign in to the AWS Console** with your class login (`user1`, `user2`, …).

**A2 — Create an access key**

1. Open **IAM** (search “IAM” in the Console top search box).  
2. In the left menu open **Users**, then click **your user name** (same as your login).  
3. Open the **Security credentials** tab.  
4. Under **Access keys**, choose **Create access key**.  
5. Select **Command Line Interface (CLI)** → Next → Create.  
6. Copy **Access key ID** and **Secret access key** now (the secret is shown only once).  
   Paste them into Notepad temporarily if you need to.

If **Create access key** is blocked, your IAM user does not have permission to create keys. Access keys will be provided for you instead.

**A3 — Configure the AWS CLI** (Command Prompt):

```bat
aws configure
```

When it asks, enter:

| Prompt | What to type |
|--------|----------------|
| AWS Access Key ID | paste your Access key ID |
| AWS Secret Access Key | paste your Secret access key |
| Default region name | `ap-south-1`, or the region given for your class. Press Enter to keep the existing value if it is already correct. |
| Default output format | `json` |

**A4 — Check:**

```bat
aws sts get-caller-identity
```

**Expect:** JSON with your account id and an ARN that contains your login (for example `...:user/user3`).  
**If “Unable to locate credentials”:** run `aws configure` again.  
**If “InvalidClientTokenId” / “security token … invalid”:** the key is wrong or deleted — create a new access key and run `aws configure` again.  
**If you get `AccessDenied`:** authentication worked, so your credentials are valid — the IAM user simply lacks permission for that call. Note the exact action name in the error and request that permission.

---

### B. Course folder and Kafka lab helpers

**One-time clone** (if you do not have the folder yet):

```bat
cd %USERPROFILE%
git clone https://github.com/atingupta2006/Apache-Kafka-on-AWS.git
```

**Once per VM** (login + SCRAM password; press **Enter** to keep shared region / ARN / bootstrap defaults):

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\start-lab.bat
```

This writes your Kafka password file and saves `%USERPROFILE%\set-kafka-lab.bat`.

**Preflight (optional):**

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\validate-lab.bat
```

**Every new Command Prompt** (no questions):

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

Keep that window open. Paste from any folder.

**Check Kafka tools:**

```bat
kafka-topics.bat
echo %TOPIC% %GROUP%
```

**Expect:** Kafka help text, and your topic/group names printed.  
**If you get "not recognized":** the Kafka `bin\windows` folder is not on your `PATH`. Re-run `set-kafka-lab.bat` in this window.  
**If variables empty:** run `start-lab.bat` once, then use `set-kafka-lab.bat`.  
**If “The syntax of the command is incorrect.”:** paste this, then retry the Kafka command:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\fix-java-home.bat
call %USERPROFILE%\set-kafka-lab.bat
```

If it still fails, run `start-lab.bat` again once (rewrites `set-kafka-lab.bat`), then open a **new** Command Prompt and `call %USERPROFILE%\set-kafka-lab.bat`.

---

## 0. Password file details (only if you need to edit by hand)

Prefer:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\start-lab.bat
```

Manual fallback: copy `%USERPROFILE%\Apache-Kafka-on-AWS\day-01\samples\client-scram.properties.example` to `%USERPROFILE%\client-scram.properties`, then set your login and password on the `sasl.jaas.config` line (keep the quotes and the ending `;`).

---

## 1. Connect — prove AWS and Kafka both work

### 1.1 Who am I in AWS?

```bat
aws sts get-caller-identity
```

**Expect:** JSON with your account id and an ARN that contains your login.  
**If it fails:** go back to **Setup §A** (create access key + `aws configure`).

### 1.2 Is the MSK cluster Active?

**Console:** Amazon MSK → your cluster → status **Active**.

**CLI:**

```bat
aws kafka describe-cluster --cluster-arn %CLUSTER_ARN% --region %REGION%
```

**Expect:** `"State": "ACTIVE"` (or **Active** in the Console).

### 1.3 Confirm the bootstrap string

```bat
aws kafka get-bootstrap-brokers --cluster-arn %CLUSTER_ARN% --region %REGION%
```

Use the string that includes **`-public`** and **`:9196`**.  
If it differs from what you entered in `start-lab.bat`, update your session file:

```bat
set BOOTSTRAP=<paste-bootstrap-with-public-and-9196>
```

### 1.4 List topics (first Kafka call)

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

**Expect:** a list in a few seconds. You should see **your** topic (for example `orders-user1`). You might also see `orders-demo`.

**If “The syntax of the command is incorrect.”:**

1. Run `call %USERPROFILE%\set-kafka-lab.bat` again in **this** window.  
2. Confirm `echo %JAVA_HOME%` shows a path **without spaces** (for example `C:\PROGRA~1\Java\jdk-21` or `C:\Java\jdk-21`).  
3. Confirm `echo %BOOTSTRAP%` shows **one** host ending in `:9196` — **no commas**.  
   Comma-separated broker lists break Kafka’s Windows scripts. Use the single bootstrap from `start-lab.bat` / the board.

**If it hangs or times out** (`Timed out waiting for a node assignment`):

Your Windows VM is **outside** the MSK VPC. You must use the **public** bootstrap only:

- Hostname contains **`-public`**
- Port **`9196`** (SCRAM) — **not** private `:9096`

```bat
echo %BOOTSTRAP%
```

**Wrong (private — times out from lab VM):** `b-1.mskkafkaclass....amazonaws.com:9096`  
**Correct (public):** `b-1-public.mskkafkaclass....amazonaws.com:9196`

Do **not** copy the private string from `aws kafka get-bootstrap-brokers` — use the board value or press **Enter** at `start-lab.bat` bootstrap prompt.

**If authentication error:** open `client-scram.properties` and check username, password, and that `<password>` was fully replaced.

---

## 2. Explore your topic

List again (optional):

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

Describe **your** topic:

**Check your topic name first:**

```bat
echo TOPIC=%TOPIC%
```

**Expect:** `TOPIC=orders-userN` (your login). If empty, run `call %USERPROFILE%\set-kafka-lab.bat`.

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

**Expect:** lines for partitions (usually 0, 1, 2). Note:

- **Leader** (broker id)
- **Replicas**
- **Isr** (on a healthy topic, this matches the copies)
- Partition count and replication factor

**If `--list` worked but `--describe` fails:**

| Error | Fix |
|-------|-----|
| `The syntax of the command is incorrect.` | `git pull`, then `call scripts\fix-java-home.bat` and `call %USERPROFILE%\set-kafka-lab.bat` |
| `TOPIC` empty in `echo` | Run `set-kafka-lab.bat` |
| `UnknownTopicOrPartitionException` | Wrong topic — use `orders-userN` matching your login |
| Auth / SASL error | Re-run `start-lab.bat` with correct SCRAM password |

Write these on your assignment card.

---

## 3. Describe topic configuration

Topic describe (safe to run again):

```bat
kafka-topics.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --topic %TOPIC% --describe
```

Topic config:

```bat
kafka-configs.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --entity-type topics --entity-name %TOPIC% --describe
```

**Expect:** often only the header line and **no** config rows. That means the topic uses broker defaults (no dynamic overrides). That is normal on Day 1. For leaders and ISR, use topic `--describe` above.

---

## 4. View consumer groups

List groups:

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --list
```

**Expect before section 5:** you may only see AWS names like `amazon.msk.canary.group.broker-1` (ignore those). Your `cg-userN-support` appears after you consume once.

Describe **your** group:

**Paste as ONE line** — do not let the command wrap in the middle of `%GROUP%`:

```bat
echo GROUP=%GROUP%
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**If `The syntax of the command is incorrect.` before any Kafka output:**

1. The command was split across two lines when pasted — re-paste as **one line**, or type it manually.  
2. Run `call %USERPROFILE%\set-kafka-lab.bat` first.  
3. Run `git pull` and `call scripts\start-lab.bat` if other Kafka commands also fail.

**Expect before you consume (Section 5):**  
`Consumer group 'cg-userN-support' does not exist.`  
**This is normal — not an error.** The group is created when the consumer in section 5 joins.

**After section 5:** describe again — you should see partitions, offsets, and **LAG**.

---

## 5. Produce and consume sample messages

Use **two** terminals. In **both**, paste:

```bat
call %USERPROFILE%\set-kafka-lab.bat
```

### Terminal A — start the consumer first

Kafka’s Windows `kafka-console-consumer.bat` breaks when you pass `--group` (“The syntax of the command is incorrect”). Use the course helper instead:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --from-beginning
```

**Expect:** the window waits (cursor blinks). Leave it running.  
`--from-beginning` shows messages already on the topic as well as new ones.

### Terminal B — produce messages

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat
```

Type three lines (same key twice to see partition behaviour):

```text
order-1001
order-1002
order-1001
```

**Do not use** `kafka-console-producer.bat` or `kafka-console-consumer.bat` on Windows — they fail with “The syntax of the command is incorrect” when `--group` is used.

**Expect in Terminal A:** the same lines appear.

Stop the producer with `Ctrl+C`.  
Stop the consumer with `Ctrl+C` in Terminal A.

### Terminal C — offset contrast (after consumer stopped)

Produce one **new** line, then consume **without** `--from-beginning`:

```bat
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat order-1003
call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --max-messages 5 --timeout-ms 25000
```

**Expect:** only `order-1003` (not a full replay). If 0 messages, re-run produce + consume (group join can take up to ~25s).

### Check the group again

```bat
kafka-consumer-groups.bat --bootstrap-server %BOOTSTRAP% --command-config %CLIENT% --group %GROUP% --describe
```

**Expect:** your group exists. LAG is often **0** (or low) after the consumer caught up.

---

## Assignment

Open [samples/assignment-topic-card.md](samples/assignment-topic-card.md).

Fill every row using **your** `TOPIC` and `GROUP` and the output of `--describe` / group describe. Keep answers short.

---

## Quick troubleshooting (Day 1)

| Problem | What to check |
|---------|----------------|
| Wrong shell | Use **CMD**, not PowerShell |
| `The syntax of the command is incorrect.` on `kafka-consumer-groups.bat` | Command split across lines when pasted — use **one line**; run `set-kafka-lab.bat` |
| `The syntax of the command is incorrect.` on `kafka-topics.bat` | `git pull`, then `fix-java-home.bat` + `set-kafka-lab.bat`; JDK must be `C:\Java\jdk-21` |
| `The syntax of the command is incorrect.` on console consumer | Use `scripts\consume.bat` / `scripts\produce.bat` (not `kafka-console-consumer.bat` with `--group`) |
| Group `--describe` says **does not exist** | **Normal before Section 5** — run `consume.bat` once, then describe again |
| `TOPIC` or `GROUP` empty | Run `set-kafka-lab.bat` |
| `kafka-topics.bat` not found | `PATH` / run `set-kafka-lab.bat` |
| `aws` InvalidClientTokenId | New access key + `aws configure` (Setup §A) |
| Timeout on `--list` / `--describe` | Private bootstrap `:9096` — use **`-public`** and **`:9196`** |
| Hangs on `--list` | Check `BOOTSTRAP` is a `-public` host on port **9196** — the private `9096` endpoint times out from outside the VPC |
| Auth / SASL error | Password file username + password (`start-lab.bat`) |
| Consumer shows nothing | Produce in the other window; same `%TOPIC%` in both |
| Group not in `--list` / “does not exist” | Complete section 5 consume once (group is created then) |
| Only `amazon.msk.canary.group.*` in `--list` | Normal before you consume — those are AWS internal |
| Empty `kafka-configs` describe | Normal — topic has no dynamic overrides |
| Wrong topic or group name | Use your `orders-userN` and `cg-userN-support` |
