# 07 Ruleset Intro

This example shows how to use Skink's `ruleset` and `rule` language features, plus the `RuleSource` template for registering dynamic sources at runtime.

## Files

- `main.skink` — complete example with:
  - a `SensorSource` struct that implements the `RuleSource` template
  - a `ClimateRules` ruleset with static reactive rules
  - a `main()` that registers the dynamic source and drives the ruleset

## What it does

`ClimateRules` watches a global `currentTemp` variable. Three static rules fire when the temperature is high, low, or normal.

`SensorSource` is a dynamic rule source. Its methods are defined inside the struct so the compiler emits the qualified names the ruleset wrapper expects. It implements `RuleSource` by providing `name`, `start`, `stop`, `triggered`, `Action`, and `Priority` methods. It is registered with the ruleset via:

```skink
ClimateRules.registerRule(&src)
```

The ruleset background loop evaluates all rules every millisecond. The program sets `currentTemp` and the sensor `reading` a few times, lets the loop run, then stops the ruleset.

Ruleset lifecycle methods:

- `ClimateRules.start()` — start the background evaluation loop
- `ClimateRules.stop()` — stop the loop
- `ClimateRules.restart()` — stop then start again
- `ClimateRules.reset()` — clear all registered rules

## Running

```bash
SKINK_HOME=/path/to/skink-lang /path/to/skink -o ruleset_intro main.skink
./ruleset_intro
```

Expected output contains repeated `STATIC:` and `DYNAMIC:` messages because the ruleset loop fires frequently during each `time.SleepMs` window.
