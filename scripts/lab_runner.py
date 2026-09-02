"""Kafka/AWS lab runner for Jupyter on Windows or Linux JupyterHub.

Reads set-kafka-lab.bat in the user home (written by start-lab.bat or hub bake).
Uses java -cp directly — no kafka shell / CMD paste issues.
"""
from __future__ import annotations

import json
import os
import platform
import re
import subprocess
import sys
from pathlib import Path
from typing import Mapping

IS_WINDOWS = platform.system() == "Windows"
PATH_SEP = ";" if IS_WINDOWS else ":"
KAFKA_HOME = (
    Path(r"C:\kafka\kafka_2.13-3.8.1")
    if IS_WINDOWS
    else Path("/opt/kafka/kafka_2.13-3.8.1")
)
KAFKA_LIBS = str(KAFKA_HOME / "libs" / "*")
_default_session = Path.home() / "set-kafka-lab.bat"
SESSION_BAT = Path(os.environ["LAB_SESSION_BAT"]) if os.environ.get("LAB_SESSION_BAT") else _default_session
SET_LINE = re.compile(r"^set\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$", re.IGNORECASE)
DEFAULT_JAVA_HOME = r"C:\Java\jdk-21" if IS_WINDOWS else "/usr/lib/jvm/java-21-openjdk-amd64"


def load_lab_env(session: Path | None = None) -> dict[str, str]:
    """Parse set-kafka-lab.bat into a dict."""
    path = session or SESSION_BAT
    if not path.is_file():
        raise FileNotFoundError(
            f"Lab session not found: {path}\n"
            "Run once: call %USERPROFILE%\\Apache-Kafka-on-AWS\\scripts\\start-lab.bat"
        )
    env: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("@") or line.upper().startswith("REM"):
            continue
        m = SET_LINE.match(line)
        if m:
            env[m.group(1).upper()] = m.group(2).strip().strip('"')
    if not env.get("BOOTSTRAP"):
        raise ValueError(f"No BOOTSTRAP in {path} — re-run start-lab.bat")
    if "," in env.get("BOOTSTRAP", ""):
        raise ValueError(
            "BOOTSTRAP has commas — use ONE public host :9196. Re-run start-lab.bat."
        )
    if "-public" not in env.get("BOOTSTRAP", ""):
        print("WARNING: BOOTSTRAP missing '-public' — may timeout from lab VM.")
    return env


def _java_exe(env: Mapping[str, str]) -> Path:
    java_home = Path(env.get("JAVA_HOME", DEFAULT_JAVA_HOME))
    name = "java.exe" if IS_WINDOWS else "java"
    exe = java_home / "bin" / name
    if not exe.is_file():
        fallback = Path(os.environ.get("JAVA_HOME", "")) / "bin" / name
        if fallback.is_file():
            return fallback
        which = subprocess.run(["which", "java"], capture_output=True, text=True, check=False)
        if which.returncode == 0 and which.stdout.strip():
            return Path(which.stdout.strip())
        raise FileNotFoundError(f"java not found at {exe}")
    return exe


def _classpath(*, iam: bool = False) -> str:
    if iam:
        jar = KAFKA_HOME / "libs" / "aws-msk-iam-auth.jar"
        if jar.is_file():
            return f"{jar}{PATH_SEP}{KAFKA_LIBS}"
    return KAFKA_LIBS


def _client_path(env: Mapping[str, str]) -> str:
    return env.get("CLIENT") or str(Path.home() / "client-scram.properties")


def _run(
    argv: list[str],
    *,
    env: Mapping[str, str] | None = None,
    timeout: int = 120,
    input: str | None = None,
) -> subprocess.CompletedProcess[str]:
    merged = os.environ.copy()
    if env:
        merged.update({k: v for k, v in env.items()})
    return subprocess.run(
        argv,
        capture_output=True,
        text=True,
        timeout=timeout,
        env=merged,
        input=input,
        check=False,
    )


def print_result(proc: subprocess.CompletedProcess[str], *, title: str = "") -> int:
    if title:
        print(f"=== {title} ===")
    if proc.stdout:
        print(proc.stdout.rstrip())
    if proc.stderr:
        print(proc.stderr.rstrip(), file=sys.stderr)
    if proc.returncode != 0:
        print(f"Exit code: {proc.returncode}", file=sys.stderr)
    return proc.returncode


def aws_json(*args: str, timeout: int = 120) -> dict:
    proc = _run(["aws", "--output", "json", *args], timeout=timeout)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "aws failed").strip())
    return json.loads(proc.stdout or "{}")


def aws_cli(*args: str, timeout: int = 120) -> subprocess.CompletedProcess[str]:
    return _run(["aws", *args], timeout=timeout)


def kafka_java(main_class: str, *args: str, timeout: int = 120) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    java = _java_exe(env)
    client = _client_path(env)
    bootstrap = env["BOOTSTRAP"]
    cmd = [
        str(java),
        "-cp",
        _classpath(),
        main_class,
        "--bootstrap-server",
        bootstrap,
        "--command-config",
        client,
        *args,
    ]
    return _run(cmd, env=env, timeout=timeout)


def show_lab_info() -> dict[str, str]:
    env = load_lab_env()
    keys = [
        "LOGIN",
        "TOPIC",
        "GROUP",
        "BOOTSTRAP",
        "REGION",
        "CLUSTER_ARN",
        "CLUSTER_NAME",
        "JAVA_HOME",
        "CLIENT",
    ]
    print("Lab session loaded:")
    for k in keys:
        print(f"  {k} = {env.get(k, '(not set)')}")
    return env


def list_topics() -> subprocess.CompletedProcess[str]:
    return kafka_java("org.apache.kafka.tools.TopicCommand", "--list")


def describe_topic(topic: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    t = topic or env["TOPIC"]
    return kafka_java("org.apache.kafka.tools.TopicCommand", "--topic", t, "--describe")


def describe_topic_configs(topic: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    t = topic or env["TOPIC"]
    return kafka_java(
        "kafka.admin.ConfigCommand",
        "--entity-type",
        "topics",
        "--entity-name",
        t,
        "--describe",
    )


def list_consumer_groups() -> subprocess.CompletedProcess[str]:
    return kafka_java("org.apache.kafka.tools.consumer.group.ConsumerGroupCommand", "--list")


def describe_consumer_group(group: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    g = group or env["GROUP"]
    return kafka_java(
        "org.apache.kafka.tools.consumer.group.ConsumerGroupCommand",
        "--group",
        g,
        "--describe",
    )


def produce_message(message: str, topic: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    t = topic or env["TOPIC"]
    java = _java_exe(env)
    client = _client_path(env)
    producer_class = (
        "kafka.tools.ConsoleProducer"
        if IS_WINDOWS
        else "org.apache.kafka.tools.producer.ConsoleProducer"
    )
    cmd = [
        str(java),
        "-cp",
        _classpath(),
        producer_class,
        "--bootstrap-server",
        env["BOOTSTRAP"],
        "--producer.config",
        client,
        "--topic",
        t,
    ]
    return _run(cmd, input=message + "\n", env=env, timeout=60)


def consume_messages(
    *,
    group: str | None = None,
    topic: str | None = None,
    from_beginning: bool = False,
    max_messages: int = 10,
    timeout_ms: int = 15000,
) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    g = group or env["GROUP"]
    t = topic or env["TOPIC"]
    java = _java_exe(env)
    client = _client_path(env)
    cmd = [
        str(java),
        "-cp",
        _classpath(),
        "org.apache.kafka.tools.consumer.ConsoleConsumer",
        "--bootstrap-server",
        env["BOOTSTRAP"],
        "--consumer.config",
        client,
        "--topic",
        t,
        "--group",
        g,
        "--timeout-ms",
        str(timeout_ms),
        "--max-messages",
        str(max_messages),
    ]
    if from_beginning:
        cmd.append("--from-beginning")
    return _run(cmd, env=env, timeout=max(60, timeout_ms // 1000 + 30))


def sts_identity() -> dict:
    return aws_json("sts", "get-caller-identity")


def describe_cluster() -> dict:
    env = load_lab_env()
    return aws_json(
        "kafka",
        "describe-cluster",
        "--cluster-arn",
        env["CLUSTER_ARN"],
        "--region",
        env.get("REGION", "ap-south-1"),
    )


def safe_aws_call(fn, label: str = "AWS") -> bool:
    """Run AWS helper; print friendly message on failure. Returns True if OK."""
    try:
        fn()
        return True
    except Exception as e:
        print(f"{label} skipped:", str(e).splitlines()[0][:200])
        print("Check: AWS credentials match CLUSTER_ARN account, or use offline samples.")
        return False


def course_root() -> Path:
    """Apache-Kafka-on-AWS clone under USERPROFILE, or repo relative to lab_runner."""
    home = Path.home() / "Apache-Kafka-on-AWS"
    if (home / "scripts" / "lab_runner.py").is_file():
        return home
    return Path(__file__).resolve().parent.parent


def read_sample_log(name: str) -> str:
    root = course_root()
    files = {
        "producer": root / "day-02" / "samples" / "producer-error.log",
        "consumer": root / "day-02" / "samples" / "consumer-error.log",
        "scenario5": root / "day-05" / "samples" / "scenario-5-app.log",
    }
    key = name.lower()
    if key not in files:
        raise ValueError(f"Unknown log {name!r} — use producer, consumer, or scenario5")
    path = files[key]
    if not path.is_file():
        raise FileNotFoundError(f"Sample log not found: {path}")
    return path.read_text(encoding="utf-8", errors="replace")


def bootstrap_host() -> str:
    env = load_lab_env()
    return env["BOOTSTRAP"].split(":")[0]


def nslookup(host: str | None = None) -> subprocess.CompletedProcess[str]:
    h = host or bootstrap_host()
    return _run(["nslookup", h], timeout=30)


def describe_cluster_table() -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    return aws_cli(
        "kafka",
        "describe-cluster",
        "--cluster-arn",
        env["CLUSTER_ARN"],
        "--region",
        env.get("REGION", "ap-south-1"),
        "--query",
        "ClusterInfo.{State:State,Brokers:NumberOfBrokerNodes}",
        "--output",
        "table",
    )


def get_bootstrap_brokers() -> dict:
    env = load_lab_env()
    return aws_json(
        "kafka",
        "get-bootstrap-brokers",
        "--cluster-arn",
        env["CLUSTER_ARN"],
        "--region",
        env.get("REGION", "ap-south-1"),
    )


def extract_leader_ids(topic_describe_stdout: str) -> list[str]:
    return sorted(set(re.findall(r"Leader:\s*(\d+)", topic_describe_stdout or "")))


def cloudwatch_list_dashboards() -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    return aws_cli("cloudwatch", "list-dashboards", "--region", env.get("REGION", "ap-south-1"))


def cloudwatch_metric(
    metric_name: str,
    *,
    start_time: str,
    end_time: str,
    dimensions: list[tuple[str, str]],
    statistic: str = "Average",
    period: int = 300,
    namespace: str = "AWS/Kafka",
) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    # AWS CLI: each dimension is Name=Key,Value=Val (separate args)
    dim_args = [f"Name={name},Value={value}" for name, value in dimensions]
    return aws_cli(
        "cloudwatch",
        "get-metric-statistics",
        "--region",
        env.get("REGION", "ap-south-1"),
        "--namespace",
        namespace,
        "--metric-name",
        metric_name,
        "--dimensions",
        *dim_args,
        "--start-time",
        start_time,
        "--end-time",
        end_time,
        "--period",
        str(period),
        "--statistics",
        statistic,
        "--output",
        "json",
    )


def recover_probe() -> tuple[subprocess.CompletedProcess[str], subprocess.CompletedProcess[str]]:
    """Day 2 recover: produce marker then consume recent messages."""
    prod = produce_message("recover-probe")
    cons = consume_messages(from_beginning=False, max_messages=10, timeout_ms=25000)
    return prod, cons


def load_metrics_dump() -> dict:
    path = course_root() / "day-03" / "samples" / "metrics-dump.json"
    return json.loads(path.read_text(encoding="utf-8"))


IAM_JAR = KAFKA_HOME / "libs" / "aws-msk-iam-auth.jar"


def ensure_client_iam() -> Path:
    """Copy IAM client properties example if missing."""
    env = load_lab_env()
    target = Path(env.get("CLIENT_IAM") or Path.home() / "client-iam.properties")
    if target.is_file():
        return target
    example = course_root() / "day-04" / "samples" / "client-iam.properties.example"
    if not example.is_file():
        raise FileNotFoundError(f"IAM example not found: {example}")
    target.write_text(example.read_text(encoding="utf-8"), encoding="utf-8")
    print(f"Created {target}")
    return target



def kafka_with_config(
    main_class: str,
    bootstrap: str,
    config_path: str,
    *args: str,
    iam_auth: bool = False,
    timeout: int = 120,
) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    java = _java_exe(env)
    cmd = [
        str(java),
        "-cp",
        _classpath(iam=iam_auth),
        main_class,
        "--bootstrap-server",
        bootstrap,
        "--command-config",
        config_path,
        *args,
    ]
    return _run(cmd, env=env, timeout=timeout)


def reset_offsets(*, dry_run: bool = True) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    args = [
        "--group",
        env["GROUP"],
        "--topic",
        env["TOPIC"],
        "--reset-offsets",
        "--to-earliest",
    ]
    args.append("--dry-run" if dry_run else "--execute")
    return kafka_java("org.apache.kafka.tools.consumer.group.ConsumerGroupCommand", *args)


def list_acls(topic: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    t = topic or env.get("ACL_TOPIC") or f"acl-lab-{env['LOGIN']}"
    return kafka_java("kafka.admin.AclCommand", "--list", "--topic", t)


def add_acl_deny_write(topic: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    t = topic or env.get("ACL_TOPIC") or f"acl-lab-{env['LOGIN']}"
    login = env["LOGIN"]
    return kafka_java(
        "kafka.admin.AclCommand",
        "--add",
        "--deny-principal",
        f"User:{login}",
        "--operation",
        "Write",
        "--topic",
        t,
    )


def remove_acl_deny_write(topic: str | None = None) -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    t = topic or env.get("ACL_TOPIC") or f"acl-lab-{env['LOGIN']}"
    login = env["LOGIN"]
    return kafka_java(
        "kafka.admin.AclCommand",
        "--remove",
        "--deny-principal",
        f"User:{login}",
        "--operation",
        "Write",
        "--topic",
        t,
        "--force",
    )


def list_topics_iam() -> subprocess.CompletedProcess[str]:
    env = load_lab_env()
    ensure_client_iam()
    bootstrap = env.get("BOOTSTRAP_IAM", "")
    client_iam = env.get("CLIENT_IAM") or str(Path.home() / "client-iam.properties")
    if not bootstrap:
        raise ValueError("BOOTSTRAP_IAM missing — re-run start-lab.bat")
    if not IAM_JAR.is_file():
        raise FileNotFoundError(f"IAM jar missing — run scripts/install-iam-jar.bat")
    return kafka_with_config(
        "org.apache.kafka.tools.TopicCommand",
        bootstrap,
        client_iam,
        "--list",
        iam_auth=True,
    )


def list_topics_wrong_listener() -> subprocess.CompletedProcess[str]:
    """SCRAM client on IAM port — should fail (wrong mechanism)."""
    env = load_lab_env()
    bootstrap = env.get("BOOTSTRAP_IAM", "")
    client = _client_path(env)
    return kafka_with_config(
        "org.apache.kafka.tools.TopicCommand",
        bootstrap,
        client,
        "--list",
        iam_auth=False,
    )


def produce_to_topic(message: str, topic: str) -> subprocess.CompletedProcess[str]:
    return produce_message(message, topic=topic)


def scenario_validate(message: str = "s5-validate") -> tuple[
    subprocess.CompletedProcess[str],
    subprocess.CompletedProcess[str],
    subprocess.CompletedProcess[str],
]:
    """Day 5 end validation: produce, consume, group describe."""
    prod = produce_message(message)
    cons = consume_messages(from_beginning=False, max_messages=5, timeout_ms=20000)
    desc = describe_consumer_group()
    return prod, cons, desc
