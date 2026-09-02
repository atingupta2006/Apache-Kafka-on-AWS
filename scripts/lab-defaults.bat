@echo off
REM Shared class defaults (same for every student).
REM Account: vinsys23-7 (891377046325) — https://vinsys23-7.signin.aws.amazon.com/console
REM Region: ap-south-1 | Cluster: msk-kafka-class | Student path: public SCRAM :9196
REM
REM IMPORTANT (Windows): DEF_BOOTSTRAP must be ONE host:port.
REM Comma-separated broker lists break kafka-*.bat ("The syntax of the command is incorrect").

set "DEF_REGION=ap-south-1"
set "DEF_CLUSTER_ARN=arn:aws:kafka:ap-south-1:891377046325:cluster/msk-kafka-class/ad474b96-f594-495b-82cd-ad95d7c2c71c-4"
set "DEF_BOOTSTRAP=b-1-public.mskkafkaclass.qau5zr.c4.kafka.ap-south-1.amazonaws.com:9196"
set "DEF_BOOTSTRAP_IAM=b-1-public.mskkafkaclass.qau5zr.c4.kafka.ap-south-1.amazonaws.com:9198"
set "DEF_CLUSTER_NAME=msk-kafka-class"

REM Install JDK to this exact folder (see day-01 commands — Install tools).
REM Path has no spaces, so kafka-*.bat works reliably.
set "DEF_JAVA_HOME=C:\Java\jdk-21"
REM Forward slashes avoid CMD turning "\b" into a backspace in PATH.
set "DEF_KAFKA_BIN=C:/kafka/kafka_2.13-3.8.1/bin/windows"
