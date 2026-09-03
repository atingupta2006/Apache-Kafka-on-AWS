# Daily Kafka / MSK operations checklist

Cluster: `<cluster-name>`  
Client: Windows 10 lab VM (**outside MSK VPC**; public SCRAM **9196**)  
Auth default: SASL/SCRAM (`%USERPROFILE%\client-scram.properties`; username = login `userN`)  
Topic / group: `orders-userN` / `cg-userN-support`

| Check | Command or place | OK? |
|-------|------------------|-----|
| Cluster state ACTIVE | `aws kafka describe-cluster` | |
| Broker count matches expectation | same | |
| Public SCRAM bootstrap resolves | `get-bootstrap-brokers` / `nslookup` on `-public` host | |
| Off-VPC Windows `--list` works | `kafka-topics.bat --list` on **9196** | |
| Critical topics ISR = RF | `--describe` | |
| Consumer members present | `--describe --group` | |
| Lag not trending up | group describe / dashboard | |
| CloudWatch alarms | `describe-alarms` (lab alarm prefix); empty list → mark N/A, do not create | |
| CpuIdle not exhausted on all brokers | CloudWatch dashboard / metrics | |
| Kafka log disk under threshold | `KafkaDataLogsDiskUsed` | |
| No leftover deny ACLs on lab topics | `kafka-acls.bat --list` | |
| IAM listener still works (weekly) | `client-iam.properties` `--list` on public **9198** | |

Incident order: symptom → scope → path → describe → logs → metrics → one change → validate.
