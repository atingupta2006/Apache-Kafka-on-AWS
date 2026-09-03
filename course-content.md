# Apache Kafka on AWS

**Duration:** 20 Hours (5 Days × 4 Hours)

This workshop is designed for L1, L2 and L3 Production Support Engineers responsible for supporting Kafka-based applications. The workshop focuses on production support activities including monitoring, troubleshooting, security, configuration review and operational best practices. Application development is outside the scope of this training.

## Prerequisites

- Basic understanding of Apache Kafka concepts
- Basic knowledge of Java
- Basic Windows command-line knowledge (Command Prompt or Git Bash)
- Familiarity with AWS environments (Console and CLI)
- Prior exposure to Production Support activities is beneficial

## Learning objectives

After completing this workshop, participants will be able to:

- Understand the architecture of Apache Kafka on AWS MSK
- Monitor Kafka clusters using AWS monitoring services
- Troubleshoot producer, consumer and broker-related issues
- Analyze application logs and Kafka client errors
- Investigate infrastructure, security and configuration issues
- Troubleshoot consumer lag and message processing issues
- Perform consumer offset management and message replay
- Apply production support best practices for Kafka environments

---

## Day 1 (4 Hours) — Kafka Fundamentals and AWS MSK Overview

### Apache Kafka Fundamentals

- Apache Kafka architecture overview
- Topics and partitions
- Producers and consumers
- Consumer groups
- Brokers and replicas
- Message flow and offsets
- Message lifecycle

### AWS Managed Streaming for Apache Kafka (MSK)

- AWS MSK architecture
- Cluster components
- Client connectivity
- Topic overview
- Consumer group overview

### Hands-on Exercises

- Connect to an AWS MSK cluster
- Explore Kafka topics
- Describe topic configuration
- View consumer groups
- Produce and consume sample messages

### Assignment

Review an existing Kafka topic and document:

- Number of partitions
- Replication factor
- Consumer groups consuming the topic
- Message flow from producer to consumer

---

## Day 2 (4 Hours) — Producer and Application Troubleshooting

### Producer and Application Troubleshooting

- Message publishing failures
- Producer timeout issues
- Retry behaviour
- Acknowledgement settings
- Reviewing producer application logs
- Analyzing common Kafka client exceptions
- Correlating application logs with Kafka broker behaviour

### Consumer and Application Troubleshooting

- Consumer lag analysis
- Consumer group rebalancing
- Offset commit issues
- Slow consumers
- Reviewing consumer application logs
- Troubleshooting consumer connectivity issues

### Broker and Infrastructure Troubleshooting

- Broker availability
- Leader election overview
- Under-replicated partitions
- Network connectivity issues
- DNS resolution issues
- Security Group configuration
- Disk usage and retention issues

### Hands-on Exercises

- Diagnose consumer lag
- Analyze application logs
- Investigate broker health
- Recover a stopped consumer

### Assignment

Analyze a production incident involving producer failures and consumer lag. Document the troubleshooting approach, probable root cause and recommended resolution.

---

## Day 3 (4 Hours) — Monitoring and Performance Troubleshooting

### Monitoring AWS MSK

- Monitoring Kafka cluster health
- AWS CloudWatch metrics
- Broker health monitoring
- Consumer lag monitoring
- Disk utilization monitoring
- Monitoring alerts and notifications

### Performance Troubleshooting

- Identifying slow producers
- Identifying slow consumers
- Broker performance issues
- Network latency
- Common performance bottlenecks
- Correlating application behaviour with Kafka metrics

### Hands-on Exercises

- Monitor Kafka metrics using CloudWatch
- Analyze consumer lag
- Identify performance bottlenecks
- Verify broker resource utilization

### Assignment

Analyze monitoring metrics collected from an AWS MSK cluster and identify the probable causes of performance degradation.

---

## Day 4 (4 Hours) — Security, Configuration and Message Recovery

### Security Troubleshooting

- Authentication in AWS MSK
- Authorization using Access Control Lists (ACLs)
- SSL/TLS overview
- IAM authentication overview
- Troubleshooting authentication failures
- Troubleshooting authorization failures

### Configuration Review

- Topic configuration parameters
- Retention policies
- Common configuration settings used during troubleshooting
- Configuration validation

### Message Recovery and Reprocessing

- Investigating missing messages
- Consumer offset management
- Resetting consumer offsets
- Message replay techniques
- Best practices for message reprocessing

### Hands-on Exercises

- Review topic configuration
- Reset consumer offsets
- Replay messages
- Troubleshoot authentication and authorization issues

### Assignment

Prepare a recovery procedure for a missing message scenario and document the validation steps after message replay.

---

## Day 5 (4 Hours) — Production Support Scenarios

### Scenario 1 — Troubleshooting Deployed Applications

- Review producer and consumer application logs
- Correlate application errors with Kafka metrics
- Verify producer and consumer connectivity
- Restore message processing

### Scenario 2 — Infrastructure and Performance Troubleshooting

- Investigate broker availability
- Analyze consumer lag
- Verify network connectivity
- Identify broker resource constraints
- Restore application performance

### Scenario 3 — Missing Messages and Message Reprocessing

- Investigate missing messages
- Validate consumer offsets
- Perform offset reset
- Replay messages
- Verify successful message processing

### Scenario 4 — Security and Configuration Troubleshooting

- Troubleshoot authentication failures
- Troubleshoot authorization failures
- Verify SSL/TLS connectivity
- Validate Kafka configuration
- Restore application connectivity

### Scenario 5 — End-to-End Production Support Scenario

Participants will investigate a complete production incident involving application failures, consumer lag, infrastructure issues and missing messages. The exercise includes issue identification, troubleshooting, recovery and validation of the implemented solution.

### Production Support Best Practices

- Daily Kafka cluster health checks
- Producer health verification
- Consumer health verification
- Broker health verification
- Monitoring checklist
- Incident troubleshooting approach
- Operational best practices
