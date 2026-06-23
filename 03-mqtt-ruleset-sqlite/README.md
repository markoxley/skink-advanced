# MQTT Ruleset with Custom RuleSource and SQLite Logging

A comprehensive IoT monitoring system demonstrating Skink's MQTT integration, custom ruleset sources, and SQLite database logging. This project creates a reactive system that monitors MQTT messages, evaluates rules, and logs events to a database.

## Project Overview

This project implements an IoT monitoring system that:
- Subscribes to MQTT topics for sensor data
- Uses custom RuleSource implementations for dynamic rule evaluation
- Triggers actions based on rule conditions
- Logs all events and messages to SQLite database
- Demonstrates reactive programming with rulesets

## Architecture

```
┌─────────────┐    MQTT     ┌──────────────┐    Rules   ┌─────────────┐
│   Sensors   │ ──────────> │  MQTT Broker │ ─────────> │  Ruleset    │
└─────────────┘             └──────────────┘            └─────────────┘
                                                                 │
                                                                 ▼
┌─────────────┐    Log     ┌─────────────┐    Query   ┌─────────────┐
│   SQLite    │ <───────── │   Logger     │ <──────── │   Actions   │
│  Database   │            └─────────────┘            └─────────────┘
└─────────────┘
```

## Project Structure

```
03-mqtt-ruleset-sqlite/
├── README.md
├── main.skink          # Main application entry point
├── mqtt_source.skink   # Custom RuleSource for MQTT
├── ruleset.skink       # Ruleset definition
├── db_logger.skink     # SQLite database logging
├── sensor_data.skink   # Sensor data structures
└── data/
    └── monitoring.db   # SQLite database file
```

## Implementation

### 1. Sensor Data Module (`sensor_data.skink`)

Defines sensor data structures.

```skink
struct SensorReading {
    deviceId: string
    sensorType: string
    value: float
    timestamp: int
    unit: string
}

struct Alert {
    ruleName: string
    message: string
    severity: string
    timestamp: int
    sensorData: SensorReading
}

fn NewSensorReading(deviceId: string, sensorType: string, value: float, unit: string) -> SensorReading {
    return SensorReading{
        deviceId: deviceId,
        sensorType: sensorType,
        value: value,
        timestamp: time.Now().Unix(),
        unit: unit
    }
}
```

### 2. Database Logger Module (`db_logger.skink`)

Handles SQLite database operations for logging.

```skink
import "std/db"
import "sensor_data"

struct DBLogger {
    conn: db.Connection
}

fn NewDBLogger(dbPath: string) -> (DBLogger, error) {
    conn, err := db.Open("sqlite", dbPath)
    if err != nil {
        return DBLogger{}, err
    }
    
    // Create tables
    conn.Exec(`
        CREATE TABLE IF NOT EXISTS sensor_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            sensor_type TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT NOT NULL,
            timestamp INTEGER NOT NULL
        )
    `)
    
    conn.Exec(`
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rule_name TEXT NOT NULL,
            message TEXT NOT NULL,
            severity TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            sensor_id INTEGER,
            FOREIGN KEY (sensor_id) REFERENCES sensor_readings(id)
        )
    `)
    
    return DBLogger{conn: conn}, nil
}

fn (l: *DBLogger) LogReading(reading: SensorReading) -> error {
    _, err := l.conn.Exec(
        "INSERT INTO sensor_readings (device_id, sensor_type, value, unit, timestamp) VALUES (?, ?, ?, ?, ?)",
        reading.deviceId, reading.sensorType, reading.value, reading.unit, reading.timestamp
    )
    return err
}

fn (l: *DBLogger) LogAlert(alert: Alert) -> error {
    // First log the sensor reading
    sensorId, err := l.conn.LastInsertId()
    if err != nil {
        return err
    }
    
    _, err = l.conn.Exec(
        "INSERT INTO alerts (rule_name, message, severity, timestamp, sensor_id) VALUES (?, ?, ?, ?, ?)",
        alert.ruleName, alert.message, alert.severity, alert.timestamp, sensorId
    )
    return err
}

fn (l: *DBLogger) GetRecentReadings(limit: int) -> ([]SensorReading, error) {
    rows, err := l.conn.Query("SELECT device_id, sensor_type, value, unit, timestamp FROM sensor_readings ORDER BY timestamp DESC LIMIT ?", limit)
    if err != nil {
        return []SensorReading{}, err
    }
    defer rows.Close()
    
    readings := []SensorReading{}
    for rows.Next() {
        reading := SensorReading{}
        rows.Scan(&reading.deviceId, &reading.sensorType, &reading.value, &reading.unit, &reading.timestamp)
        readings = append(readings, reading)
    }
    
    return readings, nil
}

fn (l: *DBLogger) Close() {
    l.conn.Close()
}
```

### 3. MQTT RuleSource Module (`mqtt_source.skink`)

Custom RuleSource implementation for MQTT messages.

```skink
import "std/mqtt"
import "std/rules"
import "sensor_data"
import "db_logger"

template MQTTSource for rules.RuleSource {
    client: mqtt.Client
    topic: string
    currentReading: SensorReading
    logger: DBLogger
    mutex: sync.Mutex
    
    fn name() -> string {
        return "mqtt_sensor_source"
    }
    
    fn start() {
        // Subscribe to MQTT topic
        client.Subscribe(self.topic, 0, fn(topic: string, payload: []byte) {
            // Parse sensor data from MQTT message
            // Expected format: JSON or simple "device:sensor:value:unit"
            data := string(payload)
            parts := str.Split(data, ":")
            
            if len(parts) >= 4 {
                deviceId := parts[0]
                sensorType := parts[1]
                value := str.ParseFloat(parts[2])
                unit := parts[3]
                
                reading := NewSensorReading(deviceId, sensorType, value, unit)
                
                self.mutex.Lock()
                self.currentReading = reading
                self.mutex.Unlock()
                
                // Log to database
                self.logger.LogReading(reading)
            }
        })
        
        // Start MQTT client loop
        client.Start()
    }
    
    fn stop() {
        self.client.Unsubscribe(self.topic)
        self.client.Stop()
    }
    
    fn triggered() -> bool {
        // Check if current reading meets any rule conditions
        // This is called by the ruleset engine
        return true // Always trigger to evaluate all rules
    }
    
    fn action() {
        // Default action - can be overridden by specific rules
        print("MQTT message received: {self.currentReading.deviceId} - {self.currentReading.value}")
    }
    
    fn priority() -> int {
        return 10
    }
    
    fn GetReading() -> SensorReading {
        self.mutex.Lock()
        defer self.mutex.Unlock()
        return self.currentReading
    }
}

fn NewMQTTSource(broker: string, topic: string, logger: DBLogger) -> MQTTSource {
    client := mqtt.NewClient(broker, "skink_monitor")
    return MQTTSource{
        client: client,
        topic: topic,
        logger: logger,
        mutex: sync.Mutex{}
    }
}
```

### 4. Ruleset Module (`ruleset.skink`)

Defines the reactive rules for sensor monitoring.

```skink
import "std/rules"
import "mqtt_source"
import "sensor_data"
import "db_logger"

ruleset SensorMonitoring {
    // High temperature alert
    rule high_temp when temp > 80.0 {
        action: fn() {
            source := mqtt_source.GetReading()
            alert := Alert{
                ruleName: "high_temp",
                message: "High temperature detected: {temp}°C on device {source.deviceId}",
                severity: "critical",
                timestamp: time.Now().Unix(),
                sensorData: source
            }
            logger.LogAlert(alert)
            print("ALERT: {alert.message}")
        }
        priority: 1
    }
    
    // Low temperature alert
    rule low_temp when temp < 10.0 {
        action: fn() {
            source := mqtt_source.GetReading()
            alert := Alert{
                ruleName: "low_temp",
                message: "Low temperature detected: {temp}°C on device {source.deviceId}",
                severity: "warning",
                timestamp: time.Now().Unix(),
                sensorData: source
            }
            logger.LogAlert(alert)
            print("WARNING: {alert.message}")
        }
        priority: 2
    }
    
    // High humidity alert
    rule high_humidity when humidity > 90.0 {
        action: fn() {
            source := mqtt_source.GetReading()
            alert := Alert{
                ruleName: "high_humidity",
                message: "High humidity detected: {humidity}% on device {source.deviceId}",
                severity: "warning",
                timestamp: time.Now().Unix(),
                sensorData: source
            }
            logger.LogAlert(alert)
            print("WARNING: {alert.message}")
        }
        priority: 2
    }
    
    // Pressure anomaly alert
    rule pressure_anomaly when pressure < 900.0 || pressure > 1100.0 {
        action: fn() {
            source := mqtt_source.GetReading()
            alert := Alert{
                ruleName: "pressure_anomaly",
                message: "Pressure anomaly detected: {pressure} hPa on device {source.deviceId}",
                severity: "critical",
                timestamp: time.Now().Unix(),
                sensorData: source
            }
            logger.LogAlert(alert)
            print("ALERT: {alert.message}")
        }
        priority: 1
    }
    
    // Normal operation log
    rule normal_operation when true {
        action: fn() {
            source := mqtt_source.GetReading()
            print("Normal: {source.deviceId} - {source.sensorType}: {source.value} {source.unit}")
        }
        priority: 10
    }
}
```

### 5. Main Application (`main.skink`)

Main application orchestrating all components.

```skink
import "std/mqtt"
import "std/rules"
import "mqtt_source"
import "db_logger"
import "ruleset"

fn main() -> int {
    print("Starting IoT Monitoring System...")
    
    // Initialize database logger
    logger, err := db_logger.NewDBLogger("data/monitoring.db")
    if err != nil {
        print("Failed to initialize database: {err.message}")
        return 1
    }
    defer logger.Close()
    
    print("Database initialized")
    
    // Initialize MQTT source
    mqttSource := mqtt_source.NewMQTTSource("tcp://localhost:1883", "sensors/+/data", logger)
    print("MQTT source initialized")
    
    // Create and start ruleset
    monitoring := SensorMonitoring{}
    monitoring.RegisterSource(mqttSource)
    
    print("Starting ruleset...")
    monitoring.Start()
    
    print("Monitoring system running...")
    print("Press Ctrl+C to stop")
    
    // Keep running
    select {}
    
    // Cleanup
    monitoring.Stop()
    mqttSource.stop()
    
    return 0
}
```

## MQTT Message Format

The system expects MQTT messages in the following format:

```
device_id:sensor_type:value:unit
```

Examples:
- `sensor_01:temperature:75.5:C`
- `sensor_02:humidity:65.0:%`
- `sensor_03:pressure:1013.25:hPa`

## Setup Instructions

1. **Install MQTT Broker**
   ```bash
   # Install Mosquitto MQTT broker
   # On Ubuntu/Debian:
   sudo apt-get install mosquitto mosquitto-clients
   
   # On macOS:
   brew install mosquitto
   
   # Start the broker
   mosquitto -v
   ```

2. **Create Data Directory**
   ```bash
   mkdir data
   ```

3. **Build and Run**
   ```bash
   skink build main.skink
   ./main
   ```

4. **Test with MQTT Messages**
   ```bash
   # Publish test messages
   mosquitto_pub -h localhost -t "sensors/sensor_01/data" -m "sensor_01:temperature:85.0:C"
   mosquitto_pub -h localhost -t "sensors/sensor_02/data" -m "sensor_02:humidity:95.0:%"
   mosquitto_pub -h localhost -t "sensors/sensor_03/data" -m "sensor_03:pressure:850.0:hPa"
   ```

5. **Query the Database**
   ```bash
   sqlite3 data/monitoring.db "SELECT * FROM sensor_readings ORDER BY timestamp DESC LIMIT 10;"
   sqlite3 data/monitoring.db "SELECT * FROM alerts ORDER BY timestamp DESC LIMIT 10;"
   ```

## Expected Output

```
Starting IoT Monitoring System...
Database initialized
MQTT source initialized
Starting ruleset...
Monitoring system running...
Press Ctrl+C to stop
Normal: sensor_01 - temperature: 25.0 C
Normal: sensor_02 - humidity: 45.0 %
ALERT: High temperature detected: 85.0°C on device sensor_01
WARNING: High humidity detected: 95.0% on device sensor_02
ALERT: Pressure anomaly detected: 850.0 hPa on device sensor_03
```

## Key Skink Features Demonstrated

- **`std/mqtt`**: MQTT client for IoT communication
- **`std/rules`**: Reactive ruleset engine for event-driven logic
- **`std/db`**: SQLite database integration
- **Custom RuleSource**: Template-based interface implementation
- **`std/sync`**: Mutex for thread-safe operations
- **Rulesets**: Declarative reactive programming
- **Error Handling**: Database and network error management
- **Resource Management**: `defer` for cleanup

## Extending the Project

- Add web dashboard for real-time monitoring
- Implement email/SMS alerts for critical events
- Add machine learning for anomaly detection
- Support for multiple MQTT brokers
- Add authentication and encryption
- Implement rule configuration from database
- Add historical data analysis and reporting
- Support for different sensor data formats (JSON, CBOR)
- Add rule versioning and hot-reloading
- Implement distributed monitoring with multiple instances
