# Day 2 — Jupyter lab (CMD + log reading)

Same steps as [commands.md](commands.md). **CMD cells**, not Python.

## Start

```bat
call scripts\start-jupyter-lab.bat
```

Open **day-02/lab.ipynb** — includes a **how to read sample logs** section before each log file.

## Sample logs

| File | Purpose |
|------|---------|
| `samples/producer-error.log` | Practice reading a **failed producer** (timeouts, retries) |
| `samples/consumer-error.log` | Practice reading a **failed consumer** (poll timeout, commit failed) |

In CMD:

```bat
call scripts\read-sample-log.bat producer
call scripts\read-sample-log.bat consumer
```

These are **teaching samples** — fake hostnames, not live cluster output.
