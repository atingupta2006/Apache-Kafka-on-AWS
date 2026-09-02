# Day 1 — Jupyter lab (CMD commands, not Python)

Same steps as [commands.md](commands.md), one **%%cmd** cell per step.

## Start JupyterLab

```bat
call scripts\start-jupyter-lab.bat
```

Open http://localhost:8888/lab → **day-01/lab.ipynb**

Alternate session file (set only if you have been told to):

```bat
set LAB_SESSION_BAT=c:\25-Trainings\2-Confirmed\20-08-26-kafka\GH\internal\tools\_trainer-user15-session.bat
call scripts\start-jupyter-lab.bat
```

## How it works

- Each code cell = **CMD** (`%%cmd` magic), not Python.
- First line in every cell: `call ..\scripts\jupyter-lab-session.bat` (loads `set-kafka-lab.bat`).
- Commands match [commands.md](commands.md) exactly (`kafka-topics.bat`, `produce.bat`, `consume.bat`, …).

## CMD vs notebook

| | CMD (`commands.md`) | Jupyter (`lab.ipynb`) |
|--|---------------------|------------------------|
| Setup | `start-lab.bat` | Same (once) |
| Run steps | Paste in CMD | Run cells |
| Produce/consume | Two CMD windows | Sequential cells |

Both paths cover the same Day 1 objectives.
