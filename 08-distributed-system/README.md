# 08 Distributed System Skeleton

This example sketches a real-world Skink application that combines the four major building blocks needed for a distributed monitoring and control system:

- **SQLite** (`std/db`) for local data storage
- **MQTT** (`std/mqtt`) for inter-node messaging
- **RuleSets** (`std/rules`) for event-driven reactions
- **Trainable LSTM** (`std/tensor`) for reinforcement-learning decisions
- **Concurrency primitives** (`std/sync`, `std/time`) for safe concurrent access

## Type check

```bash
SKINK_HOME=/path/to/skink-lang \
  skink -check main.skink
```

## Build (native)

```bash
SKINK_HOME=/path/to/skink-lang \
  skink -o distributed main.skink
```

## Cross-compile for AArch64

```bash
SKINK_HOME=/path/to/skink-lang \
  skink -target aarch64-linux-gnu -o distributed-arm main.skink
```

A full AArch64 executable requires `aarch64-linux-gnu-gcc` (or `clang --target=aarch64-linux-gnu`) and the matching cross libraries for SQLite, mosquitto, OpenSSL etc.

## What it does

1. Opens an in-memory SQLite database and creates a `readings` table.
2. Registers a `RuleSource` that triggers when a sensor reading exceeds a threshold.
3. Connects to the public `test.mosquitto.org` MQTT broker, publishes a demo message and subscribes to a topic.
4. Runs one gradient step on an LSTM cell to show on-device trainable decision making.

## Next steps

- Replace the in-memory database with an on-disk path for real telemetry.
- Add JSON payload parsing for MQTT messages (`std/json`).
- Train the LSTM on a stream of sensor readings to learn a policy.
