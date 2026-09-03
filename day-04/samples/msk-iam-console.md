# MSK listeners — quick Console check (optional)

Use this only if you want to **see** the two public bootstrap ports in AWS Console. The lab cluster already uses SCRAM on **9196** and IAM on **9198** — you do not change cluster settings in class.

1. Sign in to the AWS Console (region **ap-south-1**).
2. Open **Amazon MSK** → **Clusters** → **`msk-kafka-class`** (or the cluster name given for class).
3. Confirm **Status** = **Active**.
4. Open **View client information** (or **Cluster connection**).
5. Note the **public** endpoints:
   - SASL/SCRAM → hostnames with `-public` and port **9196** → `%BOOTSTRAP%`
   - IAM → hostnames with `-public` and port **9198** → `%BOOTSTRAP_IAM%`

For Windows CMD, use **one** public host (no comma-separated list), for example:

```text
b-1-public.….amazonaws.com:9196
b-1-public.….amazonaws.com:9198
```

**Client authentication** on this cluster: SASL/SCRAM and IAM are both on; unauthenticated is off. Your CMD labs still need the matching client file for each port (`client-scram.properties` vs `client-iam.properties`).
