# Skink Advanced Projects

A collection of comprehensive, real-world projects demonstrating the full power and capabilities of the Skink programming language. These projects showcase advanced features including AI integration, machine learning, IoT, web development, concurrency, and distributed systems.

## Overview

This repository contains six complete projects that go beyond simple examples to demonstrate how Skink can be used to build production-grade applications. Each project includes:

- Complete implementation with multiple modules
- Detailed documentation and architecture diagrams
- Setup and running instructions
- Key Skink features highlighted
- Extension ideas for further learning

## Projects

### 1. LLM Web Application with Middleware Logging

**Location:** `01-llm-web-app/`

A full-stack application demonstrating local LLM inference, web framework, middleware patterns, and file logging.

**Key Features:**
- Local LLM inference using `std/llm` (no cloud dependencies)
- Web server with `std/web` framework
- Request/response middleware for logging
- Thread-safe file logging with `std/sync`
- Concurrent chat session handling

**Skink Features:**
- `std/llm` - Local LLM inference
- `std/web` - HTTP server and routing
- `std/fs` - File I/O
- `std/sync` - Mutex for thread safety
- Middleware pattern implementation

**Use Case:** Building AI-powered web applications with local inference

---

### 2. Neural Network with CSV Training Data

**Location:** `02-neural-network-csv/`

A machine learning project implementing a neural network from scratch with tensor operations and CSV data processing.

**Key Features:**
- Neural network implementation with `std/tensor`
- CSV parsing and data preprocessing
- Training loop with backpropagation
- Model evaluation and metrics
- Support for classification tasks

**Skink Features:**
- `std/tensor` - Matrix operations and neural network layers
- `std/fs` - File I/O for CSV reading
- `std/str` - String parsing
- Custom structs and methods
- Mathematical operations

**Use Case:** Building ML models with Skink's tensor operations

---

### 3. MQTT Ruleset with Custom RuleSource and SQLite Logging

**Location:** `03-mqtt-ruleset-sqlite/`

An IoT monitoring system demonstrating reactive programming, custom ruleset sources, and database integration.

**Key Features:**
- MQTT integration with `std/mqtt`
- Custom RuleSource implementation
- Reactive ruleset engine with `std/rules`
- SQLite database logging with `std/db`
- Real-time sensor monitoring

**Skink Features:**
- `std/mqtt` - MQTT client for IoT
- `std/rules` - Reactive ruleset engine
- `std/db` - SQLite database
- Template-based interface implementation
- `std/sync` - Thread-safe operations

**Use Case:** Building IoT monitoring and automation systems

---

### 4. MCP Server for AI Assistant Integration

**Location:** `04-mcp-server/`

A Model Context Protocol server implementation for exposing tools to AI clients like Claude and Cursor.

**Key Features:**
- MCP server with `std/mcp`
- Tool registration with JSON schema
- Multiple transport types (stdio, HTTP, TCP)
- Resource management
- JSON-RPC protocol handling

**Skink Features:**
- `std/mcp` - Model Context Protocol server
- Tool registration and handlers
- Multiple transport support
- JSON schema validation
- Security restrictions for command execution

**Use Case:** Integrating Skink tools with AI assistants

---

### 5. Concurrent Web Scraper with Worker Pools

**Location:** `05-concurrent-scraper/`

A high-performance web scraper demonstrating concurrency patterns, worker pools, and HTTP client capabilities.

**Key Features:**
- Concurrent URL fetching with worker pools
- Goroutines and channels for coordination
- Rate limiting and timeout handling
- HTML parsing and data extraction
- CSV and JSON output formats

**Skink Features:**
- Goroutines with `spawn`
- Channels for communication
- WaitGroups for synchronization
- Worker pool pattern
- `std/net` - HTTP client
- `std/regex` - Regular expressions

**Use Case:** Building high-performance concurrent applications

---

### 6. Microservices Communication with Services

**Location:** `06-microservices/`

A distributed system demonstrating service-oriented architecture, RPC communication, and microservices patterns.

**Key Features:**
- Service definitions with `service` keyword
- Typed channel-based RPC
- Multiple interconnected services
- API gateway for request routing
- Service composition and orchestration

**Skink Features:**
- `service` keyword - Service-oriented architecture
- Service implementation with `service for`
- RPC communication over typed channels
- `std/web` - HTTP server and API gateway
- `std/sync` - Thread-safe service state

**Use Case:** Building distributed microservices architectures

---

## Getting Started

### Prerequisites

- Skink compiler (version 0.1 or later)
- Required external dependencies vary by project (see individual project READMEs)

### Running a Project

Each project is self-contained and can be run independently:

```bash
cd 01-llm-web-app
# Follow project-specific setup instructions in README.md
skink build main.skink
./main
```

## Skink Features Demonstrated

Across all projects, the following Skink features are demonstrated:

### Core Language Features
- **Structs and Methods**: Object-oriented programming patterns
- **Generics**: Flexible type-safe operations
- **Error Handling**: Explicit error propagation
- **Resource Management**: `defer` for cleanup
- **Modules**: Code organization and imports

### Standard Library
- **`std/llm`**: Local LLM inference
- **`std/mcp`**: Model Context Protocol server
- **`std/tensor`**: Tensor operations and neural networks
- **`std/web`**: HTTP server and web framework
- **`std/mqtt`**: MQTT client for IoT
- **`std/rules`**: Reactive ruleset engine
- **`std/db`**: SQLite database
- **`std/net`**: HTTP client
- **`std/fs`**: File system operations
- **`std/sync`**: Concurrency primitives (mutex, waitgroup)
- **`std/str`**: String manipulation
- **`std/regex`**: Regular expressions
- **`std/time`**: Time operations

### Advanced Patterns
- **Concurrency**: Goroutines, channels, worker pools
- **Service-Oriented Architecture**: Service definitions and RPC
- **Middleware Pattern**: Request/response processing
- **Template Implementation**: Interface-based programming
- **Reactive Programming**: Ruleset engine
- **Microservices**: Distributed system design

## Learning Path

For those new to Skink, we recommend the following progression:

1. **Neural Network with CSV** - Learn tensor operations and data processing
2. **Concurrent Web Scraper** - Understand concurrency patterns
3. **LLM Web Application** - Build a complete web application
4. **MQTT Ruleset** - Explore IoT and reactive programming
5. **MCP Server** - Integrate with AI tools
6. **Microservices** - Build distributed systems

## Contributing

These projects are meant to be educational examples. Feel free to:
- Fork and modify for your own use
- Submit issues for bugs or improvements
- Add new projects demonstrating other Skink features

## License

All projects in this repository are licensed under the Apache License 2.0, consistent with the Skink language itself.

## Additional Resources

- [Skink Language Website](https://skink-lang.org)
- [Skink Manual](https://skink-lang.org/manual.html)
- [Skink GitHub Repository](https://github.com/markoxley/skink-lang)
- [Skink VS Code Extension](https://github.com/markoxley/skink-vscode)

## Project Ideas for Future Addition

- Real-time chat application with WebSockets
- Blockchain implementation
- Game server with multiplayer support
- Data pipeline with ETL operations
- Computer vision application
- Distributed file system
- Container orchestration system
- Build system and package manager
