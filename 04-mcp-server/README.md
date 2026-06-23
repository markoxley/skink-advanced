# MCP Server for AI Assistant Integration

A Model Context Protocol (MCP) server implementation demonstrating Skink's ability to expose tools and functionality to AI clients like Claude, Cursor, and other MCP-compatible applications.

## Project Overview

This project implements a comprehensive MCP server that provides various tools for AI assistants to interact with system resources. It demonstrates:

- **MCP Server**: Using `std/mcp` to build a Model Context Protocol server
- **Tool Registration**: Exposing custom tools with JSON schema validation
- **Multiple Transports**: Support for stdio, HTTP, and TCP socket connections
- **Resource Management**: Exposing file system and system information as resources
- **Tool Handlers**: Implementing tool logic with proper error handling
- **JSON-RPC**: Handling MCP protocol messages

## Architecture

```
┌─────────────┐    MCP      ┌─────────────┐    Tool    ┌─────────────┐
│   AI Client │ ──────────> │  MCP Server │ ─────────> │  Handlers   │
│ (Claude/    │   JSON-RPC  │  (Skink)    │            └─────────────┘
│  Cursor)    │             └─────────────┘                    │
└─────────────┘                                                │
                                                               ▼
┌─────────────┐    Access  ┌─────────────┐    Query   ┌─────────────┐
│  File Sys   │ <───────── │  Resources  │ <───────── │   Tools     │
└─────────────┘            └─────────────┘            └─────────────┘
```

## Project Structure

```
04-mcp-server/
├── README.md
├── main.skink          # Main server entry point
├── tools.skink        # Tool definitions and handlers
├── resources.skink    # Resource definitions
├── transport.skink    # Transport layer abstraction
└── schemas/
    ├── file_tool.json  # JSON schema for file operations
    └── system_tool.json # JSON schema for system operations
```

## Implementation

### 1. Tools Module (`tools.skink`)

Defines MCP tools and their handlers.

```skink
import "std/mcp"
import "std/fs"
import "std/str"
import "std/time"

// File read tool
fn HandleFileRead(server: *mcp.Server, params: map[string]interface{}) -> (map[string]interface{}, error) {
    path := params["path"].(string)
    
    content, err := fs.ReadFile(path)
    if err != nil {
        return map[string]interface{}{"error": err.message}, err
    }
    
    return map[string]interface{}{
        "content": content,
        "size": len(content),
        "path": path
    }, nil
}

// File write tool
fn HandleFileWrite(server: *mcp.Server, params: map[string]interface{}) -> (map[string]interface{}, error) {
    path := params["path"].(string)
    content := params["content"].(string)
    
    err := fs.WriteFile(path, content, 0644)
    if err != nil {
        return map[string]interface{}{"error": err.message}, err
    }
    
    return map[string]interface{}{
        "success": true,
        "path": path,
        "bytes_written": len(content)
    }, nil
}

// File list tool
fn HandleFileList(server: *mcp.Server, params: map[string]interface{}) -> (map[string]interface{}, error) {
    path := params["path"].(string)
    
    entries, err := fs.ReadDir(path)
    if err != nil {
        return map[string]interface{}{"error": err.message}, err
    }
    
    files := []map[string]interface{}{}
    for i := 0; i < len(entries); i = i + 1 {
        entry := entries[i]
        info, _ := entry.Info()
        files = append(files, map[string]interface{}{
            "name": entry.Name(),
            "is_dir": entry.IsDir(),
            "size": info.Size(),
            "modified": info.ModTime()
        })
    }
    
    return map[string]interface{}{
        "path": path,
        "files": files,
        "count": len(files)
    }, nil
}

// System info tool
fn HandleSystemInfo(server: *mcp.Server, params: map[string]interface{}) -> (map[string]interface{}, error) {
    return map[string]interface{}{
        "hostname": "skink-server",
        "os": "Linux",
        "arch": "x86_64",
        "uptime": time.Now().Unix(),
        "skink_version": "0.1.0"
    }, nil
}

// Execute command tool (with safety restrictions)
fn HandleExecute(server: *mcp.Server, params: map[string]interface{}) -> (map[string]interface{}, error) {
    command := params["command"].(string)
    
    // Safety check: only allow certain commands
    allowedCommands := []string{"ls", "pwd", "date", "whoami", "echo"}
    isAllowed := false
    
    for i := 0; i < len(allowedCommands); i = i + 1 {
        if str.HasPrefix(command, allowedCommands[i]) {
            isAllowed = true
            break
        }
    }
    
    if !isAllowed {
        return map[string]interface{}{"error": "Command not allowed for security reasons"}, 
               errors.New("command not allowed")
    }
    
    // Execute command (simplified - in practice use proper exec)
    output := "Command output placeholder"
    
    return map[string]interface{}{
        "command": command,
        "output": output,
        "exit_code": 0
    }, nil
}

// Register all tools with the server
fn RegisterTools(server: *mcp.Server) {
    // File read tool
    fileReadSchema := map[string]interface{}{
        "type": "object",
        "properties": map[string]interface{}{
            "path": map[string]interface{}{
                "type": "string",
                "description": "Path to the file to read"
            }
        },
        "required": []string{"path"}
    }
    
    server.RegisterTool("file_read", "Read file contents", fileReadSchema, HandleFileRead)
    
    // File write tool
    fileWriteSchema := map[string]interface{}{
        "type": "object",
        "properties": map[string]interface{}{
            "path": map[string]interface{}{
                "type": "string",
                "description": "Path to the file to write"
            },
            "content": map[string]interface{}{
                "type": "string",
                "description": "Content to write to the file"
            }
        },
        "required": []string{"path", "content"}
    }
    
    server.RegisterTool("file_write", "Write content to a file", fileWriteSchema, HandleFileWrite)
    
    // File list tool
    fileListSchema := map[string]interface{}{
        "type": "object",
        "properties": map[string]interface{}{
            "path": map[string]interface{}{
                "type": "string",
                "description": "Directory path to list",
                "default": "."
            }
        },
        "required": []string{}
    }
    
    server.RegisterTool("file_list", "List directory contents", fileListSchema, HandleFileList)
    
    // System info tool
    systemInfoSchema := map[string]interface{}{
        "type": "object",
        "properties": map[string]interface{}{},
        "required": []string{}
    }
    
    server.RegisterTool("system_info", "Get system information", systemInfoSchema, HandleSystemInfo)
    
    // Execute command tool
    executeSchema := map[string]interface{}{
        "type": "object",
        "properties": map[string]interface{}{
            "command": map[string]interface{}{
                "type": "string",
                "description": "Command to execute (restricted for security)"
            }
        },
        "required": []string{"command"}
    }
    
    server.RegisterTool("execute", "Execute a shell command", executeSchema, HandleExecute)
}
```

### 2. Resources Module (`resources.skink`)

Defines MCP resources for file system and system information.

```skink
import "std/mcp"
import "std/fs"

// File resource handler
fn HandleFileResource(uri: string) -> (map[string]interface{}, error) {
    // Parse URI: file:///path/to/file
    path := str.Replace(uri, "file:///", "")
    
    content, err := fs.ReadFile(path)
    if err != nil {
        return map[string]interface{}{}, err
    }
    
    return map[string]interface{}{
        "uri": uri,
        "mime_type": "text/plain",
        "content": content
    }, nil
}

// Directory resource handler
fn HandleDirectoryResource(uri: string) -> (map[string]interface{}, error) {
    path := str.Replace(uri, "dir:///", "")
    
    entries, err := fs.ReadDir(path)
    if err != nil {
        return map[string]interface{}{}, err
    }
    
    files := []string{}
    for i := 0; i < len(entries); i = i + 1 {
        files = append(files, entries[i].Name())
    }
    
    return map[string]interface{}{
        "uri": uri,
        "files": files
    }, nil
}

// Register resources with the server
fn RegisterResources(server: *mcp.Server) {
    server.RegisterResource("file:///", "File system files", HandleFileResource)
    server.RegisterResource("dir:///", "File system directories", HandleDirectoryResource)
}
```

### 3. Transport Module (`transport.skink`)

Handles different transport mechanisms for MCP.

```skink
import "std/mcp"
import "std/errors"

struct TransportConfig {
    type: string // "stdio", "http", "tcp"
    host: string
    port: int
}

fn CreateTransport(config: TransportConfig) -> (mcp.Transport, error) {
    if config.type == "stdio" {
        return mcp.NewStdioTransport(), nil
    } else if config.type == "http" {
        return mcp.NewHttpTransport(config.host, config.port)
    } else if config.type == "tcp" {
        return mcp.NewSocketTransport(config.host, config.port)
    } else {
        return nil, errors.New("unknown transport type")
    }
}
```

### 4. Main Server (`main.skink`)

Main application that creates and starts the MCP server.

```skink
import "std/mcp"
import "tools"
import "resources"
import "transport"
import "std/str"

fn main() -> int {
    // Parse command line arguments for transport type
    transportType := "stdio"
    if len(os.Args) > 1 {
        transportType = os.Args[1]
    }
    
    print("Starting Skink MCP Server...")
    print("Transport: {transportType}")
    
    // Create MCP server
    server := mcp.NewServer("skink-tools", "1.0.0")
    
    // Register tools
    print("Registering tools...")
    tools.RegisterTools(&server)
    print("Registered {len(server.tools)} tools")
    
    // Register resources
    print("Registering resources...")
    resources.RegisterResources(&server)
    print("Registered {len(server.resources)} resources")
    
    // Create transport
    config := transport.TransportConfig{
        type: transportType,
        host: "0.0.0.0",
        port: 8080
    }
    
    trans, err := transport.CreateTransport(config)
    if err != nil {
        print("Failed to create transport: {err.message}")
        return 1
    }
    
    // Start server
    print("Starting server on {config.host}:{config.port}...")
    err = server.Start(trans)
    if err != nil {
        print("Failed to start server: {err.message}")
        return 1
    }
    
    print("Server running...")
    
    // Wait for shutdown signal
    select {}
    
    return 0
}
```

## Configuration

### Claude Desktop Configuration

Add to Claude Desktop configuration file:

```json
{
  "mcpServers": {
    "skink-tools": {
      "command": "/path/to/skink-mcp-server",
      "args": ["stdio"]
    }
  }
}
```

### Cursor Configuration

Add to Cursor settings:

```json
{
  "mcp.servers": {
    "skink-tools": {
      "command": "/path/to/skink-mcp-server",
      "args": ["stdio"]
    }
  }
}
```

## Setup Instructions

1. **Build the Server**
   ```bash
   skink build main.skink -o skink-mcp-server
   ```

2. **Run with stdio transport (for AI clients)**
   ```bash
   ./skink-mcp-server stdio
   ```

3. **Run with HTTP transport (for testing)**
   ```bash
   ./skink-mcp-server http
   ```

4. **Run with TCP transport (for custom clients)**
   ```bash
   ./skink-mcp-server tcp
   ```

## Testing with curl (HTTP transport)

```bash
# List available tools
curl -X POST http://localhost:8080/tools/list

# Call a tool
curl -X POST http://localhost:8080/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "name": "file_list",
    "arguments": {"path": "."}
  }'

# Read a file
curl -X POST http://localhost:8080/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "name": "file_read",
    "arguments": {"path": "README.md"}
  }'

# Get system info
curl -X POST http://localhost:8080/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "name": "system_info",
    "arguments": {}
  }'
```

## Available Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `file_read` | Read file contents | `path` (string) |
| `file_write` | Write content to a file | `path` (string), `content` (string) |
| `file_list` | List directory contents | `path` (string, optional) |
| `system_info` | Get system information | none |
| `execute` | Execute a shell command | `command` (string) |

## Available Resources

| URI Pattern | Description |
|------------|-------------|
| `file:///path/to/file` | Read file contents |
| `dir:///path/to/dir` | List directory contents |

## Key Skink Features Demonstrated

- **`std/mcp`**: Model Context Protocol server implementation
- **Tool Registration**: Exposing functionality with JSON schema
- **Resource Management**: File system resources
- **Multiple Transports**: stdio, HTTP, TCP socket support
- **JSON-RPC**: Protocol message handling
- **Error Handling**: Proper error propagation
- **Type Safety**: Interface-based tool handlers
- **Security**: Command execution restrictions

## Extending the Project

- Add database tools for SQLite/PostgreSQL access
- Implement web scraping tools
- Add network diagnostic tools (ping, traceroute)
- Create file watching capabilities
- Add compression/decompression tools
- Implement authentication and authorization
- Add rate limiting
- Create tool versioning
- Add tool dependency management
- Implement tool composition (pipelines)
- Add logging and audit trails
- Create admin dashboard for monitoring
