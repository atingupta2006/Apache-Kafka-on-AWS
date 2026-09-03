# Day 4 — Lab options

**Start here:** [notes.md](notes.md) — read **Story for today** once. It sets out the support ticket that all of toda’ exercises come from, so each command has a reason behind it.

**Then do the labs:** [commands.md](commands.md) on your own Windows PC, in Command Prompt.

**Prefer explanations beside each command?** [lab.ipynb](lab.ipynb) has the same steps in a notebook.

| What you need | Where it is |
|---------------|-------------|
| Story, concepts, and troubleshooting tables | [notes.md](notes.md) |
| Commands to run, in order | [commands.md](commands.md) |
| Same steps with notes in a notebook | [lab.ipynb](lab.ipynb) |
| Example of the two failing logins | [samples/auth-fail.log](samples/auth-fail.log) |
| Optional: see the two public ports in the AWS Console | [samples/msk-iam-console.md](samples/msk-iam-console.md) |
| Assignment | [samples/assignment-recovery.md](samples/assignment-recovery.md) |

Toda’ exercises, in the order you will do them:

1. Read the topic configuration, so you know whether recovery is even possible
2. Move your consumer grou’ position, with a dry-run first
3. Replay the messages and validate the result
4. See a permission failure and a permission restore on the ACL practice topic
5. Try the IAM door, including the mistake of using the wrong client file
