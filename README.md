# Skink Advanced Projects

A collection of comprehensive, real-world projects demonstrating the full power and capabilities of the Skink programming language. These projects showcase advanced features including AI integration, machine learning, IoT, web development, concurrency, and distributed systems.

## Overview

This repository contains ten complete projects that go beyond simple examples to demonstrate how Skink can be used to build production-grade applications. Each project includes:

- Complete implementation with multiple modules
- Detailed documentation and architecture diagrams
- Setup and running instructions
- Key Skink features highlighted
- Extension ideas for further learning

## Projects

### 1. LLM Web Application with Middleware Logging

**Location:** `01-llm-web-app/`

A full-stack application demonstrating local LLM inference, HTTP networking, JSON API endpoints, and file logging.

**Key Features:**
- Local LLM inference using `std/llm` (no cloud dependencies)
- HTTP server with `std/net`
- Request/response handling and JSON responses
- File logging with `std/fs`
- Fallback demo mode when model weights are not present

**Skink Features:**
- `std/llm` - Local LLM inference
- `std/net` - HTTP server and TCP networking
- `std/json` - JSON serialization and parsing
- `std/fs` - File I/O
- Structs and method implementation

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
- Service composition and orchestration

**Skink Features:**
- `service` keyword - Service-oriented architecture
- Service implementation with `service for`
- RPC communication over typed channels
- `std/sync` - Thread-safe service state

**Use Case:** Building distributed microservices architectures

---

### 7. Ruleset Introduction

**Location:** `07-ruleset-intro/`

An introductory example demonstrating Skink's reactive ruleset engine, showing how to define rules with conditions, actions, and priorities.

**Key Features:**
- Ruleset definitions with `ruleset` keyword
- Rule conditions (`when`) and actions
- Priority-based rule execution
- Custom rule sources

**Skink Features:**
- `std/rules` - Reactive ruleset engine
- `ruleset` keyword for event-driven logic
- Rule priorities and conflict resolution

**Use Case:** Learning the ruleset engine for reactive programming

---

### 8. Distributed System

**Location:** `08-distributed-system/`

A distributed system example demonstrating node communication, consensus patterns, and fault-tolerant design using Skink's concurrency primitives.

**Key Features:**
- Node-to-node communication
- Consensus and leader election
- Fault tolerance patterns
- Concurrent state management

**Skink Features:**
- `spawn` for goroutines
- Channels for inter-node communication
- `std/sync` for thread-safe state
- Rulesets for reactive node behavior

**Use Case:** Building fault-tolerant distributed systems

---

### 9. Self-Hosting Lexer

**Location:** `09-self-hosting-lexer/`

A Skink lexer written in Skink itself, proving the language can handle real-world tokenization tasks. Successfully lexes all stdlib files.

**Key Features:**
- Complete lexer implementation in Skink
- Token types for all Skink syntax
- String and comment lexing
- Error reporting

**Skink Features:**
- String manipulation with `std/str`
- Character classification
- Custom structs and enums
- Pattern matching

**Use Case:** Proving Skink's self-hosting capability for tooling

---

### 10. Self-Hosting Parser

**Location:** `10-self-hosting-parser/`

A Skink parser written in Skink itself, building on the self-hosting lexer to parse Skink source code into an AST.

**Key Features:**
- Recursive descent parser in Skink
- AST node definitions
- Expression and statement parsing
- Type annotation parsing

**Skink Features:**
- Tagged unions for AST nodes
- Pattern matching for node dispatch
- Self-referential types
- Module imports

**Use Case:** Proving Skink's self-hosting capability for compiler tooling

---

## Getting Started

### Prerequisites

- Skink compiler: install via `curl -fsSL http://skink-lang.uk/install.sh | bash`
- Required external dependencies vary by project (see individual project READMEs)

### Running a Project

Each project is self-contained and can be run independently:

```bash
cd 01-llm-web-app
skink code/main.skink
./code/main
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
- **`std/mqtt`**: MQTT client for IoT
- **`std/rules`**: Reactive ruleset engine
- **`std/db`**: SQLite database
- **`std/net`**: HTTP client and TCP networking
- **`std/json`**: JSON parsing and serialization
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

- [Skink Language Website](http://skink-lang.uk)
- [Skink GitHub Repository](https://github.com/markoxley/skink)
